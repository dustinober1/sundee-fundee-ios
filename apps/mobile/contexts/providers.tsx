import React from 'react';
import { UserProvider } from './user-context';
import { ExerciseProvider } from './exercise-context';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ExerciseProvider>
      <UserProvider>
        {children}
      </UserProvider>
    </ExerciseProvider>
  );
}
