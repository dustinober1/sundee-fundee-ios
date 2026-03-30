"use client";

import { SectionHeader } from "@/components/ui/art-deco";
import type { Win } from "@/app/(features)/dashboard/actions";

interface RecentWinsCardProps {
  wins: Win[];
}

const winIcons: Record<Win["type"], string> = {
  pr: "🏆",
  benchmark: "⏱️",
  "first-workout": "✨",
  "program-complete": "🎉",
};

function formatTimeAgo(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Yesterday";
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} week${Math.floor(diffDays / 7) > 1 ? "s" : ""} ago`;
  return `${Math.floor(diffDays / 30)} month${Math.floor(diffDays / 30) > 1 ? "s" : ""} ago`;
}

export function RecentWinsCard({ wins }: RecentWinsCardProps) {
  if (wins.length === 0) {
    return (
      <div className="card p-4">
        <SectionHeader label="Achievements" title="Recent Wins" />
        <p className="text-text-secondary text-[13px] mt-3">
          Your achievements will appear here as you train. Complete a workout to get started!
        </p>
      </div>
    );
  }

  return (
    <div className="card p-4">
      <SectionHeader label="Achievements" title="Recent Wins" />
      <div className="mt-3 space-y-0">
        {wins.map((win) => (
          <div
            key={win.id}
            className="flex items-center gap-3 py-2 border-b border-separator/20 last:border-0"
          >
            <span className="text-xl">{winIcons[win.type]}</span>
            <div className="flex-1 min-w-0">
              <p className="text-[13px] font-semibold text-navy truncate">{win.title}</p>
              <p className="text-[11px] text-text-secondary">
                {win.subtitle} · {formatTimeAgo(win.date)}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
