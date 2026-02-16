'use client';

import { UserProvider } from './user-context';
import { ExerciseProvider } from './exercise-context';
import { CycleProvider } from './cycle-context';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ExerciseProvider>
      <UserProvider>
        <CycleProvider>
          {children}
        </CycleProvider>
      </UserProvider>
    </ExerciseProvider>
  );
}
