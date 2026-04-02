import { getUserProfile } from "../../settings/actions";
import { WeightUnit, exerciseValueToString, findMatchingMax } from "@/lib/domain";
import type { ExerciseValue } from "@/lib/domain";
import { getSessionForEnrollment } from "../../programs/actions";
import { getMaxes } from "../../maxes/actions";
import { WorkoutLogger } from "./workout-logger";

interface NewWorkoutPageProps {
  searchParams: Promise<{ ai?: string; enrollment?: string }>;
}

function exerciseValueToNumber(ev: ExerciseValue, min = 0): number {
  let val: number;
  switch (ev.type) {
    case "fixed": val = ev.value; break;
    case "range": val = ev.low; break;
    case "amrap": val = 1; break;
    case "text": val = 1; break;
  }
  return val > 0 ? val : min;
}

export default async function NewWorkoutPage({ searchParams }: NewWorkoutPageProps) {
  const profile = await getUserProfile();
  const weightUnit = (profile?.weightUnit as WeightUnit) ?? WeightUnit.pounds;
  const params = await searchParams;

  let aiExercises: Array<{
    name: string;
    sets: number;
    reps: string;
    weightKg?: number;
    bodyweightOnly: boolean;
  }> | undefined;

  let programContext: {
    programId: string;
    sessionId: string;
    sessionName: string;
    enrollmentId: string;
  } | undefined;

  if (params.enrollment) {
    const [session, userMaxes] = await Promise.all([
      getSessionForEnrollment(params.enrollment),
      getMaxes(),
    ]);
    if (session) {
      programContext = {
        programId: session.programId,
        sessionId: session.sessionId,
        sessionName: session.sessionName,
        enrollmentId: session.enrollmentId,
      };
      if (session.exercises && session.exercises.length > 0) {
        // Convert user maxes to the format findMatchingMax expects
        const maxesList = userMaxes.map((m: any) => ({ name: m.exerciseId, weightKg: m.weightKg }));

        aiExercises = session.exercises.map((ex) => {
          const repsStr = exerciseValueToString(ex.reps);

          // Calculate weight from percent1RM and user's max
          let weightKg: number | undefined;
          if (ex.percent1RM && !ex.bodyweightOnly) {
            const matched = findMatchingMax(ex.exercise, maxesList);
            if (matched) {
              weightKg = Math.round((matched.weightKg * ex.percent1RM) / 2.5) * 2.5; // round to nearest 2.5kg
            }
          }

          return {
            name: ex.exercise,
            sets: exerciseValueToNumber(ex.sets, 3),
            reps: repsStr === "0" ? "" : repsStr,
            weightKg,
            bodyweightOnly: ex.bodyweightOnly ?? false,
          };
        });
      }
    }
  } else if (params.ai) {
    try {
      aiExercises = JSON.parse(decodeURIComponent(params.ai));
    } catch {
      // Invalid data — continue without pre-populated exercises
    }
  }

  return <WorkoutLogger weightUnit={weightUnit} aiExercises={aiExercises} programContext={programContext} />;
}
