import { Card } from "@/components/ui/card";
import { PageHeader, SectionLabel } from "@/components/ui/art-deco";
import { groupedByCategory, formatWeightWithUnit, WeightUnit } from "@/lib/domain";
import { calculateBenchmarkReadiness } from "@/lib/domain/benchmark-readiness";
import { getBenchmarkResults } from "./actions";
import { getCycleStatus } from "../cycle/actions";
import { getUserProfile } from "../settings/actions";
import Link from "next/link";
import {
  ReadinessBadge,
  IntensityGauge,
  MovementTags,
  EquipmentIcons,
  TimeDomainBadge,
} from "@/components/ui/benchmark-ui";

export default async function BenchmarksPage() {
  const [results, cycleStatus, profile] = await Promise.all([
    getBenchmarkResults(),
    getCycleStatus(),
    getUserProfile(),
  ]);
  const groups = groupedByCategory();
  const weightUnit = (profile?.weightUnit as WeightUnit) ?? WeightUnit.pounds;

  // Map definitionId → best score
  const bestScores = new Map<string, number>();
  for (const r of results) {
    const current = bestScores.get(r.definitionId);
    if (current == null || r.scoreValue > current) {
      bestScores.set(r.definitionId, r.scoreValue);
    }
  }

  const currentPhase = cycleStatus?.currentPhase ?? null;

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
            const readiness = calculateBenchmarkReadiness(
              currentPhase,
              bm.intensity,
              bm.movementTags
            );

            return (
              <Link key={bm.id} href={`/benchmarks/${bm.id}`}>
                <Card className="hover:shadow-md hover:border-gold/20 border border-transparent transition-all">
                  <div className="flex flex-col gap-2">
                    {/* Top row: Name + Score */}
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <p className="font-heading font-semibold text-[14px]">{bm.name}</p>
                        <p className="text-text-secondary text-[12px] line-clamp-1 mt-0.5">
                          {bm.workoutDescription}
                        </p>
                      </div>
                      {best != null ? (
                        <span className="text-orange font-bold font-mono text-[15px] ml-2">
                          {formatScore(best, bm.scoringType, weightUnit)}
                        </span>
                      ) : (
                        <span className="text-gold/30 text-[12px] font-mono ml-2">—</span>
                      )}
                    </div>

                    {/* Bottom row: Readiness + Tags + Equipment */}
                    <div className="flex flex-wrap items-center gap-2">
                      <ReadinessBadge
                        tier={readiness.tier}
                        reason={readiness.reason}
                        emoji={readiness.emoji}
                        color={readiness.color}
                        compact
                      />

                      {bm.intensity && (
                        <IntensityGauge intensity={bm.intensity} showLabel={false} />
                      )}

                      {bm.movementTags && (
                        <MovementTags tags={bm.movementTags} />
                      )}

                      {bm.equipment && (
                        <EquipmentIcons equipment={bm.equipment} />
                      )}

                      {bm.timeDomain && (
                        <TimeDomainBadge timeDomain={bm.timeDomain} />
                      )}
                    </div>
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

function formatScore(value: number, type: string, weightUnit: WeightUnit = WeightUnit.pounds): string {
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
    case "weight": return formatWeightWithUnit(value, weightUnit);
    case "reps": return `${Math.floor(value)} reps`;
    case "roundsAndReps": {
      const rounds = Math.floor(value / 10000);
      const reps = Math.floor(value % 10000);
      return `${rounds}+${reps}`;
    }
    default: return String(value);
  }
}
