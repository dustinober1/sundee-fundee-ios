import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
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
                <span className="font-mono font-semibold">{r.scoreValue}</span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
