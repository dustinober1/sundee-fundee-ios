import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { DeleteRecordButton } from "@/components/ui/delete-record-button";
import { getPeriodLogs, getCycleSettings, deletePeriodLog } from "./actions";
import type { PeriodLogRecord } from "./actions";
import { calculateCycleStatus, getPhaseRecommendation } from "@/lib/domain";
import type { CycleSettings, PeriodLog } from "@/lib/domain";
import { LogPeriodForm } from "./log-period-form";
import { CyclePhaseRibbon } from "./cycle-phase-ribbon";
import { CycleCalendar } from "./cycle-calendar";
import { CycleSettingsPanel } from "./cycle-settings-panel";
import { SharkWeekLabel } from "@/components/ui/shark-week-label";

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

const SYMPTOM_LABELS: Record<string, string> = {
  cramps: "Cramps",
  headache: "Headache",
  fatigue: "Fatigue",
  bloating: "Bloating",
  mood_changes: "Mood",
  back_pain: "Back Pain",
};

export default async function CyclePage() {
  const [logs, settingsData] = await Promise.all([getPeriodLogs(), getCycleSettings()]);

  const cycleConfig: CycleSettings = {
    averageCycleLengthDays: (settingsData?.averageCycleLengthDays as number) ?? 28,
    averagePeriodLengthDays: (settingsData?.averagePeriodLengthDays as number) ?? 5,
    lutealPhaseLengthDays: (settingsData?.lutealPhaseLengthDays as number) ?? 14,
  };

  const periodEntries: PeriodLog[] = logs.map((l: PeriodLogRecord) => ({
    startDate: new Date(l.startDate),
    endDate: l.endDate ? new Date(l.endDate) : undefined,
  }));

  const status = calculateCycleStatus(periodEntries, cycleConfig, new Date());

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Wellness" title="Cycle Tracking" />

      {status ? (
        <>
          {/* Phase Ribbon */}
          <CyclePhaseRibbon cycleDay={status.cycleDay} settings={cycleConfig} />

          {/* Calendar */}
          <CycleCalendar periodLogs={periodEntries} settings={cycleConfig} />

          {/* Current Phase Card */}
          <Card className="text-center overflow-hidden relative">
            <div className={`absolute inset-0 bg-gradient-to-b ${PHASE_BG[status.currentPhase] ?? "from-navy/5"} to-transparent`} />
            <div className="relative">
              <h2 className={`text-xl font-heading font-bold ${PHASE_COLORS[status.currentPhase] ?? ""}`}>
                {status.currentPhase === "menstrual" ? (
                  <SharkWeekLabel iconClassName="w-5 h-5" />
                ) : (
                  `${status.currentPhase.charAt(0).toUpperCase() + status.currentPhase.slice(1)} Phase`
                )}
              </h2>
              <p className="text-text-secondary text-[13px] mt-1">
                Day {status.cycleDay} · {status.daysUntilNextPhase} days until next phase
              </p>
            </div>
          </Card>

          {/* Training Recommendation */}
          {(() => {
            const rec = getPhaseRecommendation(status.currentPhase);
            return (
              <Card>
                <SectionHeader label="Guidance" title="Training Recommendation" />
                <div className="mt-3 space-y-2">
                  <p className="text-[13px] text-text-secondary">{rec.description}</p>
                  <div className="border-t border-separator/30 pt-3 space-y-1.5">
                    <p className="text-[13px]">
                      <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Focus:</strong>{" "}
                      {rec.trainingFocus}
                    </p>
                    <p className="text-[13px]">
                      <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Intensity:</strong>{" "}
                      {rec.intensityRecommendation}
                    </p>
                    {rec.exercisesToEmphasize.length > 0 && (
                      <p className="text-[13px]">
                        <strong className="font-mono text-[11px] text-gold uppercase tracking-wider">Emphasize:</strong>{" "}
                        {rec.exercisesToEmphasize.join(", ")}
                      </p>
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

      {/* Log Period Form */}
      <LogPeriodForm />

      {/* Cycle Settings */}
      <CycleSettingsPanel
        initialCycleLength={cycleConfig.averageCycleLengthDays}
        initialPeriodLength={cycleConfig.averagePeriodLengthDays}
        initialLutealLength={cycleConfig.lutealPhaseLengthDays}
      />

      {/* Period History */}
      {logs.length > 0 && (
        <Card>
          <SectionHeader label="Records" title="Period History" />
          <div className="flex flex-col gap-0 mt-3">
            {logs.slice(0, 10).map((l: PeriodLogRecord) => {
              const start = new Date(l.startDate);
              const end = l.endDate ? new Date(l.endDate) : null;
              const flow = l.flowLevel ?? "medium";
              const symptoms = l.symptoms ?? [];
              const startStr = start.toLocaleDateString("en-US", { month: "short", day: "numeric" });
              const endStr = end
                ? end.toLocaleDateString("en-US", { month: "short", day: "numeric" })
                : null;

              return (
                <div
                  key={l.id}
                  className="flex justify-between items-start text-[13px] py-3 border-b border-separator/30 last:border-0"
                >
                  <div className="flex-1">
                    <p className="font-medium">
                      {startStr}
                      {endStr ? ` – ${endStr}` : ""}
                    </p>
                    <div className="flex items-center gap-1.5 mt-1">
                      <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-warm-rose/10 text-warm-rose font-mono">
                        {flow}
                      </span>
                      {symptoms.length > 0 && (
                        <span className="text-[10px] text-text-secondary">
                          {symptoms.map((s) => SYMPTOM_LABELS[s] ?? s).join(", ")}
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    {end && (
                      <span className="text-text-secondary font-mono text-[11px]">
                        {Math.round((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1} days
                      </span>
                    )}
                    <DeleteRecordButton action={deletePeriodLog} recordId={l.id} noun="Period Log" />
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
