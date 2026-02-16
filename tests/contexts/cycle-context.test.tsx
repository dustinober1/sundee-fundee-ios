import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook } from '@testing-library/react';
import { CycleProvider, useCycle } from '@/contexts/cycle-context';
import { UserProvider } from '@/contexts/user-context';
import { db } from '@/lib/db/dexie';
import React from 'react';

// Mock the database functions
vi.mock('@/lib/db', async () => {
  return {
    getPeriodLogs: vi.fn().mockResolvedValue([]),
    getSymptomLogs: vi.fn().mockResolvedValue([]),
    getBBTLogs: vi.fn().mockResolvedValue([]),
    getCycleSettings: vi.fn().mockResolvedValue(null),
    savePeriodLog: vi.fn().mockResolvedValue(undefined),
    saveSymptomLog: vi.fn().mockResolvedValue(undefined),
    saveBBTLog: vi.fn().mockResolvedValue(undefined),
    saveCycleSettings: vi.fn().mockResolvedValue(undefined),
    getDefaultSymptoms: vi.fn().mockResolvedValue([]),
    getSymptomDefinitions: vi.fn().mockResolvedValue([]),
    updatePeriodLog: vi.fn().mockResolvedValue(undefined),
    updateSymptomLog: vi.fn().mockResolvedValue(undefined),
    initializeDefaultSymptoms: vi.fn().mockResolvedValue(undefined),
    saveSymptomDefinition: vi.fn().mockResolvedValue(undefined),
    getUser: vi.fn().mockResolvedValue(null),
    getOneRepMaxesByUser: vi.fn().mockResolvedValue([]),
  };
});

vi.mock('@/lib/cycle-calculations', async () => {
  return {
    calculateCycleStatus: vi.fn().mockReturnValue(null),
    getPhaseRecommendation: vi.fn().mockReturnValue({
      phase: 'follicular',
      title: 'Follicular Phase',
      description: 'General training phase',
      trainingFocus: 'Building strength',
      intensityRecommendation: 'moderate',
      exercisesToEmphasize: ['squats', 'deadlifts'],
      exercisesToAvoid: []
    }),
    analyzeStrengthPatterns: vi.fn().mockReturnValue(null),
    predictStrengthWindow: vi.fn().mockReturnValue({
      startDate: new Date(),
      endDate: new Date(),
      confidence: 0.5
    })
  };
});

const wrapper = ({ children }: { children: React.ReactNode }) => (
  <UserProvider>
    <CycleProvider>{children}</CycleProvider>
  </UserProvider>
);

describe('Cycle Context', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it('initializes with empty state', () => {
    const { result } = renderHook(() => useCycle(), { wrapper });

    expect(result.current.periodLogs).toEqual([]);
    expect(result.current.symptomLogs).toEqual([]);
    expect(result.current.bbtLogs).toEqual([]);
  });

  it('provides period logging function', async () => {
    const { result } = renderHook(() => useCycle(), { wrapper });
    expect(typeof result.current.logPeriod).toBe('function');
  });

  it('provides symptom logging function', () => {
    const { result } = renderHook(() => useCycle(), { wrapper });
    expect(typeof result.current.logSymptom).toBe('function');
  });

  it('provides BBT logging function', () => {
    const { result } = renderHook(() => useCycle(), { wrapper });
    expect(typeof result.current.logBBT).toBe('function');
  });

  it('provides settings update function', () => {
    const { result } = renderHook(() => useCycle(), { wrapper });
    expect(typeof result.current.updateSettings).toBe('function');
  });

  it('provides utility functions', () => {
    const { result } = renderHook(() => useCycle(), { wrapper });
    expect(typeof result.current.getSymptomsForDate).toBe('function');
    expect(typeof result.current.getCycleDayForDate).toBe('function');
    expect(typeof result.current.refresh).toBe('function');
  });

  it('throws error when used outside provider', () => {
    expect(() => {
      renderHook(() => useCycle());
    }).toThrow('useCycle must be used within CycleProvider');
  });
});
