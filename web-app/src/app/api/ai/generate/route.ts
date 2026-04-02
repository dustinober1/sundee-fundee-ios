import { NextRequest, NextResponse } from "next/server";
import { db, getAuthUser, userCollection, userDoc } from "@/lib/firestore";
import {
  buildWorkoutPrompt,
  buildWorkoutSystemInstruction,
  getAIModelConfig,
  parseAIWorkoutResponse,
  validateAIWorkoutRequest,
  type CatalogEntry,
  type UserContext,
} from "@/lib/ai-generation";
import {
  getUsageDateKey,
  incrementDailyAIUsage,
  resolveEntitlement,
} from "@/lib/subscription-state";

// Map user equipment selection to catalog equipment types
const EQUIPMENT_FILTER: Record<string, string[]> = {
  full_gym: [], // no filter — all equipment available
  home_dumbbells: ["dumbbell", "kettlebell", "bodyweight", "band"],
  bodyweight_only: ["bodyweight"],
  outdoor: ["bodyweight", "band", "cardio"],
};

async function fetchCatalog(equipmentAccess: string): Promise<CatalogEntry[]> {
  const snapshot = await db.collection("exerciseCatalog").orderBy("name", "asc").get();
  const allowedEquipment = EQUIPMENT_FILTER[equipmentAccess];

  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      return {
        name: data.name as string,
        category: (data.category as string) ?? "",
        equipment: (data.equipment as string) ?? undefined,
      };
    })
    .filter((ex) => {
      // No filter for full_gym
      if (!allowedEquipment || allowedEquipment.length === 0) return true;
      // Include exercises that match allowed equipment or have no equipment set
      return !ex.equipment || allowedEquipment.includes(ex.equipment);
    });
}

