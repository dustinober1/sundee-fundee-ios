"use client";

import { useState } from "react";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { SectionHeader } from "@/components/ui/art-deco";

type BillingInterval = "monthly" | "annual";
type Tier = "plus" | "premium";

interface PlansSectionProps {
  currentTier: "free" | "plus" | "premium";
  hasActivePaidAccess: boolean;
}

const PLAN_DETAILS: Record<Tier, {
  title: string;
  monthly: string;
  annual: string;
  annualNote: string;
  highlights: string[];
}> = {
  plus: {
    title: "Sundee Plus",
    monthly: "$4.99/mo",
    annual: "$39.99/yr",
    annualNote: "Save about 33%",
    highlights: [
      "AI-enabled cloud workouts",
      "Custom program builder and templates",
      "Full history, trends, and custom benchmarks",
    ],
  },
  premium: {
    title: "Sundee Premium",
    monthly: "$9.99/mo",
    annual: "$79.99/yr",
    annualNote: "Save about 33%",
    highlights: [
      "Higher daily cloud AI limits",
      "AI mesocycle planning and coaching memory",
      "Premium reports, substitutions, and recovery tools",
    ],
  },
};

export function PlansSection({ currentTier, hasActivePaidAccess }: PlansSectionProps) {
  const [interval, setInterval] = useState<BillingInterval>("monthly");
  const [loadingTier, setLoadingTier] = useState<Tier | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function startCheckout(tier: Tier) {
    setLoadingTier(tier);
    setError(null);

    try {
      const res = await fetch("/api/stripe/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tier, interval }),
      });

      let data: { url?: string; error?: string } = {};
      const raw = await res.text();
      if (raw.trim()) {
        try {
          data = JSON.parse(raw) as { url?: string; error?: string };
        } catch {
          data = { error: raw };
        }
      }

      if (!res.ok || !data.url) {
        throw new Error(data.error ?? "Unable to start checkout.");
      }

      window.location.href = data.url;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to start checkout.");
      setLoadingTier(null);
    }
  }

  return (
    <div id="plans" className="grid gap-4 scroll-mt-24">
      <Card>
        <SectionHeader label="Upgrade" title="Plans" />
        <div className="mt-4 flex items-center gap-2 rounded-button bg-card-bg border border-separator/50 p-1 w-fit">
          <button
            type="button"
            onClick={() => setInterval("monthly")}
            className={`px-4 py-2 rounded-button text-[13px] font-medium transition-colors ${
              interval === "monthly" ? "bg-orange text-cream" : "text-navy"
            }`}
          >
            Monthly
          </button>
          <button
            type="button"
            onClick={() => setInterval("annual")}
            className={`px-4 py-2 rounded-button text-[13px] font-medium transition-colors ${
              interval === "annual" ? "bg-orange text-cream" : "text-navy"
            }`}
          >
            Annual
          </button>
        </div>
        {error && <p className="mt-3 text-[12px] text-error">{error}</p>}
      </Card>

      <div className="grid gap-4 md:grid-cols-2">
        {(Object.entries(PLAN_DETAILS) as Array<[Tier, (typeof PLAN_DETAILS)[Tier]]>).map(([tier, plan]) => {
          const isCurrent = hasActivePaidAccess && currentTier === tier;
          const isHigherTierLocked = hasActivePaidAccess && currentTier === "premium" && tier === "plus";

          return (
            <Card key={tier} className={`relative overflow-hidden ${tier === "premium" ? "border-gold/30" : ""}`}>
              {tier === "premium" && (
                <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-gold/50 to-transparent" />
              )}
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-[10px] uppercase tracking-[0.2em] text-gold mb-1">
                    {tier === "plus" ? "Most Popular" : "Best Value"}
                  </p>
                  <h3 className="text-lg font-heading font-bold text-navy">{plan.title}</h3>
                  <p className="mt-2 text-2xl font-bold text-orange">
                    {interval === "monthly" ? plan.monthly : plan.annual}
                  </p>
                  <p className="text-[12px] text-text-secondary mt-1">{plan.annualNote}</p>
                </div>
                {isCurrent && (
                  <span className="text-[10px] font-mono uppercase tracking-[0.18em] px-2 py-1 rounded-sm bg-green-100 text-green-800">
                    Current
                  </span>
                )}
              </div>

              <ul className="mt-4 space-y-2 text-[12px] text-text-secondary">
                {plan.highlights.map((highlight) => (
                  <li key={highlight}>{highlight}</li>
                ))}
              </ul>

              <div className="mt-5">
                <Button
                  fullWidth
                  onClick={() => startCheckout(tier)}
                  disabled={isCurrent || isHigherTierLocked || loadingTier !== null}
                  variant={tier === "premium" ? "primary" : "secondary"}
                >
                  {isCurrent
                    ? "Current plan"
                    : loadingTier === tier
                      ? "Redirecting..."
                      : tier === "premium" && currentTier === "plus" && hasActivePaidAccess
                        ? "Upgrade to Premium"
                        : "Choose plan"}
                </Button>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
