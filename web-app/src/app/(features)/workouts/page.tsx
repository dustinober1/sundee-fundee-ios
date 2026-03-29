import { Card } from "@/components/ui/card";

export default function WorkoutsPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Workouts</h1>
      <Card>
        <p className="text-text-secondary text-[13px]">Workout history will appear here.</p>
      </Card>
    </div>
  );
}
