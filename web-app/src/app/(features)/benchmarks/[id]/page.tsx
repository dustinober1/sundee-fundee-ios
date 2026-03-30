import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { PREDEFINED_BENCHMARKS } from "@/lib/domain";
import { getBenchmarkResults } from "../actions";
import { LogResultForm } from "./log-result-form";

function formatScore(value: number, type: string): string {
  switch (type) {
    case "time": {
      const hours = Math.floor(value / 3600);
      const min = Math.floor((value % 3600) / 60);
      const sec = Math.floor(value % 60);
      if (hours > 0) {
        return `${hours}:${String(min).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
      }
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

export default async function BenchmarkDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const benchmark = PREDEFINED_BENCHMARKS.find((b) => b.id === id);
  if (!benchmark) return <p>Benchmark not found.</p>;

  const allResults = await getBenchmarkResults();
  const results = allResults.filter((r) => r.definitionId === id);

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader
        label="Benchmark"
        title={benchmark.name}
        subtitle={benchmark.workoutDescription}
      />

      <span className="text-[11px] bg-navy/5 text-navy px-3 py-1 rounded-full font-mono tracking-wider uppercase self-start border border-navy/10">
        {benchmark.scoringType}
      </span>

      <LogResultForm definitionId={id} scoringType={benchmark.scoringType} />

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {results.length > 0 && (
        <Card>
          <SectionHeader label="Progress" title="History" />
          <div className="flex flex-col gap-0 mt-3">
            {results.map((r) => (
              <div key={r.id} className="flex justify-between text-[13px] py-3 border-b border-separator/30 last:border-0">
                <span className="text-text-secondary">
                  {r.performedAt ? new Date(r.performedAt).toLocaleDateString() : ""}
                </span>
                <span className="font-mono font-semibold">{formatScore(r.scoreValue, benchmark.scoringType)}</span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
