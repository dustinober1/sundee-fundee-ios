import { NextRequest, NextResponse } from "next/server";
import { getAuthUser, userCollection, userDoc } from "@/lib/firestore";
import {
  buildWorkoutPrompt,
  buildWorkoutSystemInstruction,
  getAIModelConfig,
  parseAIWorkoutResponse,
  validateAIWorkoutRequest,
  type UserContext,
} from "@/lib/ai-generation";
import {
  getUsageDateKey,
  incrementDailyAIUsage,
  resolveEntitlement,
} from "@/lib/subscription-state";

async function fetchUserContext(uid: string): Promise<UserContext> {
  const ctx: UserContext = {};

  // Fetch profile, maxes, and recent workouts in parallel
  const [profileSnap, maxesSnap, workoutsSnap] = await Promise.all([
    userDoc(uid).get(),
    userCollection(uid, "oneRepMaxes").orderBy("date", "desc").limit(20).get(),
    userCollection(uid, "completedWorkouts").orderBy("completedAt", "desc").limit(5).get(),
  ]);

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
    // Fetch user context for richer prompts
    const userContext = await fetchUserContext(user.uid);
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