async function fetchUserContext(uid: string, equipmentAccess: string): Promise<UserContext> {
  const ctx: UserContext = {};

  // Fetch profile, maxes, recent workouts, and catalog in parallel
  const [profileSnap, maxesSnap, workoutsSnap, catalog] = await Promise.all([
    userDoc(uid).get(),
    userCollection(uid, "oneRepMaxes").orderBy("date", "desc").limit(20).get(),
    userCollection(uid, "completedWorkouts").orderBy("completedAt", "desc").limit(5).get(),
    fetchCatalog(equipmentAccess),
  ]);

  ctx.catalog = catalog;

  if (profileSnap.exists) {
    const profile = profileSnap.data() as Record<string, unknown>;
    ctx.experienceLevel = typeof profile.experienceLevel === "string" ? profile.experienceLevel : undefined;
    ctx.primaryGoal = typeof profile.primaryGoal === "string" ? profile.primaryGoal : undefined;
    ctx.weightUnit = typeof profile.weightUnit === "string" ? profile.weightUnit : undefined;
  }

  if (!maxesSnap.empty) {
    // Deduplicate by exerciseId (keep most recent)
    const seen = new Set<string>();
    ctx.maxes = [];
    for (const doc of maxesSnap.docs) {
      const data = doc.data() as { exerciseId: string; weightKg: number };
      if (!seen.has(data.exerciseId)) {
        seen.add(data.exerciseId);
        ctx.maxes.push({ exerciseId: data.exerciseId, weightKg: data.weightKg });
      }
    }
  }

  if (!workoutsSnap.empty) {
    ctx.recentWorkouts = workoutsSnap.docs.map((doc) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const data = doc.data() as Record<string, any>;
      const raw = data.completedAt;
      const completedAt = raw && typeof raw.toDate === "function"
        ? (raw.toDate() as Date)
        : new Date(String(raw));
      const sets = Array.isArray(data.sets) ? data.sets : [];
      const exercises = [...new Set(sets.map((s: { exerciseName: string }) => s.exerciseName))];
      return {
        completedAt: completedAt.toISOString().split("T")[0]!,
        durationSeconds: data.durationSeconds ?? 0,
        exercises,
      };
    });
  }

  return ctx;
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let requestBody;
  try {
    requestBody = validateAIWorkoutRequest(await req.json());
  } catch (error) {
    return NextResponse.json({ error: (error as Error).message }, { status: 400 });
  }

  const entitlement = await resolveEntitlement(user.uid);
  if (!entitlement.hasActivePaidAccess) {
    return NextResponse.json({ error: "Cloud AI requires a Plus or Premium subscription" }, { status: 403 });
  }
  if (!entitlement.canUseCloudAI) {
    return NextResponse.json({ error: "Daily limit exceeded" }, { status: 429 });
  }

  try {
    // Fetch user context for richer prompts (filtered by equipment selection)
    const userContext = await fetchUserContext(user.uid, requestBody.equipment);
    requestBody = { ...requestBody, userContext };

    const modelConfig = getAIModelConfig(entitlement.tier);
    if (!modelConfig.model) {
      return NextResponse.json({ error: "Cloud AI is not configured for this tier" }, { status: 403 });
    }
    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json({ error: "GEMINI_API_KEY is not configured on the server" }, { status: 500 });
    }

    const { GoogleGenAI } = await import("@google/genai");
    const client = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY!.trim(),
    });

    const prompt = buildWorkoutPrompt(requestBody);
    const systemInstruction = buildWorkoutSystemInstruction();

    const result = await client.models.generateContent({
      model: modelConfig.model,
      contents: prompt,
      config: {
        systemInstruction,
        responseMimeType: "application/json",
        temperature: modelConfig.temperature,
        maxOutputTokens: modelConfig.maxOutputTokens,
      },
    });

    const raw = typeof result.text === "string" ? result.text : "";
    if (!raw) {
      return NextResponse.json({ error: "No response from AI" }, { status: 502 });
    }

    const workout = parseAIWorkoutResponse(raw);

    const usage = await incrementDailyAIUsage(user.uid);

    const sanitizedRequest = JSON.parse(JSON.stringify(requestBody));
    await userCollection(user.uid, "generatedWorkoutRecords").add({
      request: sanitizedRequest,
      prompt,
      systemInstruction,
      response: JSON.parse(JSON.stringify(workout)),
      createdAt: new Date(),
      requestedTier: entitlement.subscription.tier,
      resolvedTier: entitlement.tier,
      status: "success",
      requestSource: "web-app-ai-workout",
      feature: "aiWorkout",
      model: modelConfig.model,
      usageDate: getUsageDateKey(),
      generatedToday: usage.count,
      remainingCloudGenerations: Math.max(0, entitlement.dailyCloudLimit - usage.count),
      dailyCloudLimit: entitlement.dailyCloudLimit,
      userEmail: user.email ?? null,
    });

    return NextResponse.json({
      ...workout,
      usage: {
        tier: entitlement.tier,
        generatedToday: usage.count,
        remainingCloudGenerations: Math.max(0, entitlement.dailyCloudLimit - usage.count),
        dailyCloudLimit: entitlement.dailyCloudLimit,
      },
    });
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : "AI generation failed";
    const errorStack = error instanceof Error ? error.stack : undefined;
    console.error("[ai/generate] Error:", errorMsg, errorStack);
    try {
      await userCollection(user.uid, "generatedWorkoutRecords").add({
        request: JSON.parse(JSON.stringify(requestBody)),
        createdAt: new Date(),
        requestedTier: entitlement.subscription.tier,
        resolvedTier: entitlement.tier,
        status: "error",
        requestSource: "web-app-ai-workout",
        feature: "aiWorkout",
        errorMessage: errorMsg,
        usageDate: getUsageDateKey(),
        userEmail: user.email ?? null,
      });
    } catch (logError) {
      console.error("[ai/generate] Failed to log error:", logError);
    }
    return NextResponse.json(
      { error: errorMsg },
      { status: 500 }
    );
  }
}
