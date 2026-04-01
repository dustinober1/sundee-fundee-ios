"use client";

import Link from "next/link";
import type { ActiveProgram } from "@/app/(features)/dashboard/actions";

interface SuggestedWorkoutCardProps {
  program: ActiveProgram | null;
  aiEntitlement: {
    canUseCloudAI: boolean;
    tier: "free" | "plus" | "premium";
    remainingCloudGenerations: number;
    dailyCloudLimit: number;
  };
}

export function SuggestedWorkoutCard({ program, aiEntitlement }: SuggestedWorkoutCardProps) {
  if (program) {
    return (
      <div className="card p-4">
        <p className="text-[10px] uppercase tracking-[0.2em] text-gold mb-1">Today&apos;s Focus</p>
        <h3 className="text-base font-semibold text-navy mb-2">
          Week {program.currentWeek} — {program.sessionName}
        </h3>
        <div className="flex gap-2 mb-3">
          <span className="text-[11px] bg-card-bg px-2 py-0.5 rounded text-text-secondary">
            {program.duration}
          </span>
          <span className="text-[11px] bg-card-bg px-2 py-0.5 rounded text-text-secondary">
            {program.focus}
          </span>
        </div>
        <div className="h-1.5 bg-separator/30 rounded-full mb-3 overflow-hidden">
          <div
            className="h-full bg-orange rounded-full transition-all duration-300"
            style={{ width: `${program.progressPercent}%` }}
          />
        </div>
        <Link
          href="/workouts"
          className="block w-full bg-orange text-cream text-center py-3 rounded-button font-semibold hover:opacity-90 transition-opacity shadow-md shadow-orange/20"
        >
          Start Session
        </Link>
      </div>
    );
  }

  // No active program
  return (
    <div className="card p-4">
      <p className="text-[10px] uppercase tracking-[0.2em] text-gold mb-1">Today&apos;s Focus</p>
      <h3 className="text-base font-semibold text-navy mb-1">
        {aiEntitlement.canUseCloudAI ? "Generate AI Workout" : "Find a Program"}
      </h3>
      <p className="text-sm text-text-secondary mb-3">
        {aiEntitlement.canUseCloudAI
          ? `AI-powered workout based on your cycle, goals, and equipment. ${aiEntitlement.remainingCloudGenerations}/${aiEntitlement.dailyCloudLimit} remaining today.`
          : aiEntitlement.tier === "free"
            ? "Browse programs tailored to your goals or upgrade for cloud AI workouts."
            : "Your cloud AI limit is reached for today. Browse programs or try again tomorrow."}
      </p>
      <Link
        href={aiEntitlement.canUseCloudAI ? "/workouts/ai" : aiEntitlement.tier === "free" ? "/settings#plans" : "/programs"}
        className="block w-full bg-orange text-cream text-center py-3 rounded-button font-semibold hover:opacity-90 transition-opacity shadow-md shadow-orange/20"
      >
        {aiEntitlement.canUseCloudAI ? "Generate Workout" : aiEntitlement.tier === "free" ? "Upgrade to Plus" : "Browse Programs"}
      </Link>
    </div>
  );
}
