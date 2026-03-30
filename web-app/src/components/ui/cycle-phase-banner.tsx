"use client";

import { useState } from "react";
import type { CyclePhase } from "@/lib/domain";
import { SharkWeekLabel } from "@/components/ui/shark-week-label";

const PHASE_STYLES: Record<CyclePhase, { bg: string; border: string; text: string; icon: string }> = {
  menstrual: {
    bg: "from-warm-rose/10 to-warm-rose/5",
    border: "border-warm-rose/25",
    text: "text-warm-rose",
    icon: "🩸",
  },
  follicular: {
    bg: "from-gold/10 to-gold/5",
    border: "border-gold/25",
    text: "text-gold",
    icon: "🌱",
  },
  ovulation: {
    bg: "from-orange/10 to-orange/5",
    border: "border-orange/25",
    text: "text-orange",
    icon: "⚡",
  },
  luteal: {
    bg: "from-navy/8 to-navy/3",
    border: "border-navy/15",
    text: "text-navy",
    icon: "🌙",
  },
};

const PHASE_LABELS: Record<CyclePhase, string> = {
  menstrual: "Shark Week",
  follicular: "Follicular",
  ovulation: "Ovulation",
  luteal: "Luteal",
};

interface CyclePhaseBannerProps {
  phase: CyclePhase;
  cycleDay: number;
  adjustmentSummary: string;
}

export function CyclePhaseBanner({ phase, cycleDay, adjustmentSummary }: CyclePhaseBannerProps) {
  const [hidden, setHidden] = useState(false);
  const style = PHASE_STYLES[phase];

  if (hidden) return null;

  const phaseName = PHASE_LABELS[phase];

  return (
    <div className={`bg-gradient-to-r ${style.bg} border ${style.border} rounded-xl p-3 flex items-center gap-3`}>
      <div className="w-8 h-8 rounded-full bg-white/60 flex items-center justify-center flex-shrink-0">
        <span className="text-sm">{style.icon}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className={`text-[11px] font-semibold ${style.text}`}>
          {phase === "menstrual" ? (
            <SharkWeekLabel iconClassName="w-3.5 h-3.5" />
          ) : (
            phaseName
          )}{" "}
          · Day {cycleDay}
        </p>
        <p className="text-[10px] text-text-secondary mt-0.5 truncate">
          {adjustmentSummary}
        </p>
      </div>
      <button
        type="button"
        onClick={() => setHidden(true)}
        className="text-[9px] text-text-secondary underline flex-shrink-0"
      >
        Hide
      </button>
    </div>
  );
}
