import Link from "next/link";
import { Card } from "./card";

interface FeatureGateProps {
  title: string;
  description: string;
  minimumTier: "plus" | "premium";
  unlocked: boolean;
}

export function FeatureGate({ title, description, minimumTier, unlocked }: FeatureGateProps) {
  return (
    <Card className={unlocked ? "" : "border-dashed"}>
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[14px] font-medium text-navy">{title}</p>
          <p className="text-[12px] text-text-secondary mt-1">{description}</p>
        </div>
        <span
          className={`text-[10px] font-mono uppercase tracking-[0.18em] px-2 py-1 rounded-sm ${
            unlocked ? "bg-green-100 text-green-800" : "bg-gold/15 text-navy"
          }`}
        >
          {unlocked ? "Unlocked" : minimumTier}
        </span>
      </div>
      {!unlocked && (
        <div className="mt-3 pt-3 border-t border-separator/30 flex items-center justify-between gap-3">
          <p className="text-[11px] text-text-secondary">
            Upgrade to {minimumTier === "plus" ? "Sundee Plus" : "Sundee Premium"} to unlock this.
          </p>
          <Link
            href="/settings#plans"
            className="text-[12px] text-orange font-medium hover:text-orange/80 transition-colors whitespace-nowrap"
          >
            See plans →
          </Link>
        </div>
      )}
    </Card>
  );
}
