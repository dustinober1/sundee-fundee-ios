import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";
import {
  buildSystemPrompt,
  buildUserPrompt,
  WorkoutContext,
} from "./prompts/workoutPrompt";

const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

interface GeneratedExercise {
  name: string;
  sets: number;
  reps: string;
  weightLb: number | null;
  restMinutes: number | null;
  notes: string | null;
  reasoning: string | null;
  bodyweightOnly: boolean;
}

interface GeneratedWorkoutResponse {
  coachingSummary: string;
  exercises: GeneratedExercise[];
}

export const generateWorkout = onCall(
  {
    secrets: [ANTHROPIC_API_KEY],
    memory: "256MiB",
    timeoutSeconds: 60,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const userId = request.auth.uid;
    const context = request.data as WorkoutContext;

    if (!context.focus || !context.timeMinutes) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields: focus, timeMinutes"
      );
    }

    const client = new Anthropic({ apiKey: ANTHROPIC_API_KEY.value() });

    let workoutData: GeneratedWorkoutResponse;
    const maxRetries = 2;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const message = await client.messages.create({
          model: "claude-haiku-4-5-20251001",
          max_tokens: 2048,
          system: buildSystemPrompt(),
          messages: [{ role: "user", content: buildUserPrompt(context) }],
        });

        const textBlock = message.content.find((b) => b.type === "text");
        if (!textBlock || textBlock.type !== "text") {
          throw new Error("No text response from Claude");
        }

        workoutData = JSON.parse(textBlock.text);
        workoutData = validateWorkout(workoutData, context);
        break;
      } catch (error) {
        if (attempt === maxRetries - 1) {
          throw new HttpsError(
            "internal",
            `Failed to generate workout: ${error}`
          );
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
      coachingSummary: workoutData!.coachingSummary,
      exercises: workoutData!.exercises.map((ex, i) => ({
        id: `${workoutId}-ex-${i}`,
        ...ex,
      })),
      metadata: {
        focus: context.focus,
        durationMinutes: context.timeMinutes,
        difficulty: context.experienceLevel,
        muscleGroups: extractMuscleGroups(workoutData!.exercises),
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
  }
);

function validateWorkout(
  data: GeneratedWorkoutResponse,
  context: WorkoutContext
): GeneratedWorkoutResponse {
  if (
    !data.exercises ||
    !Array.isArray(data.exercises) ||
    data.exercises.length === 0
  ) {
    throw new Error("Invalid workout: no exercises");
  }

  if (!data.coachingSummary || typeof data.coachingSummary !== "string") {
    data.coachingSummary = "AI-generated workout session.";
  }

  const maxDict = new Map(context.maxes.map((m) => [m.name, m.weightLb]));
  const injuredLocations = context.activeInjuries.map((i) =>
    i.location.toLowerCase()
  );

  data.exercises = data.exercises
    .filter((ex) => {
      // Filter out exercises targeting injured areas
      const name = ex.name.toLowerCase();
      return !injuredLocations.some((loc) => {
        if (loc.includes("knee"))
          return ["squat", "lunge", "leg press"].some((k) =>
            name.includes(k)
          );
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

function extractMuscleGroups(exercises: GeneratedExercise[]): string[] {
  const groups = new Set<string>();
  for (const ex of exercises) {
    const name = ex.name.toLowerCase();
    if (name.includes("squat") || name.includes("lunge")) groups.add("Quads");
    if (name.includes("deadlift") || name.includes("hip thrust"))
      groups.add("Glutes");
    if (name.includes("bench") || name.includes("push")) groups.add("Chest");
    if (name.includes("row") || name.includes("pull")) groups.add("Back");
    if (name.includes("press") && name.includes("overhead"))
      groups.add("Shoulders");
    if (name.includes("curl")) groups.add("Biceps");
    if (name.includes("tricep")) groups.add("Triceps");
  }
  return Array.from(groups);
}
