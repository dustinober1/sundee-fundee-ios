import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import { tierDisplayName, tierHeadline, tierHighlights, tierValueProposition } from "@/lib/domain";
import Link from "next/link";

const TIER_BADGE: Record<string, { bg: string; text: string; label: string }> = {
  free: { bg: "bg-orange/10", text: "text-orange", label: "Free" },
  plus: { bg: "bg-gold/15", text: "text-navy", label: "Paid" },
  premium: { bg: "bg-navy/10", text: "text-navy", label: "Paid" },
};

interface SubscriptionCardProps {
  tier: "free" | "plus" | "premium";
  status?: string | null;
  currentPeriodEnd?: string | null;
  cancelAtPeriodEnd?: boolean;
  generatedToday?: number;
  remainingCloudGenerations?: number;
  dailyCloudLimit?: number;
  hasActivePaidAccess?: boolean;
}

function formatStatus(status?: string | null, cancelAtPeriodEnd?: boolean) {
  if (cancelAtPeriodEnd && status === "active") return "Cancels at period end";
  if (!status) return "Free plan";
  return status.replaceAll("_", " ");
}

export function SubscriptionCard({
  tier,
  status,
  currentPeriodEnd,
  cancelAtPeriodEnd,
  generatedToday = 0,
  remainingCloudGenerations = 0,
  dailyCloudLimit = 0,
  hasActivePaidAccess = false,
}: SubscriptionCardProps) {
  const name = tierDisplayName(tier);
  const description = tierValueProposition(tier);
  const badge = TIER_BADGE[tier] ?? TIER_BADGE.free;
  const periodLabel = currentPeriodEnd
    ? `${cancelAtPeriodEnd ? "Access ends" : "Renews"} ${new Date(currentPeriodEnd).toLocaleDateString()}`
    : null;
  const highlights = tierHighlights(tier);

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
              <p className="text-text-secondary text-[11px]">{tierHeadline(tier)} · {description}</p>
            </div>
          </div>
          <span className={`text-[11px] ${badge.bg} ${badge.text} px-2.5 py-1 rounded-sm font-medium font-mono tracking-wider uppercase`}>
            {badge.label}
          </span>
        </div>
        <div className="mt-4 pt-3 border-t border-separator/30 space-y-3">
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-text-secondary">
            <span className="capitalize">Status: {formatStatus(status, cancelAtPeriodEnd)}</span>
            {periodLabel && <span>{periodLabel}</span>}
            {dailyCloudLimit > 0 && (
              <span>
                Cloud AI: {generatedToday}/{dailyCloudLimit} used · {remainingCloudGenerations} left today
              </span>
            )}
          </div>

          <ul className="space-y-1 text-[12px] text-text-secondary">
            {highlights.map((highlight) => (
              <li key={highlight}>{highlight}</li>
            ))}
          </ul>

          <div className="flex items-center justify-between gap-4">
            <p className="text-[12px] text-text-secondary">
              {hasActivePaidAccess
                ? "Billing is connected and your entitlement is active."
                : tier === "free"
                  ? "Upgrade to unlock Gemini cloud workouts and advanced tools."
                  : "Your paid access is not currently active."}
            </p>
            <Link
              href={hasActivePaidAccess ? "/api/stripe/portal" : "/settings#plans"}
              className="text-[12px] text-orange font-medium hover:text-orange/80 transition-colors whitespace-nowrap"
            >
              {hasActivePaidAccess ? "Manage billing" : "View upgrade options →"}
            </Link>
          </div>
        </div>
      </div>
    </Card>
  );
}
