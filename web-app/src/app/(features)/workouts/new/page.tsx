import { getUserProfile } from "../../settings/actions";
import { WeightUnit } from "@/lib/domain";
import { WorkoutLogger } from "./workout-logger";

interface NewWorkoutPageProps {
  searchParams: Promise<{ ai?: string }>;
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

  if (params.ai) {
    try {
      aiExercises = JSON.parse(decodeURIComponent(params.ai));
    } catch {
      // Invalid data — continue without pre-populated exercises
    }
  }

  return <WorkoutLogger weightUnit={weightUnit} aiExercises={aiExercises} />;
}
