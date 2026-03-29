"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateWorkoutFn = void 0;
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const rate_limit_1 = require("./rate-limit");
const ai_1 = require("./ai");
(0, app_1.initializeApp)();
exports.generateWorkoutFn = (0, https_1.onCall)({ region: "us-central1", memory: "512MiB", timeoutSeconds: 120 }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be signed in");
    }
    const userId = request.auth.uid;
    const { prompt, systemInstruction } = request.data;
    if (!prompt || !systemInstruction) {
        throw new https_1.HttpsError("invalid-argument", "Missing prompt or systemInstruction");
    }
    const db = (0, firestore_1.getFirestore)();
    const subDoc = await db.collection("users").doc(userId)
        .collection("subscription").doc("current").get();
    const tier = subDoc.data()?.tier ?? "free";
    if (tier === "free") {
        throw new https_1.HttpsError("permission-denied", "Cloud AI requires a Plus or Premium subscription");
    }
    const rateResult = await (0, rate_limit_1.checkRateLimit)(userId, tier);
    if (!rateResult.allowed) {
        throw new https_1.HttpsError("resource-exhausted", "Daily limit exceeded", {
            remaining: 0,
            resetsAt: rateResult.resetsAt,
        });
    }
    const projectId = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? "";
    const workout = await (0, ai_1.generateWorkout)(projectId, prompt, systemInstruction);
    await db.collection("users").doc(userId).collection("generatedWorkoutRecords").add({
        prompt,
        response: JSON.stringify(workout),
        createdAt: new Date(),
    });
    return workout;
});
//# sourceMappingURL=index.js.map