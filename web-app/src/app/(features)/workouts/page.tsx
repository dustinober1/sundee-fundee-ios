import { Card } from "@/components/ui/card";
import Link from "next/link";
import { getRecentWorkouts } from "./actions";

export default async function WorkoutsPage() {
  const workouts = await getRecentWorkouts();

  return (
    <div className="flex flex-col gap-spacing-lg">
      <div className="flex items-center justify-between">
        <h1>Workouts</h1>
        <Link
          href="/workouts/new"
          className="bg-orange text-cream rounded-button px-spacing-md py-spacing-xs text-[14px] font-medium hover:opacity-90"
        >
          + New
        </Link>
      </div>

      {workouts.length === 0 ? (
        <Card>
          <div className="text-center py-spacing-lg">
            <p className="text-text-secondary mb-spacing-sm">No workouts logged yet.</p>
            <Link href="/workouts/new" className="text-orange font-medium text-[14px]">
              Log your first workout
            </Link>
          </div>
        </Card>
      ) : (
        <div className="flex flex-col gap-spacing-sm">
          {workouts.map((w) => (
            <Card key={w.id}>
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-medium">{w.programId || "Quick Workout"}</p>
                  <p className="text-text-secondary text-[13px]">
                    {w.completedAt ? new Date(w.completedAt).toLocaleDateString() : ""}
                    {w.durationSeconds ? ` · ${Math.round((w.durationSeconds ?? 0) / 60)} min` : ""}
                  </p>
                </div>
                {w.perceivedEffort && (
                  <span className="text-orange font-bold">{w.perceivedEffort}/10</span>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
