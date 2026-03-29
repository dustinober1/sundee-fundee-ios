import { getAuthUser } from "@/lib/firestore";
import { Card } from "@/components/ui/card";
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
    <div className="flex flex-col gap-8 pt-6">
      <div className="pl-2">
        <p className="text-gold font-mono text-[10px] tracking-[0.3em] uppercase mb-1">Welcome Back</p>
        <h1 className="text-3xl">Hey, {userName}</h1>
        <p className="text-text-secondary">{today}</p>
      </div>

      <div className="grid grid-cols-3 gap-spacing-sm">
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">0</p>
          <p className="text-[11px] text-text-secondary">This Week</p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">0</p>
          <p className="text-[11px] text-text-secondary">Day Streak</p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">None</p>
          <p className="text-[11px] text-text-secondary">Program</p>
        </Card>
      </div>

      <Card>
        <p className="text-gold font-mono text-[10px] tracking-[0.2em] uppercase mb-1">Get Moving</p>
        <h2 className="mb-4">Quick Actions</h2>
        <div className="grid grid-cols-2 gap-3">
          <Link href="/workouts" className="flex items-center justify-center gap-2 bg-orange text-cream rounded-button py-3 px-spacing-md text-[14px] font-medium hover:opacity-90 transition-opacity shadow-sm shadow-orange/20">Start Workout</Link>
          <Link href="/maxes" className="flex items-center justify-center gap-2 bg-navy text-cream rounded-button py-3 px-spacing-md text-[14px] font-medium hover:opacity-90 transition-opacity">Log Max</Link>
          <Link href="/programs" className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy/20 rounded-button py-3 px-spacing-md text-[14px] font-medium hover:border-navy/40 transition-colors">Programs</Link>
          <Link href="/benchmarks" className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy/20 rounded-button py-3 px-spacing-md text-[14px] font-medium hover:border-navy/40 transition-colors">Benchmarks</Link>
        </div>
      </Card>

      <Card>
        <p className="text-gold font-mono text-[10px] tracking-[0.2em] uppercase mb-1">History</p>
        <h2 className="mb-3">Recent Activity</h2>
        <p className="text-text-secondary text-[13px]">No workouts yet. Start your first workout to see activity here.</p>
      </Card>
    </div>
  );
}
