import { ActiveCyclesCard } from '@/components/dashboard/active-cycles-card';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';
import { CycleWidget } from '@/components/dashboard/cycle-widget';

export default function DashboardPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      </FadeIn>

      <StaggerList className="space-y-4">
        <StaggerItem>
          <ActiveCyclesCard />
        </StaggerItem>
        <StaggerItem>
          <CycleWidget />
        </StaggerItem>
        {/* Future widgets will be added here as StaggerItems */}
      </StaggerList>
    </div>
  );
}
