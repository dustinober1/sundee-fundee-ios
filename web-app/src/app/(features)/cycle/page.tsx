import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { DeleteRecordButton } from "@/components/ui/delete-record-button";
import { deletePeriodLog, getPeriodLogs, getCycleSettings } from "./actions";
import { calculateCycleStatus, getPhaseRecommendation } from "@/lib/domain";
import { coerceStoredDateToLocalDate } from "@/lib/date-input";
import { LogPeriodForm } from "./log-period-form";

const PHASE_COLORS: Record<string, string> = {
  menstrual: "text-warm-rose",
  follicular: "text-gold",
  ovulation: "text-orange",
  luteal: "text-text-secondary",
};

const PHASE_BG: Record<string, string> = {
  menstrual: "from-warm-rose/10",
  follicular: "from-gold/10",
  ovulation: "from-orange/10",
  luteal: "from-navy/5",
};

export default async function CyclePage() {
  const [logs, settings] = await Promise.all([getPeriodLogs(), getCycleSettings()]);

  const cycleConfig = {
    averageCycleLengthDays: settings?.averageCycleLengthDays ?? 28,
    averagePeriodLengthDays: settings?.averagePeriodLengthDays ?? 5,
    lutealPhaseLengthDays: settings?.lutealPhaseLengthDays ?? 14,
  };

  const periodEntries = logs.flatMap((l) => {
    const startDate = coerceStoredDateToLocalDate(l.startDate);
    if (!startDate) return [];

    const endDate = coerceStoredDateToLocalDate(l.endDate);

    return [{
      startDate,
      ...(endDate ? { endDate } : {}),
    }];
  });
  const status = calculateCycleStatus(periodEntries, cycleConfig, new Date());

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Wellness" title="Cycle Tracking" />

      {status ? (
        <>
          <Card className={`text-center overflow-hidden relative`}>
            <div className={`absolute inset-0 bg-gradient-to-b ${PHASE_BG[status.currentPhase] ?? "from-navy/5"} to-transparent`} />
            <div className="relative">
              <h2 className={`text-xl font-heading font-bold ${PHASE_COLORS[status.currentPhase] ?? ""}`}>
                {status.currentPhase.charAt(0).toUpperCase() + status.currentPhase.slice(1)} Phase
              </h2>
              <p className="text-text-secondary text-[13px] mt-1">
                Day {status.cycleDay} · {status.daysUntilNextPhase} days until next phase
              </p>
            </div>
          </Card>

          {(() => {
            const rec = getPhaseRecommendation(status.currentPhase);
            return (
              <Card>
                <SectionHeader label="Guidance" title="Training Recommendation" />
                <div className="mt-3 space-y-2">
                  <p className="text-[13px] text-text-secondary">{rec.description}</p>
                  <div className="border-t border-separator/30 pt-3 space-y-1.5">
                    <p className="text-[13px]"><strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Focus:</strong> {rec.trainingFocus}</p>
                    <p className="text-[13px]"><strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Intensity:</strong> {rec.intensityRecommendation}</p>
                    {rec.exercisesToEmphasize.length > 0 && (
                      <p className="text-[13px]"><strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Emphasize:</strong> {rec.exercisesToEmphasize.join(", ")}</p>
                    )}
                  </div>
                </div>
              </Card>
            );
          })()}
        </>
      ) : (
        <Card>
          <div className="text-center py-8">
            <div className="text-gold/30 mb-4">
              <svg className="w-12 h-12 mx-auto" fill="none" viewBox="0 0 48 48" stroke="currentColor" strokeWidth={1}>
                <circle cx="24" cy="24" r="20" />
                <path d="M24 4 C30 16, 30 32, 24 44" />
                <path d="M24 4 C18 16, 18 32, 24 44" />
                <ellipse cx="24" cy="24" rx="20" ry="8" />
              </svg>
            </div>
            <p className="text-text-secondary text-[13px]">
              Log your first period to start tracking your cycle.
            </p>
          </div>
        </Card>
      )}

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      <LogPeriodForm />

      {logs.length > 0 && (
        <Card>
          <SectionHeader label="Records" title="Period History" />
          <div className="flex flex-col gap-0 mt-3">
            {logs.slice(0, 10).map((l) => (
              (() => {
                const startDate = coerceStoredDateToLocalDate(l.startDate);

                if (!startDate) return null;

                return (
                  <div key={l.id} className="flex items-start justify-between gap-3 py-3 border-b border-separator/30 last:border-0">
                    <div className="text-[13px]">
                      <p>{startDate.toLocaleDateString()}</p>
                      <p className="text-text-secondary font-mono mt-0.5">{l.flowLevel}</p>
                    </div>
                    <DeleteRecordButton action={deletePeriodLog} recordId={l.id} noun="Period Log" />
                  </div>
                );
              })()
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
