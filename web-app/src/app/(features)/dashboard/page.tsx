import { getAuthUser } from "@/lib/firestore";
import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, StatCard, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import Link from "next/link";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const user = await getAuthUser();
  if (!user) redirect("/sign-in");

  const userName = user.name ?? "Athlete";
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Welcome Back" title={`Hey, ${userName}`} subtitle={today} />

      <div className="grid grid-cols-3 gap-3">
        <StatCard value="0" label="This Week" />
        <StatCard value="0" label="Streak" />
        <StatCard value="None" label="Program" />
      </div>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      <Card>
        <SectionHeader label="Get Moving" title="Quick Actions" />
        <div className="grid grid-cols-2 gap-3 mt-4">
          <Link
            href="/workouts"
            className="flex items-center justify-center gap-2 bg-orange text-cream rounded-button py-3 px-4 text-[14px] font-semibold hover:opacity-90 transition-opacity shadow-md shadow-orange/20"
          >
            Start Workout
          </Link>
          <Link
            href="/maxes"
            className="flex items-center justify-center gap-2 bg-navy text-cream rounded-button py-3 px-4 text-[14px] font-semibold hover:opacity-90 transition-opacity"
          >
            Log Max
          </Link>
          <Link
            href="/programs"
            className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-gold/20 rounded-button py-3 px-4 text-[14px] font-medium hover:border-gold/40 transition-colors"
          >
            Programs
          </Link>
          <Link
            href="/benchmarks"
            className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-gold/20 rounded-button py-3 px-4 text-[14px] font-medium hover:border-gold/40 transition-colors"
          >
            Benchmarks
          </Link>
        </div>
      </Card>

      <Card>
        <SectionHeader label="History" title="Recent Activity" />
        <p className="text-text-secondary text-[13px] mt-3">
          No workouts yet. Start your first workout to see activity here.
        </p>
      </Card>
    </div>
  );
}
