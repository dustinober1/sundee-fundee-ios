import { getUserProfile } from "../../settings/actions";
import { WeightUnit } from "@/lib/domain";
import { WorkoutLogger } from "./workout-logger";

export default async function NewWorkoutPage() {
  const profile = await getUserProfile();
  const weightUnit = (profile?.weightUnit as WeightUnit) ?? WeightUnit.pounds;

  return <WorkoutLogger weightUnit={weightUnit} />;
}
