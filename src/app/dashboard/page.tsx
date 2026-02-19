'use client';

import { ActiveCyclesCard } from '@/components/dashboard/active-cycles-card';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';
import { CycleWidget } from '@/components/dashboard/cycle-widget';
import { DashboardHeader } from '@/components/dashboard/dashboard-header';
import { OfflineBanner } from '@/components/dashboard/offline-banner';
import { SyncNudge } from '@/components/auth/sync-nudge';
import { useUser } from '@/contexts/user-context';

export default function DashboardPage() {
  const { isAuthenticated, uploadExistingData } = useUser();

  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <DashboardHeader />
        <OfflineBanner />
        <SyncNudge
          show={!isAuthenticated}
          isAuthenticated={isAuthenticated}
          uploadExistingData={uploadExistingData}
        />
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
