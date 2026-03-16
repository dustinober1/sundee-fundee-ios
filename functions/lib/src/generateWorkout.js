"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateWorkout = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const admin = __importStar(require("firebase-admin"));
const generative_ai_1 = require("@google/generative-ai");
const workoutPrompt_1 = require("./prompts/workoutPrompt");
const GEMINI_API_KEY = (0, params_1.defineSecret)("GEMINI_API_KEY");
exports.generateWorkout = (0, https_1.onCall)({
    secrets: [GEMINI_API_KEY],
    memory: "256MiB",
    timeoutSeconds: 60,
    minInstances: 1,
    concurrency: 80,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be authenticated");
    }
    const userId = request.auth.uid;
    const context = request.data;
    if (!context.focus || !context.timeMinutes) {
        throw new https_1.HttpsError("invalid-argument", "Missing required fields: focus, timeMinutes");
    }
    const genAI = new generative_ai_1.GoogleGenerativeAI(GEMINI_API_KEY.value());
    const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" }, { apiVersion: "v1beta" });
    let workoutData;
    const maxRetries = 2;
    for (let attempt = 0; attempt < maxRetries; attempt++) {
        try {
            const result = await model.generateContent({
                systemInstruction: (0, workoutPrompt_1.buildSystemPrompt)(),
                contents: [{ role: "user", parts: [{ text: (0, workoutPrompt_1.buildUserPrompt)(context) }] }],
                generationConfig: {
                    responseMimeType: "application/json",
                    maxOutputTokens: 2048,
                },
            });
            const responseText = result.response.text();
            workoutData = JSON.parse(responseText);
            workoutData = validateWorkout(workoutData, context);
            break;
        }
        catch (error) {
            if (attempt === maxRetries - 1) {
                throw new https_1.HttpsError("internal", `Failed to generate workout: ${error}`);
            }
        }
    }
    // Store in Firestore
    const workoutId = admin.firestore().collection("generatedWorkouts").doc().id;
    const workoutDoc = {
        userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isFavorite: false,
        questionnaire: {
            timeMinutes: context.timeMinutes,
            focus: context.focus,
            energyLevel: context.energyLevel,
            equipment: context.equipment,
        },
        coachingSummary: workoutData.coachingSummary,
        exercises: workoutData.exercises.map((ex, i) => ({
            id: `${workoutId}-ex-${i}`,
            ...ex,
        })),
        metadata: {
            focus: context.focus,
            durationMinutes: context.timeMinutes,
            difficulty: context.experienceLevel,
            muscleGroups: extractMuscleGroups(workoutData.exercises),
        },
    };
    await admin
        .firestore()
        .collection("generatedWorkouts")
        .doc(workoutId)
        .set(workoutDoc);
    return {
        id: workoutId,
        ...workoutDoc,
        createdAt: new Date().toISOString(),
    };
});
function validateWorkout(data, context) {
    if (!data.exercises ||
        !Array.isArray(data.exercises) ||
        data.exercises.length === 0) {
        throw new Error("Invalid workout: no exercises");
    }
    if (!data.coachingSummary || typeof data.coachingSummary !== "string") {
        data.coachingSummary = "AI-generated workout session.";
    }
    const maxDict = new Map(context.maxes.map((m) => [m.name, m.weightLb]));
    const injuredLocations = context.activeInjuries.map((i) => i.location.toLowerCase());
    data.exercises = data.exercises
        .filter((ex) => {
        // Filter out exercises targeting injured areas
        const name = ex.name.toLowerCase();
        return !injuredLocations.some((loc) => {
            if (loc.includes("knee"))
                return ["squat", "lunge", "leg press"].some((k) => name.includes(k));
            if (loc.includes("shoulder"))
                return ["press", "overhead", "bench"].some((k) => name.includes(k));
            if (loc.includes("back"))
                return ["deadlift", "row"].some((k) => name.includes(k));
            return false;
        });
    })
        .map((ex) => {
        // Cap weights at known maxes
        if (ex.weightLb) {
            const orm = maxDict.get(ex.name);
            if (orm && ex.weightLb > orm) {
                ex.weightLb = Math.round((orm * 0.8) / 5) * 5;
            }
        }
        ex.sets = Math.max(1, Math.min(10, ex.sets || 3));
        ex.bodyweightOnly = ex.bodyweightOnly ?? false;
        return ex;
    });
    return data;
}
function extractMuscleGroups(exercises) {
    const groups = new Set();
    for (const ex of exercises) {
        const name = ex.name.toLowerCase();
        if (name.includes("squat") || name.includes("lunge"))
            groups.add("Quads");
        if (name.includes("deadlift") || name.includes("hip thrust"))
            groups.add("Glutes");
        if (name.includes("bench") || name.includes("push"))
            groups.add("Chest");
        if (name.includes("row") || name.includes("pull"))
            groups.add("Back");
        if (name.includes("press") && name.includes("overhead"))
            groups.add("Shoulders");
        if (name.includes("curl"))
            groups.add("Biceps");
        if (name.includes("tricep"))
            groups.add("Triceps");
    }
    return Array.from(groups);
}
//# sourceMappingURL=generateWorkout.js.map