import { Card } from "@/components/ui/card";
import { PREDEFINED_BENCHMARKS } from "@/lib/domain";
import { getBenchmarkResults } from "../actions";
import { LogResultForm } from "./log-result-form";

export default async function BenchmarkDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const benchmark = PREDEFINED_BENCHMARKS.find((b) => b.id === id);
  if (!benchmark) return <p>Benchmark not found.</p>;

  const allResults = await getBenchmarkResults();
  const results = allResults.filter((r) => r.definitionId === id);

  return (
    <div className="flex flex-col gap-8 pt-6">
      <div className="pl-2">
        <p className="text-gold font-mono text-[10px] tracking-[0.3em] uppercase mb-1">Benchmark</p>
        <h1 className="text-3xl">{benchmark.name}</h1>
        <p className="text-text-secondary">{benchmark.workoutDescription}</p>
        <span className="text-[12px] bg-navy/5 text-navy px-2 py-0.5 rounded-sm mt-2 inline-block">
          {benchmark.scoringType}
        </span>
      </div>

      <LogResultForm definitionId={id} scoringType={benchmark.scoringType} />

      {results.length > 0 && (
        <Card>
          <h2 className="mb-spacing-sm">History</h2>
          <div className="flex flex-col gap-spacing-xs">
            {results.map((r) => (
              <div key={r.id} className="flex justify-between text-[13px] py-spacing-xs border-b border-separator/50 last:border-0">
                <span className="text-text-secondary">{r.performedAt ? new Date(r.performedAt).toLocaleDateString() : ""}</span>
                <span className="font-medium">{r.scoreValue}</span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
