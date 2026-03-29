import { Card } from "@/components/ui/card";
import { getPeriodLogs, getCycleSettings } from "./actions";
import { calculateCycleStatus, getPhaseRecommendation } from "@/lib/domain";
import { LogPeriodForm } from "./log-period-form";

const PHASE_COLORS: Record<string, string> = {
  menstrual: "text-warm-rose",
  follicular: "text-gold",
  ovulation: "text-orange",
  luteal: "text-text-secondary",
};

const PHASE_EMOJI: Record<string, string> = {
  menstrual: "🩸",
  follicular: "🌱",
  ovulation: "☀️",
  luteal: "🌙",
};

export default async function CyclePage() {
  const [logs, settings] = await Promise.all([getPeriodLogs(), getCycleSettings()]);

  const cycleConfig = {
    averageCycleLengthDays: settings?.averageCycleLengthDays ?? 28,
    averagePeriodLengthDays: settings?.averagePeriodLengthDays ?? 5,
    lutealPhaseLengthDays: settings?.lutealPhaseLengthDays ?? 14,
  };

  const periodEntries = logs.map((l) => ({ startDate: new Date(l.startDate) }));
  const status = calculateCycleStatus(periodEntries, cycleConfig, new Date());

  return (
    <div className="flex flex-col gap-spacing-lg">
      <h1>Cycle Tracking</h1>

      {status ? (
        <>
          <Card className="text-center">
            <p className="text-4xl mb-spacing-xs">{PHASE_EMOJI[status.currentPhase] ?? "📊"}</p>
            <h2 className={`text-xl ${PHASE_COLORS[status.currentPhase] ?? ""}`}>
              {status.currentPhase.charAt(0).toUpperCase() + status.currentPhase.slice(1)} Phase
            </h2>
            <p className="text-text-secondary text-[13px]">
              Day {status.cycleDay} · {status.daysUntilNextPhase} days until next phase
            </p>
          </Card>

          {(() => {
            const rec = getPhaseRecommendation(status.currentPhase);
            return (
              <Card>
                <h2 className="mb-spacing-sm">Training Recommendation</h2>
                <p className="text-[13px] text-text-secondary mb-spacing-xs">{rec.description}</p>
                <p className="text-[13px]"><strong>Focus:</strong> {rec.trainingFocus}</p>
                <p className="text-[13px]"><strong>Intensity:</strong> {rec.intensityRecommendation}</p>
                {rec.exercisesToEmphasize.length > 0 && (
                  <p className="text-[13px] mt-spacing-xs"><strong>Emphasize:</strong> {rec.exercisesToEmphasize.join(", ")}</p>
                )}
              </Card>
            );
          })()}
        </>
      ) : (
        <Card>
          <p className="text-text-secondary text-[13px] text-center py-spacing-md">
            Log your first period to start tracking your cycle.
          </p>
        </Card>
      )}

      <LogPeriodForm />

      {logs.length > 0 && (
        <Card>
          <h2 className="mb-spacing-sm">Period History</h2>
          <div className="flex flex-col gap-spacing-xs">
            {logs.slice(0, 10).map((l) => (
              <div key={l.id} className="flex justify-between text-[13px] py-spacing-xs border-b border-separator/50 last:border-0">
                <span>{new Date(l.startDate).toLocaleDateString()}</span>
                <span className="text-text-secondary">{l.flowLevel}</span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}
