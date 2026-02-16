import { ActiveCyclesCard } from '@/components/dashboard/active-cycles-card';

export default function DashboardPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>

      <div className="space-y-4">
        <ActiveCyclesCard />
      </div>
    </div>
  );
}
