import { NextRequest, NextResponse } from "next/server";
import { getAuthUser, userCollection } from "@/lib/firestore";
import {
  buildWorkoutPrompt,
  buildWorkoutSystemInstruction,
  getAIModelConfig,
  parseAIWorkoutResponse,
  validateAIWorkoutRequest,
} from "@/lib/ai-generation";
import {
  getUsageDateKey,
  incrementDailyAIUsage,
  resolveEntitlement,
} from "@/lib/subscription-state";

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
    const modelConfig = getAIModelConfig(entitlement.tier);
    if (!modelConfig.model) {
      return NextResponse.json({ error: "Cloud AI is not configured for this tier" }, { status: 403 });
    }
    if (!process.env.GEMINI_API_KEY) {
      return NextResponse.json({ error: "GEMINI_API_KEY is not configured on the server" }, { status: 500 });
    }

    const { GoogleGenAI } = await import("@google/genai");
    const client = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
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

    await userCollection(user.uid, "generatedWorkoutRecords").add({
      request: requestBody,
      prompt,
      systemInstruction,
      response: workout,
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
        model: modelConfig.model,
        generatedToday: usage.count,
        remainingCloudGenerations: Math.max(0, entitlement.dailyCloudLimit - usage.count),
        dailyCloudLimit: entitlement.dailyCloudLimit,
      },
    });
  } catch (error) {
    await userCollection(user.uid, "generatedWorkoutRecords").add({
      request: requestBody,
      createdAt: new Date(),
      requestedTier: entitlement.subscription.tier,
      resolvedTier: entitlement.tier,
      status: "error",
      requestSource: "web-app-ai-workout",
      feature: "aiWorkout",
      errorMessage: error instanceof Error ? error.message : "AI generation failed",
      usageDate: getUsageDateKey(),
      userEmail: user.email ?? null,
    });
    return NextResponse.json(
      { error: error instanceof Error ? error.message : "AI generation failed" },
      { status: 500 }
    );
  }
}
