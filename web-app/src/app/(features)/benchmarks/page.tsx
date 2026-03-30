import { Card } from "@/components/ui/card";
import { PageHeader, SectionLabel } from "@/components/ui/art-deco";
import { PREDEFINED_BENCHMARKS, groupedByCategory } from "@/lib/domain";
import { getBenchmarkResults } from "./actions";
import Link from "next/link";

export default async function BenchmarksPage() {
  const results = await getBenchmarkResults();
  const groups = groupedByCategory();

  // Map definitionId → best score
  const bestScores = new Map<string, number>();
  for (const r of results) {
    const current = bestScores.get(r.definitionId);
    if (current == null || r.scoreValue > current) {
      bestScores.set(r.definitionId, r.scoreValue);
    }
  }

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Performance" title="Benchmarks" />

      {Array.from(groups.entries()).map(([category, benchmarks]) => (
        <div key={category} className="flex flex-col gap-3">
          <div>
            <SectionLabel className="mb-0.5">{category}</SectionLabel>
            <h2>{category}</h2>
          </div>
          {benchmarks.map((bm) => {
            const best = bestScores.get(bm.id);
            return (
              <Link key={bm.id} href={`/benchmarks/${bm.id}`}>
                <Card className="hover:shadow-md hover:border-gold/20 border border-transparent transition-all">
                  <div className="flex justify-between items-center">
                    <div>
                      <p className="font-heading font-semibold text-[14px]">{bm.name}</p>
                      <p className="text-text-secondary text-[12px] line-clamp-1 mt-0.5">{bm.workoutDescription}</p>
                    </div>
                    {best != null ? (
                      <span className="text-orange font-bold font-mono text-[15px]">
                        {formatScore(best, bm.scoringType)}
                      </span>
                    ) : (
                      <span className="text-gold/30 text-[12px] font-mono">—</span>
                    )}
                  </div>
                </Card>
              </Link>
            );
          })}
        </div>
      ))}
    </div>
  );
}

function formatScore(value: number, type: string): string {
  switch (type) {
    case "time": {
      const min = Math.floor(value / 60);
      const sec = Math.floor(value % 60);
      return `${min}:${String(sec).padStart(2, "0")}`;
    }
    case "weight": return `${value} kg`;
    case "reps": return `${Math.floor(value)} reps`;
    case "roundsAndReps": {
      const rounds = Math.floor(value / 10000);
      const reps = Math.floor(value % 10000);
      return `${rounds}+${reps}`;
    }
    default: return String(value);
  }
}
