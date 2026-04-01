import { Card } from "@/components/ui/card";
import { FeatureGate } from "@/components/ui/feature-gate";
import { PageHeader, SectionHeader, ArtDecoRuleSmall, SectionLabel } from "@/components/ui/art-deco";
import { getAuthUser } from "@/lib/firestore";
import { getUserProfile, getSubscription } from "./actions";
import { ProfileForm } from "./profile-form";
import { SubscriptionCard } from "./subscription-card";
import { SignOutButton } from "./sign-out-button";
import { redirect } from "next/navigation";
import Link from "next/link";

export default async function SettingsPage() {
  const [user, profile, subscription] = await Promise.all([
    getAuthUser(),
    getUserProfile(),
    getSubscription(),
  ]);

  if (!user) redirect("/sign-in");

  const tier = ((subscription as Record<string, unknown>)?.resolvedTier as "free" | "plus" | "premium") ?? "free";
  const profileData = profile as Record<string, unknown> | null;
  const subscriptionData = subscription as Record<string, unknown> | null;
  const userName = (profileData?.name as string) ?? user.name ?? "Athlete";
  const initials = userName
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Navigation" title="More" />

      {/* Profile Identity Card */}
      <Card className="overflow-hidden relative">
        <div className="absolute inset-0 bg-gradient-to-br from-navy/[0.03] via-transparent to-gold/[0.04]" />
        <div className="relative flex items-center gap-4">
          <div className="w-14 h-14 rounded-full bg-gradient-to-br from-navy to-navy/80 flex items-center justify-center flex-shrink-0 shadow-md shadow-navy/15 ring-2 ring-gold/20">
            <span className="text-cream font-heading text-lg font-bold tracking-wide">{initials}</span>
          </div>
          <div className="min-w-0">
            <h2 className="text-lg font-heading font-bold text-navy truncate">{userName}</h2>
            <p className="text-text-secondary text-[12px] font-mono truncate">{user.email}</p>
          </div>
        </div>
      </Card>

      {/* Profile Form */}
      <Card>
        <SectionHeader label="Personal" title="Profile" />
        <div className="mt-5">
          <ProfileForm
            initialName={userName}
            initialWeightUnit={(profileData?.weightUnit as string) ?? "lb"}
            initialExperience={(profileData?.experienceLevel as string) ?? "beginner"}
            initialGoal={(profileData?.primaryGoal as string) ?? "strength"}
          />
        </div>
      </Card>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {/* Navigation Links */}
      <Card>
        <SectionHeader label="Browse" title="Navigate" />
        <div className="mt-4 flex flex-col gap-0">
          <Link
            href="/cycle"
            className="group flex items-center justify-between py-3.5 border-b border-separator/30 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-warm-rose/10 flex items-center justify-center">
                <svg className="w-[18px] h-[18px] text-warm-rose" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <circle cx="12" cy="12" r="9" />
                  <path d="M12 3c3 5 3 13 0 18" />
                  <path d="M12 3c-3 5-3 13 0 18" />
                  <ellipse cx="12" cy="12" rx="9" ry="4" />
                </svg>
              </div>
              <div>
                <p className="text-[14px] font-medium text-navy">Cycle Tracking</p>
                <p className="text-[11px] text-text-secondary">Phase-aware training guidance</p>
              </div>
            </div>
            <svg className="w-4 h-4 text-text-secondary/50 group-hover:text-navy transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </Link>
          <Link
            href="/benchmarks"
            className="group flex items-center justify-between py-3.5 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-gold/10 flex items-center justify-center">
                <svg className="w-[18px] h-[18px] text-gold" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16 8v8m-4-5v5m-4-2v2m-2 4h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <div>
                <p className="text-[14px] font-medium text-navy">Benchmarks</p>
                <p className="text-[11px] text-text-secondary">Track your fitness milestones</p>
              </div>
            </div>
            <svg className="w-4 h-4 text-text-secondary/50 group-hover:text-navy transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      </Card>

      <div id="plans">
        <SubscriptionCard
          tier={tier}
          status={(subscriptionData?.status as string | undefined) ?? null}
          currentPeriodEnd={(subscriptionData?.currentPeriodEnd as string | undefined) ?? null}
          cancelAtPeriodEnd={subscriptionData?.cancelAtPeriodEnd === true}
          generatedToday={Number(subscriptionData?.generatedToday ?? 0)}
          remainingCloudGenerations={Number(subscriptionData?.remainingCloudGenerations ?? 0)}
          dailyCloudLimit={Number(subscriptionData?.dailyCloudLimit ?? 0)}
          hasActivePaidAccess={subscriptionData?.hasActivePaidAccess === true}
        />
      </div>

      <div className="grid gap-4">
        <FeatureGate
          title="Custom Program Builder"
          description="Create your own training blocks with editable structure and programming tools."
          minimumTier="plus"
          unlocked={tier === "plus" || tier === "premium"}
        />
        <FeatureGate
          title="AI Mesocycle Plans"
          description="Unlock multi-week planning, adaptive coaching memory, and richer AI recommendations."
          minimumTier="premium"
          unlocked={tier === "premium"}
        />
      </div>

      {/* Account & Security */}
      <Card>
        <SectionHeader label="Security" title="Account" />
        <div className="mt-4 flex flex-col gap-4">
          <div className="flex items-center gap-3 py-2">
            <div className="w-9 h-9 rounded-lg bg-navy/5 flex items-center justify-center flex-shrink-0">
              <svg className="w-[18px] h-[18px] text-navy/50" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <div className="min-w-0">
              <SectionLabel>Email</SectionLabel>
              <p className="text-[13px] text-navy truncate">{user.email}</p>
            </div>
          </div>
          <div className="border-t border-separator/30 pt-4">
            <SignOutButton />
          </div>
        </div>
      </Card>
    </div>
  );
}
