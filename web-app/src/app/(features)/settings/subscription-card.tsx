import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import { tierDisplayName } from "@/lib/domain";
import Link from "next/link";

const TIER_DESCRIPTIONS: Record<string, string> = {
  free: "Unlimited on-device AI workouts",
  plus: "Cloud-powered AI workouts and programming tools",
  premium: "Personal AI coach that learns and adapts",
};

const TIER_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  free: { bg: "bg-orange/10", text: "text-orange", label: "Free" },
  plus: { bg: "bg-gold/15", text: "text-navy", label: "Active" },
  premium: { bg: "bg-navy/10", text: "text-navy", label: "Active" },
};

export function SubscriptionCard({ tier }: { tier: "free" | "plus" | "premium" }) {
  const name = tierDisplayName(tier);
  const description = TIER_DESCRIPTIONS[tier] ?? "";
  const badge = TIER_BADGE[tier] ?? TIER_BADGE.free;

  return (
    <Card className="overflow-hidden relative">
      {tier !== "free" && (
        <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-gold/40 to-transparent" />
      )}
      <div className="relative">
        <SectionHeader label="Plan" title="Subscription" />
        <div className="mt-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`w-9 h-9 rounded-lg ${tier === "free" ? "bg-orange/10" : "bg-gold/10"} flex items-center justify-center`}>
              <svg className={`w-[18px] h-[18px] ${tier === "free" ? "text-orange" : "text-gold"}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                {tier === "free" ? (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                )}
              </svg>
            </div>
            <div>
              <p className="text-[14px] font-medium text-navy">{name}</p>
              <p className="text-text-secondary text-[11px]">{description}</p>
            </div>
          </div>
          <span className={`text-[11px] ${badge.bg} ${badge.text} px-2.5 py-1 rounded-sm font-medium font-mono tracking-wider uppercase`}>
            {badge.label}
          </span>
        </div>
        {tier === "free" && (
          <div className="mt-4 pt-3 border-t border-separator/30">
            <Link
              href="/settings"
              className="text-[12px] text-orange font-medium hover:text-orange/80 transition-colors"
            >
              View upgrade options &rarr;
            </Link>
          </div>
        )}
      </div>
    </Card>
  );
}
