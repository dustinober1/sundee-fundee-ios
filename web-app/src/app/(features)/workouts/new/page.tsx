import { getUserProfile } from "../../settings/actions";
import { WeightUnit, exerciseValueToString } from "@/lib/domain";
import type { ExerciseValue } from "@/lib/domain";
import { getSessionForEnrollment } from "../../programs/actions";
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
    const session = await getSessionForEnrollment(params.enrollment);
    if (session) {
      programContext = {
        programId: session.programId,
        sessionId: session.sessionId,
        sessionName: session.sessionName,
        enrollmentId: session.enrollmentId,
      };
      if (session.exercises && session.exercises.length > 0) {
        aiExercises = session.exercises.map((ex) => {
          const repsStr = exerciseValueToString(ex.reps);
          return {
            name: ex.exercise,
            sets: exerciseValueToNumber(ex.sets, 3),    // default 3 sets if unspecified
            reps: repsStr === "0" ? "" : repsStr,        // leave blank for user to fill in
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
