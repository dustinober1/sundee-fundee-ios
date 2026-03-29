import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { checkRateLimit } from "./rate-limit";
import { generateWorkout } from "./ai";

initializeApp();

export const generateWorkoutFn = onCall(
  { region: "us-central1", memory: "512MiB", timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const userId = request.auth.uid;
    const { prompt, systemInstruction } = request.data as {
      prompt?: string;
      systemInstruction?: string;
    };

    if (!prompt || !systemInstruction) {
      throw new HttpsError("invalid-argument", "Missing prompt or systemInstruction");
    }

    const db = getFirestore();
    const subDoc = await db.collection("users").doc(userId)
      .collection("subscription").doc("current").get();
    const tier = (subDoc.data()?.tier as string) ?? "free";

    if (tier === "free") {
      throw new HttpsError("permission-denied", "Cloud AI requires a Plus or Premium subscription");
    }

    const rateResult = await checkRateLimit(userId, tier);
    if (!rateResult.allowed) {
      throw new HttpsError("resource-exhausted", "Daily limit exceeded", {
        remaining: 0,
        resetsAt: rateResult.resetsAt,
      });
    }

    const projectId = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? "";
    const workout = await generateWorkout(projectId, prompt, systemInstruction);

    await db.collection("users").doc(userId).collection("generatedWorkoutRecords").add({
      prompt,
      response: JSON.stringify(workout),
      createdAt: new Date(),
    });

    return workout;
  },
);
