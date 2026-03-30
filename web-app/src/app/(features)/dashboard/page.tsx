import { getAuthUser, userCollection } from "@/lib/firestore";
import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, StatCard, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import Link from "next/link";
import { redirect } from "next/navigation";
import { CyclePhaseBanner, SuggestedWorkoutCard, RecentWinsCard } from "@/components/dashboard";
import {
  getCycleStatus,
  getDashboardStats,
  getActiveProgram,
  getRecentWins,
} from "./actions";

export default async function DashboardPage() {
  const user = await getAuthUser();
  if (!user) redirect("/sign-in");

  const userName = user.name ?? "Athlete";
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  // Fetch all dashboard data in parallel
  const [cycleStatus, stats, activeProgram, recentWins] = await Promise.all([
    getCycleStatus(),
    getDashboardStats(),
    getActiveProgram(),
    getRecentWins(),
  ]);

  // Check AI access from subscription
  const subscription = await userCollection(user.uid, "subscription").doc("current").get();
  const subscriptionData = subscription.exists ? subscription.data() : null;
  const hasAIAccess = subscriptionData?.tier === "plus" || subscriptionData?.tier === "premium";

  return (
    <div className="flex flex-col gap-6 pt-4">
      <PageHeader label="Welcome Back" title={`Hey, ${userName}`} subtitle={today} />

      {/* Cycle Phase Banner - only if cycle tracking enabled */}
      {cycleStatus && <CyclePhaseBanner status={cycleStatus} />}

      {/* Stat Cards with real data */}
      <div className="grid grid-cols-3 gap-3">
        <StatCard value={stats.workoutsThisWeek} label="This Week" />
        <StatCard value={stats.prsThisMonth} label="PRs Month" />
        <StatCard value={stats.activeProgramName ?? "None"} label="Program" />
      </div>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {/* Suggested Workout - replaces Start Workout button */}
      <SuggestedWorkoutCard program={activeProgram} hasAIAccess={hasAIAccess} />

      {/* Quick Actions - simplified */}
      <Card>
        <SectionHeader label="Shortcuts" title="Quick Actions" />
        <div className="grid grid-cols-3 gap-3 mt-4">
          <Link
            href="/maxes"
            className="flex items-center justify-center bg-navy text-cream rounded-button py-3 px-4 text-[13px] font-semibold hover:opacity-90 transition-opacity"
          >
            Log Max
          </Link>
          <Link
            href="/programs"
            className="flex items-center justify-center bg-card-bg text-navy border border-gold/20 rounded-button py-3 px-4 text-[13px] font-medium hover:border-gold/40 transition-colors"
          >
            Programs
          </Link>
          <Link
            href="/benchmarks"
            className="flex items-center justify-center bg-card-bg text-navy border border-gold/20 rounded-button py-3 px-4 text-[13px] font-medium hover:border-gold/40 transition-colors"
          >
            Benchmarks
          </Link>
        </div>
      </Card>

      {/* Recent Wins */}
      <RecentWinsCard wins={recentWins} />
    </div>
  );
}
