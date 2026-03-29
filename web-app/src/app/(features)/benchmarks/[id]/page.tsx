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
    <div className="flex flex-col gap-spacing-md">
      <div>
        <h1>{benchmark.name}</h1>
        <p className="text-text-secondary">{benchmark.workoutDescription}</p>
        <span className="text-[12px] bg-navy/5 text-navy px-2 py-0.5 rounded-sm mt-spacing-xs inline-block">
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
