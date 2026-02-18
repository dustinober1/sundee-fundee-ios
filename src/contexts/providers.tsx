'use client';

import { UserProvider } from './user-context';
import { ExerciseProvider } from './exercise-context';
import { CycleProvider } from './cycle-context';
import { TooltipProvider } from '@/components/ui/tooltip';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ExerciseProvider>
      <UserProvider>
        <CycleProvider>
          <TooltipProvider delayDuration={300}>
            {children}
          </TooltipProvider>
        </CycleProvider>
      </UserProvider>
    </ExerciseProvider>
  );
}
