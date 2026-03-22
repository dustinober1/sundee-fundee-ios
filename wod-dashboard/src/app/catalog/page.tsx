import {
  weightliftingExercises,
  conditioningExercises,
  type WeightliftingExercise,
  type ConditioningExercise,
} from "@/lib/exercise-catalog";

// ─── Helpers ─────────────────────────────────────────────────────────────────

const WEIGHTLIFTING_CATEGORIES: WeightliftingExercise["category"][] = [
  "Squat",
  "Hip Hinge",
  "Press",
  "Pull",
  "Carry",
  "Olympic Weightlifting",
];

const CONDITIONING_SCORING: ConditioningExercise["scoring"][] = [
  "Reps",
  "Time",
];

const SCORING_LABEL: Record<ConditioningExercise["scoring"], string> = {
  Reps: "Reps-based",
  Time: "Time-based",
};

// ─── Sub-components ──────────────────────────────────────────────────────────

function SectionHeader({ title, count }: { title: string; count: number }) {
  return (
    <div className="flex items-baseline gap-3 mb-6">
      <h2 className="text-2xl font-bold tracking-wide text-navy uppercase">
        {title}
      </h2>
      <span className="text-sm font-medium text-orange border border-orange/40 px-2 py-0.5 rounded">
        {count} exercises
      </span>
    </div>
  );
}

function CategoryBlock({ heading, exercises }: { heading: string; exercises: string[] }) {
  return (
    <div className="mb-6">
      <h3 className="text-xs font-bold uppercase tracking-widest text-navy/50 mb-2 pb-1 border-b border-navy/10">
        {heading}
        <span className="ml-2 font-normal normal-case tracking-normal text-navy/30">
          ({exercises.length})
        </span>
      </h3>
      <ul className="grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-1.5">
        {exercises.map((name) => (
          <li
            key={name}
            className="text-sm text-navy/80 py-0.5 border-b border-navy/5 last:border-0"
          >
            {name}
          </li>
        ))}
      </ul>
    </div>
  );
}

// ─── Page ────────────────────────────────────────────────────────────────────

export default function CatalogPage() {
  return (
    <div className="max-w-4xl mx-auto space-y-10">
      {/* Page title */}
      <div className="border-b-2 border-navy/20 pb-4">
        <h1 className="text-3xl font-bold tracking-wide text-navy uppercase">
          Exercise Catalog
        </h1>
        <p className="mt-1 text-sm text-navy/50">
          Read-only reference of all tracked exercises
        </p>
      </div>

      {/* ── Weightlifting ─────────────────────────────────────────────────── */}
      <section>
        <SectionHeader
          title="Weightlifting"
          count={weightliftingExercises.length}
        />
        <div className="bg-white border border-navy/10 rounded p-6 space-y-2">
          {WEIGHTLIFTING_CATEGORIES.map((cat) => {
            const exercises = weightliftingExercises
              .filter((e) => e.category === cat)
              .map((e) => e.name);
            return (
              <CategoryBlock key={cat} heading={cat} exercises={exercises} />
            );
          })}
        </div>
      </section>

      {/* ── Conditioning ──────────────────────────────────────────────────── */}
      <section>
        <SectionHeader
          title="Conditioning"
          count={conditioningExercises.length}
        />
        <div className="bg-white border border-navy/10 rounded p-6 space-y-2">
          {CONDITIONING_SCORING.map((scoring) => {
            const exercises = conditioningExercises
              .filter((e) => e.scoring === scoring)
              .map((e) => e.name);
            return (
              <CategoryBlock
                key={scoring}
                heading={SCORING_LABEL[scoring]}
                exercises={exercises}
              />
            );
          })}
        </div>
      </section>
    </div>
  );
}
