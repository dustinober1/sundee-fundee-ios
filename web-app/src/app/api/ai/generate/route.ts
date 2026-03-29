import { NextRequest, NextResponse } from "next/server";
import { getAuthUser, userCollection } from "@/lib/firestore";
import { db } from "@/lib/firebase-admin";

export async function POST(req: NextRequest) {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await req.json()) as { prompt?: string; systemInstruction?: string };
  if (!body.prompt || !body.systemInstruction) {
    return NextResponse.json({ error: "Missing prompt or systemInstruction" }, { status: 400 });
  }

  // Check subscription tier
  const subDoc = await db.collection("users").doc(user.uid)
    .collection("subscription").doc("current").get();
  const tier = (subDoc.data()?.tier as string) ?? "free";

  if (tier === "free") {
    return NextResponse.json({ error: "Cloud AI requires a Plus or Premium subscription" }, { status: 403 });
  }

  // Rate limit
  const tierLimits: Record<string, number> = { plus: 1, premium: 10 };
  const limit = tierLimits[tier] ?? 0;
  const today = new Date().toISOString().split("T")[0];
  const usageRef = db.collection("users").doc(user.uid).collection("aiUsage").doc(today);
  const usageDoc = await usageRef.get();
  const current = (usageDoc.data()?.count as number) ?? 0;

  if (current >= limit) {
    return NextResponse.json({ error: "Daily limit exceeded" }, { status: 429 });
  }

  try {
    const { VertexAI } = await import("@google-cloud/vertexai");
    const vertexAI = new VertexAI({
      project: process.env.FIREBASE_PROJECT_ID!,
      location: "us-central1",
    });
    const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash" });

    const result = await model.generateContent({
      systemInstruction: { role: "system", parts: [{ text: body.systemInstruction }] },
      contents: [{ role: "user", parts: [{ text: body.prompt }] }],
      generationConfig: { responseMimeType: "application/json" },
    });

    const raw = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) {
      return NextResponse.json({ error: "No response from AI" }, { status: 502 });
    }

    const workout = JSON.parse(raw);

    // Increment usage
    await usageRef.set({ count: current + 1, updatedAt: new Date() }, { merge: true });

    // Save record
    await userCollection(user.uid, "generatedWorkoutRecords").add({
      prompt: body.prompt,
      response: JSON.stringify(workout),
      createdAt: new Date(),
    });

    return NextResponse.json(workout);
  } catch {
    return NextResponse.json({ error: "AI generation failed" }, { status: 500 });
  }
}
