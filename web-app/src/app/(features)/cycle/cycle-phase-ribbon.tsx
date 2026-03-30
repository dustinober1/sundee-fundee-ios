import { Card } from "@/components/ui/card";
import type { CyclePhase } from "@/lib/domain";
import type { CycleSettings } from "@/lib/domain";
import { getPhaseBoundaries } from "@/lib/domain";
import { SharkIcon } from "@/components/ui/shark-week-label";

const PHASE_RIBBON_COLORS: Record<CyclePhase, string> = {
  menstrual: "bg-warm-rose",
  follicular: "bg-gold",
  ovulation: "bg-orange",
  luteal: "bg-navy",
};

const PHASE_LABELS: Record<CyclePhase, string> = {
  menstrual: "Shark Week",
  follicular: "Follicular",
  ovulation: "Ov",
  luteal: "Luteal",
};

interface CyclePhaseRibbonProps {
  cycleDay: number;
  settings: CycleSettings;
}

export function CyclePhaseRibbon({ cycleDay, settings }: CyclePhaseRibbonProps) {
  const boundaries = getPhaseBoundaries(settings);
  const phases: CyclePhase[] = ["menstrual", "follicular", "ovulation", "luteal"];
  const totalDays = settings.averageCycleLengthDays;

  return (
    <Card>
      <div className="flex gap-0.5 h-7 rounded-md overflow-hidden">
        {phases.map((phase) => {
          const b = boundaries[phase];
          const width = ((b.end - b.start + 1) / totalDays) * 100;
          return (
            <div
              key={phase}
              className={`${PHASE_RIBBON_COLORS[phase]} flex items-center justify-center relative`}
              style={{ width: `${width}%` }}
            >
              <span className="text-[9px] font-semibold text-white/90 uppercase tracking-wide inline-flex items-center gap-1">
                {phase === "menstrual" && <SharkIcon className="w-3 h-3" />}
                <span>{PHASE_LABELS[phase]}</span>
              </span>
            </div>
          );
        })}
      </div>
      <div className="flex justify-between mt-1.5 text-[10px] text-text-secondary">
        <span>Day 1</span>
        <span className="text-orange font-semibold">
          ▲ Day {cycleDay}
        </span>
        <span>Day {totalDays}</span>
      </div>
    </Card>
  );
}
