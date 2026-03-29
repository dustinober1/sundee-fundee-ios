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
    <div className="flex flex-col gap-spacing-lg">
      <div>
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
        <h2 className="mb-spacing-sm">Quick Actions</h2>
        <div className="grid grid-cols-2 gap-spacing-sm">
          <Link href="/workouts" className="flex items-center justify-center gap-2 bg-orange text-cream rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:opacity-90">Start Workout</Link>
          <Link href="/maxes" className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30">Log Max</Link>
          <Link href="/programs" className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30">Programs</Link>
          <Link href="/benchmarks" className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30">Benchmarks</Link>
        </div>
      </Card>

      <Card>
        <h2 className="mb-spacing-sm">Recent Activity</h2>
        <p className="text-text-secondary text-[13px]">No workouts yet. Start your first workout to see activity here.</p>
      </Card>
    </div>
  );
}
