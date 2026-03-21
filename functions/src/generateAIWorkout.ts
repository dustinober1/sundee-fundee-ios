/**
 * generateAIWorkout Cloud Function (BACK-01)
 *
 * Firebase Functions v2 onCall function that accepts a WorkoutGenerationContext,
 * calls Gemini to generate a personalized workout, and returns a GeneratedWorkout-shaped response.
 *
 * Auth gating: unauthenticated calls are rejected with HttpsError('unauthenticated').
 * Input validation: missing timeMinutes, focus, or equipment throws HttpsError('invalid-argument').
 * Error handling: Gemini parse failures throw HttpsError('internal').
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import * as logger from 'firebase-functions/logger';
import { GoogleGenAI } from '@google/genai';
import { getFirestore } from 'firebase-admin/firestore';

const DAILY_AI_LIMIT = 5;

const geminiApiKey = defineSecret('GEMINI_API_KEY');

// ---------------------------------------------------------------------------
// Prompt
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT = `You are a professional strength and conditioning coach who creates personalized workout programs.
Your role is to generate evidence-based workouts tailored to each athlete's unique context including:
- Their training experience and goals
- Available equipment and time constraints
- Current energy levels and readiness
- Active injuries and physical limitations
- Hormonal cycle phase (if provided) for female athletes
- Recent training history to avoid overtraining

Always return valid JSON matching the exact schema requested. Never include markdown, code blocks, or extra text.
Prioritize exercise safety and progressive overload principles.`;

function buildWorkoutPrompt(data: Record<string, unknown>): string {
  const {
    timeMinutes,
    focus,
    energyLevel,
    equipment,
    maxes,
    recentWorkouts,
    cyclePhase,
    readinessTier,
    activeInjuries,
    experienceLevel,
    primaryGoal,
    gender,
    weightUnit,
    desiredSkills,
    bodyWeightKg,
    workoutCompletionRate,
    travelModeEnabled,
  } = data as Record<string, unknown>;

  const maxesSummary =
    Array.isArray(maxes) && maxes.length > 0
      ? (maxes as Array<{ name: string; weightLb: number }>)
          .map((m) => `${m.name}: ${m.weightLb}lb`)
          .join(', ')
      : 'No maxes recorded';

  const injurySummary =
    Array.isArray(activeInjuries) && (activeInjuries as unknown[]).length > 0
      ? `Active injuries: ${JSON.stringify(activeInjuries)}`
      : 'No active injuries';

  const cyclePhaseLine =
    cyclePhase ? `Hormonal cycle phase: ${cyclePhase}` : 'Cycle phase: not provided';
  const readinessLine =
    readinessTier ? `Readiness tier: ${readinessTier}` : 'Readiness: not assessed';

  return `Generate a personalized ${timeMinutes}-minute strength workout for this athlete:

ATHLETE PROFILE:
- Experience level: ${experienceLevel}
- Primary goal: ${primaryGoal}
- Gender: ${gender}
- Body weight: ${bodyWeightKg ? `${bodyWeightKg}kg` : 'not provided'}
- Weight unit preference: ${weightUnit}

WORKOUT PARAMETERS:
- Duration: ${timeMinutes} minutes
- Focus area: ${focus}
- Energy level today: ${energyLevel}
- Equipment available: ${equipment}
- Travel mode: ${travelModeEnabled ? 'Yes (bodyweight/hotel gym focus)' : 'No'}

ATHLETE CONTEXT:
- ${cyclePhaseLine}
- ${readinessLine}
- ${injurySummary}
- Known maxes: ${maxesSummary}
- Recent workout count: ${Array.isArray(recentWorkouts) ? (recentWorkouts as unknown[]).length : 0}
- Workout completion rate: ${workoutCompletionRate !== null && workoutCompletionRate !== undefined ? `${Math.round((workoutCompletionRate as number) * 100)}%` : 'unknown'}
- Desired skills to develop: ${Array.isArray(desiredSkills) && (desiredSkills as unknown[]).length > 0 ? (desiredSkills as string[]).join(', ') : 'none specified'}

Return a JSON object with this exact structure:
{
  "coachingSummary": "2-3 sentence explanation of the workout rationale, personalized to this athlete's context",
  "exercises": [
    {
      "name": "Exercise name",
      "sets": 3,
      "reps": "5" or "8-10" or "AMRAP",
      "weightLb": 135 or null (null for bodyweight),
      "restMinutes": 2 or null,
      "notes": "Form cue or scaling option" or null,
      "reasoning": "Why this exercise was selected for this athlete" or null,
      "bodyweightOnly": false
    }
  ]
}

Include 3-6 exercises appropriate for the time budget, focus, and equipment.
If weights are specified in lbs, snap to realistic barbell (5lb increments) or dumbbell (nearest 5) increments.
If athlete has a relevant max, use 70-85% of that max for working weight based on energy level.`;
}

// ---------------------------------------------------------------------------
// Input validation
// ---------------------------------------------------------------------------

function validateInput(data: Record<string, unknown>): void {
  if (data.timeMinutes === undefined || data.timeMinutes === null) {
    throw new HttpsError('invalid-argument', 'timeMinutes is required.');
  }
  if (!data.focus) {
    throw new HttpsError('invalid-argument', 'focus is required.');
  }
  if (!data.equipment) {
    throw new HttpsError('invalid-argument', 'equipment is required.');
  }
}

// ---------------------------------------------------------------------------
// Cloud Function
// ---------------------------------------------------------------------------

export const generateAIWorkout = onCall(
  { secrets: [geminiApiKey], region: 'us-central1' },
  async (request) => {
    // Auth gate: reject unauthenticated calls
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Must be signed in to generate workouts.');
    }

    const uid = request.auth.uid;
    const data = request.data as Record<string, unknown>;

    // Rate limit check (SEC-04): max 5 AI workouts per user per UTC day
    const today = new Date().toISOString().slice(0, 10);
    const db = getFirestore();
    const rateLimitRef = db.collection('users').doc(uid)
      .collection('rateLimits').doc('aiWorkout');

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(rateLimitRef);
      const data_rl = snap.data() as { date: string; count: number } | undefined;

      if (data_rl && data_rl.date === today && data_rl.count >= DAILY_AI_LIMIT) {
        throw new HttpsError(
          'resource-exhausted',
          'Daily AI workout limit reached (5 per day). Try again tomorrow.'
        );
      }

      if (data_rl && data_rl.date === today) {
        tx.update(rateLimitRef, { count: data_rl.count + 1 });
      } else {
        tx.set(rateLimitRef, { date: today, count: 1 });
      }
    });

    logger.info('Rate limit check passed', { uid, today });

    // Input validation
    validateInput(data);

    logger.info('Generating AI workout', {
      uid,
      timeMinutes: data.timeMinutes,
      focus: data.focus,
      equipment: data.equipment,
      energyLevel: data.energyLevel,
    });

    // Call Gemini
    const ai = new GoogleGenAI({ apiKey: geminiApiKey.value() });
    const userPrompt = buildWorkoutPrompt(data);

    let responseText: string;
    try {
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: userPrompt,
        config: {
          systemInstruction: SYSTEM_PROMPT,
          responseMimeType: 'application/json',
        },
      });
      responseText = response.text ?? '';
    } catch (err) {
      logger.error('Gemini API call failed', { uid, error: err });
      throw new HttpsError('internal', 'Failed to contact AI service. Please try again.');
    }

    // Parse the response
    let parsed: { coachingSummary: string; exercises: unknown[] };
    try {
      // Strip markdown code fences if present (safety net)
      const cleaned = responseText
        .replace(/^```json\s*/i, '')
        .replace(/^```\s*/i, '')
        .replace(/\s*```$/i, '')
        .trim();
      parsed = JSON.parse(cleaned) as { coachingSummary: string; exercises: unknown[] };
    } catch (parseErr) {
      logger.error('Failed to parse Gemini response', { uid, responseText, error: parseErr });
      throw new HttpsError('internal', 'Failed to parse AI response. Please try again.');
    }

    // Basic shape validation
    if (!parsed.exercises || !Array.isArray(parsed.exercises)) {
      logger.error('Gemini response missing exercises array', { uid, parsed });
      throw new HttpsError('internal', 'AI returned an unexpected response format.');
    }

    logger.info('AI workout generated successfully', {
      uid,
      exerciseCount: parsed.exercises.length,
    });

    return {
      coachingSummary: parsed.coachingSummary ?? '',
      exercises: parsed.exercises,
    };
  }
);
