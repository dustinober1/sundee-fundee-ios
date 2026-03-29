import { Card } from "@/components/ui/card";
import { tierDisplayName } from "@/lib/domain";

const TIER_DESCRIPTIONS: Record<string, string> = {
  free: "Unlimited on-device AI workouts",
  plus: "Cloud-powered AI workouts and programming tools",
  premium: "Personal AI coach that learns and adapts",
};

export function SubscriptionCard({ tier }: { tier: "free" | "plus" | "premium" }) {
  const name = tierDisplayName(tier);
  const description = TIER_DESCRIPTIONS[tier] ?? "";

  return (
    <Card>
      <h2 className="mb-spacing-sm">Subscription</h2>
      <div className="flex items-center justify-between">
        <div>
          <p className="font-medium text-[14px]">{name}</p>
          <p className="text-text-secondary text-[12px]">{description}</p>
        </div>
        {tier === "free" && (
          <span className="text-[12px] bg-orange/10 text-orange px-2 py-0.5 rounded-sm font-medium">
            Upgrade
          </span>
        )}
        {tier !== "free" && (
          <span className="text-[12px] bg-navy/5 text-navy px-2 py-0.5 rounded-sm font-medium">
            Active
          </span>
        )}
      </div>
    </Card>
  );
}
