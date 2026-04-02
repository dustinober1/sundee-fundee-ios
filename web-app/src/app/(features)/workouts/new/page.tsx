import { getUserProfile } from "../../settings/actions";
import { WeightUnit, exerciseValueToString } from "@/lib/domain";
import type { ExerciseValue } from "@/lib/domain";
import { getSessionForEnrollment } from "../../programs/actions";
import { WorkoutLogger } from "./workout-logger";

interface NewWorkoutPageProps {
  searchParams: Promise<{ ai?: string; enrollment?: string }>;
}

function exerciseValueToNumber(ev: ExerciseValue): number {
  switch (ev.type) {
    case "fixed": return ev.value;
    case "range": return ev.low;
    case "amrap": return 1;
    case "text": return 1;
  }
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
        aiExercises = session.exercises.map((ex) => ({
          name: ex.exercise,
          sets: exerciseValueToNumber(ex.sets),
          reps: exerciseValueToString(ex.reps),
          bodyweightOnly: ex.bodyweightOnly ?? false,
        }));
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
