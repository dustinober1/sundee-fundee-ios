"use client";

import { useState } from "react";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

import type { ReadinessTier } from "@/lib/domain/benchmark-readiness";

// ---------------------------------------------------------------------------
// ReadinessBadge
// ---------------------------------------------------------------------------

interface ReadinessBadgeProps {
  tier: ReadinessTier;
  reason: string;
  emoji: string;
  color: string;
  compact?: boolean;
}

export function ReadinessBadge({ tier, reason, emoji, color, compact = false }: ReadinessBadgeProps) {
  const bgColor =
    tier === "peak" ? "bg-green-100" :
    tier === "recovery" ? "bg-warm-rose/15" :
    "bg-gold/15";

  if (compact) {
    return (
      <span
        className={`inline-flex items-center gap-1 text-[10px] px-2 py-0.5 rounded-full font-mono tracking-wider uppercase ${bgColor} ${color}`}
        title={reason}
      >
        <span>{emoji}</span>
        <span>{tier}</span>
      </span>
    );
  }

  return (
    <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full ${bgColor}`}>
      <span className="text-base">{emoji}</span>
      <span className={`text-[11px] font-mono font-semibold tracking-wider uppercase ${color}`}>
        {tier === "peak" ? "Peak Performance" : tier === "recovery" ? "Recovery Day" : "Moderate"}
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// IntensityGauge
// ---------------------------------------------------------------------------

interface IntensityGaugeProps {
  intensity: 1 | 2 | 3 | 4 | 5;
  showLabel?: boolean;
}

export function IntensityGauge({ intensity, showLabel = true }: IntensityGaugeProps) {
  const bars = Array.from({ length: 5 }, (_, i) => i + 1);

  return (
    <div className="flex items-center gap-1.5">
      <div className="flex gap-0.5">
        {bars.map((level) => {
          const isActive = level <= intensity;
          const height = 8 + level * 2; // Increasing height
          return (
            <div
              key={level}
              className={`w-1.5 rounded-sm transition-colors ${
                isActive ? "bg-orange" : "bg-separator/50"
              }`}
              style={{ height: `${height}px` }}
            />
          );
        })}
      </div>
      {showLabel && (
        <span className="text-[10px] text-text-secondary font-mono uppercase tracking-wider">
          Intensity
        </span>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// MovementTags
// ---------------------------------------------------------------------------

interface MovementTagsProps {
  tags: string[];
}

const TAG_COLORS: Record<string, string> = {
  "Heavy Pull": "bg-navy/10 text-navy",
  "Heavy Push": "bg-navy/10 text-navy",
  "High Cardio": "bg-orange/10 text-orange",
  "High Volume": "bg-gold/15 text-gold",
  "High Skill": "bg-warm-rose/15 text-warm-rose",
  "Sprint": "bg-orange/15 text-orange",
  "Endurance": "bg-green-100 text-green-700",
  "Gymnastics": "bg-purple-100 text-purple-700",
  "Core": "bg-blue-100 text-blue-700",
  "Posterior Chain": "bg-amber-100 text-amber-700",
  "Push/Pull": "bg-slate-100 text-slate-700",
  "default": "bg-separator/30 text-text-secondary",
};

export function MovementTags({ tags }: MovementTagsProps) {
  if (!tags || tags.length === 0) return null;

  return (
    <div className="flex flex-wrap gap-1">
      {tags.map((tag) => {
        const colorClass = TAG_COLORS[tag] ?? TAG_COLORS.default;
        return (
          <span
            key={tag}
            className={`text-[9px] px-1.5 py-0.5 rounded font-mono tracking-wider uppercase ${colorClass}`}
          >
            {tag}
          </span>
        );
      })}
    </div>
  );
}

// ---------------------------------------------------------------------------
// EquipmentIcons
// ---------------------------------------------------------------------------

interface EquipmentIconsProps {
  equipment: string[];
}

const EQUIPMENT_ICONS: Record<string, { icon: string; label: string }> = {
  barbell: { icon: "🏋️", label: "Barbell" },
  "pull-up bar": { icon: "💪", label: "Pull-up Bar" },
  "jump rope": { icon: "⏭️", label: "Jump Rope" },
  kettlebell: { icon: "⚖️", label: "Kettlebell" },
  dumbbells: { icon: "🏋️", label: "Dumbbells" },
  rower: { icon: "🚣", label: "Rower" },
  "wall ball": { icon: "🔴", label: "Wall Ball" },
  sandbag: { icon: "🎒", label: "Sandbag" },
  vest: { icon: "🦺", label: "Weight Vest" },
  plates: { icon: "⚫", label: "Plates" },
  "running space": { icon: "🏃", label: "Running" },
  wall: { icon: "🧱", label: "Wall" },
};

export function EquipmentIcons({ equipment }: EquipmentIconsProps) {
  if (!equipment || equipment.length === 0) return null;

  return (
    <div className="flex items-center gap-1">
      {equipment.slice(0, 5).map((item) => {
        const eq = EQUIPMENT_ICONS[item] ?? { icon: "🔧", label: item };
        return (
          <span
            key={item}
            className="text-sm"
            title={eq.label}
          >
            {eq.icon}
          </span>
        );
      })}
      {equipment.length > 5 && (
        <span className="text-[9px] text-text-secondary font-mono">
          +{equipment.length - 5}
        </span>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// TimeDomainBadge
// ---------------------------------------------------------------------------

interface TimeDomainBadgeProps {
  timeDomain: string;
}

export function TimeDomainBadge({ timeDomain }: TimeDomainBadgeProps) {
  return (
    <span className="text-[9px] bg-cream border border-separator/50 text-text-secondary px-1.5 py-0.5 rounded font-mono tracking-wider">
      ⏱️ {timeDomain}
    </span>
  );
}

// ---------------------------------------------------------------------------
// CoachNotesCard
// ---------------------------------------------------------------------------

interface CoachNotesCardProps {
  notes: string;
}

export function CoachNotesCard({ notes }: CoachNotesCardProps) {
  const [expanded, setExpanded] = useState(false);

  if (!notes) return null;

  return (
    <div className="bg-card-bg rounded-card border border-separator/50 overflow-hidden">
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full flex items-center justify-between px-4 py-3 text-left hover:bg-cream/50 transition-colors"
      >
        <span className="flex items-center gap-2">
          <span className="text-gold">💡</span>
          <span className="text-[12px] font-semibold text-navy font-heading">Coach Notes</span>
        </span>
        <span className={`text-text-secondary transition-transform ${expanded ? "rotate-180" : ""}`}>
          ▼
        </span>
      </button>
      {expanded && (
        <div className="px-4 pb-4">
          <p className="text-[13px] text-text-secondary leading-relaxed">
            {notes}
          </p>
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// ReadinessPanel (Full display for detail page)
// ---------------------------------------------------------------------------

interface ReadinessPanelProps {
  tier: ReadinessTier;
  reason: string;
  recommendation: string;
  emoji: string;
  color: string;
  phaseMultiplier: number;
}

export function ReadinessPanel({
  tier,
  reason,
  recommendation,
  emoji,
  color,
  phaseMultiplier,
}: ReadinessPanelProps) {
  const bgColor =
    tier === "peak" ? "bg-green-50 border-green-200" :
    tier === "recovery" ? "bg-warm-rose/10 border-warm-rose/30" :
    "bg-gold/10 border-gold/30";

  return (
    <div className={`rounded-card border p-4 ${bgColor}`}>
      <div className="flex items-start gap-3">
        <span className="text-2xl">{emoji}</span>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <span className={`text-[14px] font-heading font-semibold ${color}`}>
              {tier === "peak" ? "Peak Performance Day" : tier === "recovery" ? "Recovery Day" : "Moderate Day"}
            </span>
            {phaseMultiplier !== 1.0 && (
              <span className="text-[10px] font-mono bg-white/50 px-1.5 py-0.5 rounded">
                {phaseMultiplier > 1 ? "+" : ""}{Math.round((phaseMultiplier - 1) * 100)}% load
              </span>
            )}
          </div>
          <p className="text-[12px] text-text-secondary mb-2">{reason}</p>
          <p className="text-[12px] text-navy">{recommendation}</p>
        </div>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// PRTrendIndicator
// ---------------------------------------------------------------------------

interface PRTrendIndicatorProps {
  currentValue: number;
  previousValue: number | null;
  scoringType: string;
  lowerIsBetter?: boolean;
}

export function PRTrendIndicator({
  currentValue,
  previousValue,
  scoringType,
  lowerIsBetter = false,
}: PRTrendIndicatorProps) {
  if (previousValue == null) {
    return (
      <span className="text-[10px] text-gold font-mono uppercase tracking-wider">
        First Attempt
      </span>
    );
  }

  const diff = currentValue - previousValue;
  const percentChange = ((diff / previousValue) * 100).toFixed(1);

  // For time-based scores, lower is better
  const improved = lowerIsBetter ? diff < 0 : diff > 0;

  if (Math.abs(diff) < 0.01) {
    return (
      <span className="text-[10px] text-text-secondary font-mono">
        — Same as previous
      </span>
    );
  }

  return (
    <span className={`text-[10px] font-mono font-semibold ${improved ? "text-green-600" : "text-warm-rose"}`}>
      {improved ? "↑" : "↓"} {Math.abs(Number(percentChange))}%
    </span>
  );
}
