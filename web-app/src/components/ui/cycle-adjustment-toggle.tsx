"use client";

import type { CyclePhase } from "@/lib/domain";
import { getPhaseExplanation } from "@/lib/domain";

interface CycleAdjustmentToggleProps {
  phase: CyclePhase;
  enabled: boolean;
  onToggle: () => void;
}

export function CycleAdjustmentToggle({ phase, enabled, onToggle }: CycleAdjustmentToggleProps) {
  const explanation = getPhaseExplanation(phase);

  return (
    <div className="space-y-3">
      <div className="bg-card-bg border border-separator rounded-xl p-3 flex items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[12px] font-medium text-navy">Cycle-aware adjustments</p>
          <p className="text-[10px] text-text-secondary mt-0.5">
            {enabled ? "Active — weights and volume adjusted" : "Disabled — using base values"}
          </p>
        </div>
        <button
          type="button"
          onClick={onToggle}
          className={`w-10 h-[22px] rounded-full transition-colors flex-shrink-0 relative ${
            enabled ? "bg-orange" : "bg-separator"
          }`}
        >
          <div
            className={`w-[18px] h-[18px] bg-white rounded-full absolute top-[2px] transition-all ${
              enabled ? "right-[2px]" : "left-[2px]"
            }`}
          />
        </button>
      </div>

      {enabled && (
        <div className="bg-navy/[0.03] border-l-[3px] border-l-navy rounded-r-lg p-3">
          <p className="text-[11px] text-navy font-semibold mb-1">Why the adjustment?</p>
          <p className="text-[11px] text-text-secondary leading-relaxed">{explanation}</p>
        </div>
      )}
    </div>
  );
}
