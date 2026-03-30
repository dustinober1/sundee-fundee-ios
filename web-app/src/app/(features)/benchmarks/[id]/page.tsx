import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall, StatCard } from "@/components/ui/art-deco";
import { PREDEFINED_BENCHMARKS, type CyclePhase } from "@/lib/domain";
import { calculateBenchmarkReadiness, getBestAttemptWindow } from "@/lib/domain/benchmark-readiness";
import { getBenchmarkResults } from "../actions";
import { getCycleStatus, getCycleSettings, getPeriodLogs } from "../../cycle/actions";
import { LogResultForm } from "./log-result-form";
import {
  ReadinessPanel,
  IntensityGauge,
  MovementTags,
  EquipmentIcons,
  TimeDomainBadge,
  CoachNotesCard,
  PRTrendIndicator,
} from "@/components/ui/benchmark-ui";

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

// Determine if lower score is better (time-based)
function isLowerBetter(scoringType: string): boolean {
  return scoringType === "time";
}

export default async function BenchmarkDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const benchmark = PREDEFINED_BENCHMARKS.find((b) => b.id === id);
  if (!benchmark) return <p>Benchmark not found.</p>;

  // Fetch all data in parallel
  const [allResults, cycleStatus, cycleSettings, periodLogs] = await Promise.all([
    getBenchmarkResults(),
    getCycleStatus(),
    getCycleSettings(),
    getPeriodLogs(),
  ]);

  const results = allResults.filter((r) => r.definitionId === id);
  const currentPhase = cycleStatus?.currentPhase ?? null;

  // Calculate readiness
  const readiness = calculateBenchmarkReadiness(
    currentPhase,
    benchmark.intensity,
    benchmark.movementTags
  );

  // Calculate PR info
  const sortedResults = [...results].sort((a, b) => {
    const dateA = a.performedAt ? new Date(a.performedAt).getTime() : 0;
    const dateB = b.performedAt ? new Date(b.performedAt).getTime() : 0;
    return dateB - dateA; // Most recent first
  });

  const lowerIsBetter = isLowerBetter(benchmark.scoringType);
  const bestResult = results.length > 0
    ? results.reduce((best, r) => {
        if (!best) return r;
        return lowerIsBetter
          ? (r.scoreValue < best.scoreValue ? r : best)
          : (r.scoreValue > best.scoreValue ? r : best);
      }, results[0])
    : null;

  // Calculate best attempt window
  let bestWindow: { startDate: Date; endDate: Date; reason: string } | null = null;
  if (periodLogs.length > 0 && cycleSettings) {
    const lastPeriod = periodLogs[0];
    if (lastPeriod?.startDate) {
      bestWindow = getBestAttemptWindow(
        cycleSettings.averageCycleLengthDays ?? 28,
        new Date(lastPeriod.startDate)
      );
    }
  }

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader
        label="Benchmark"
        title={benchmark.name}
        subtitle={benchmark.workoutDescription}
      />

      {/* Scoring type badge */}
      <span className="text-[11px] bg-navy/5 text-navy px-3 py-1 rounded-full font-mono tracking-wider uppercase self-start border border-navy/10">
        {benchmark.scoringType}
      </span>

      {/* Enhanced tags row */}
      <div className="flex flex-wrap items-center gap-3">
        {benchmark.intensity && (
          <IntensityGauge intensity={benchmark.intensity} />
        )}
        {benchmark.movementTags && (
          <MovementTags tags={benchmark.movementTags} />
        )}
        {benchmark.timeDomain && (
          <TimeDomainBadge timeDomain={benchmark.timeDomain} />
        )}
        {benchmark.equipment && (
          <EquipmentIcons equipment={benchmark.equipment} />
        )}
      </div>

      {/* Readiness Panel */}
      <ReadinessPanel
        tier={readiness.tier}
        reason={readiness.reason}
        recommendation={readiness.recommendation}
        emoji={readiness.emoji}
        color={readiness.color}
        phaseMultiplier={readiness.phaseMultiplier}
      />

      {/* Best Window Predictor */}
      {bestWindow && (
        <Card className="bg-cream/50">
          <div className="flex items-start gap-3">
            <span className="text-xl">📅</span>
            <div>
              <p className="text-[12px] font-semibold text-navy font-heading">Best Window for PR</p>
              <p className="text-[11px] text-text-secondary mt-0.5">
                {bestWindow.startDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })} – {bestWindow.endDate.toLocaleDateString("en-US", { month: "short", day: "numeric" })}
              </p>
              <p className="text-[10px] text-text-secondary mt-1">{bestWindow.reason}</p>
            </div>
          </div>
        </Card>
      )}

      {/* Log Result Form */}
      <LogResultForm definitionId={id} scoringType={benchmark.scoringType} />

      {/* Coach Notes */}
      {benchmark.coachNotes && (
        <CoachNotesCard notes={benchmark.coachNotes} />
      )}

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {/* PR Stats */}
      {bestResult && (
        <div className="grid grid-cols-2 gap-3">
          <StatCard
            label="Best Score"
            value={formatScore(bestResult.scoreValue, benchmark.scoringType)}
          />
          <StatCard
            label="Attempts"
            value={results.length.toString()}
          />
        </div>
      )}

      {/* History with trends */}
      {results.length > 0 && (
        <Card>
          <SectionHeader label="Progress" title="History" />
          <div className="flex flex-col gap-0 mt-3">
            {sortedResults.map((r, index) => {
              const prevResult = index < sortedResults.length - 1 ? sortedResults[index + 1] : null;
              const isPR = r.id === bestResult?.id;

              return (
                <div
                  key={r.id}
                  className={`flex justify-between items-center text-[13px] py-3 border-b border-separator/30 last:border-0 ${isPR ? "bg-gold/5 -mx-4 px-4" : ""}`}
                >
                  <div className="flex items-center gap-2">
                    <span className="text-text-secondary">
                      {r.performedAt ? new Date(r.performedAt).toLocaleDateString() : ""}
                    </span>
                    {isPR && (
                      <span className="text-[9px] bg-gold/20 text-gold px-1.5 py-0.5 rounded font-mono uppercase tracking-wider">
                        PR
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    {index < sortedResults.length - 1 && (
                      <PRTrendIndicator
                        currentValue={r.scoreValue}
                        previousValue={prevResult?.scoreValue ?? null}
                        scoringType={benchmark.scoringType}
                        lowerIsBetter={lowerIsBetter}
                      />
                    )}
                    <span className="font-mono font-semibold">{formatScore(r.scoreValue, benchmark.scoringType)}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      )}
    </div>
  );
}
