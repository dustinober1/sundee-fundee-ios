"use client";

import type { CycleStatusResult } from "@/app/(features)/dashboard/actions";

interface CyclePhaseBannerProps {
  status: CycleStatusResult;
}

export function CyclePhaseBanner({ status }: CyclePhaseBannerProps) {
  return (
    <div className="bg-gradient-to-br from-navy via-[#1a2a5e] to-navy rounded-card p-4 text-cream">
      <div className="flex justify-between items-center">
        <div>
          <p className="text-[10px] uppercase tracking-[0.2em] text-gold mb-0.5">Current Phase</p>
          <p className="text-lg font-semibold">{status.phaseTitle}</p>
        </div>
        <div className="text-right">
          <p className="text-sm font-medium text-orange">{status.trainingRecommendation}</p>
        </div>
      </div>
    </div>
  );
}
