'use client';

import { createContext, useContext, ReactNode } from 'react';
import { useRestTimer } from '@/hooks/useRestTimer';

type RestTimerContextValue = ReturnType<typeof useRestTimer>;

const RestTimerContext = createContext<RestTimerContextValue | null>(null);

interface RestTimerProviderProps {
  children: ReactNode;
}

export function RestTimerProvider({ children }: RestTimerProviderProps) {
  const timer = useRestTimer();

  return (
    <RestTimerContext.Provider value={timer}>
      {children}
    </RestTimerContext.Provider>
  );
}

export function useRestTimerContext(): RestTimerContextValue {
  const context = useContext(RestTimerContext);
  if (!context) {
    throw new Error('useRestTimerContext must be used within a RestTimerProvider');
  }
  return context;
}
