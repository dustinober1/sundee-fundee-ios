import { Card } from "@/components/ui/card";
import { PageHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import Link from "next/link";
import { getRecentWorkouts } from "./actions";

export default async function WorkoutsPage() {
  const workouts = await getRecentWorkouts();

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader
        label="Train"
        title="Workouts"
        action={
          <Link
            href="/workouts/new"
            className="bg-orange text-cream rounded-button px-5 py-2 text-[13px] font-semibold hover:opacity-90 transition-opacity shadow-md shadow-orange/20"
          >
            + New
          </Link>
        }
      />

      <div className="flex gap-3">
        <Link
          href="/workouts/new"
          className="flex-1 text-center bg-navy text-cream rounded-button py-3 text-[13px] font-semibold hover:opacity-90 transition-opacity"
        >
          Quick Workout
        </Link>
        <Link
          href="/workouts/ai"
          className="flex-1 text-center bg-card-bg text-navy border border-gold/20 rounded-button py-3 text-[13px] font-semibold hover:border-gold/40 transition-colors"
        >
          AI Generate
        </Link>
      </div>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {workouts.length === 0 ? (
        <Card>
          <div className="text-center py-8">
            <div className="text-gold/30 mb-4">
              <svg className="w-12 h-12 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
            </div>
            <p className="text-text-secondary mb-3">No workouts logged yet.</p>
            <Link href="/workouts/new" className="text-orange font-semibold text-[14px] hover:underline">
              Log your first workout
            </Link>
          </div>
        </Card>
      ) : (
        <div className="flex flex-col gap-3">
          {workouts.map((w) => (
            <Card key={w.id} className="hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-heading font-semibold">{w.programId || "Quick Workout"}</p>
                  <p className="text-text-secondary text-[13px] mt-0.5">
                    {w.completedAt ? new Date(w.completedAt).toLocaleDateString() : ""}
                    {w.durationSeconds ? ` · ${Math.round((w.durationSeconds ?? 0) / 60)} min` : ""}
                  </p>
                </div>
                {w.perceivedEffort && (
                  <span className="text-orange font-bold font-mono text-lg">{w.perceivedEffort}/10</span>
                )}
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
