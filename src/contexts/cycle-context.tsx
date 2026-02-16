'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import type {
  PeriodLog,
  SymptomLog,
  BBTLog,
  SymptomDefinition,
  CycleSettings,
  CycleStatus,
  PhaseRecommendation,
  PhaseStrengthProfile,
} from '@/types';
import {
  getPeriodLogs,
  getSymptomLogs,
  getBBTLogs,
  getCycleSettings,
  savePeriodLog,
  saveSymptomLog,
  saveBBTLog,
  saveCycleSettings,
  getSymptomDefinitions,
  updatePeriodLog as dbUpdatePeriodLog,
  updateSymptomLog as dbUpdateSymptomLog,
  saveSymptomDefinition,
} from '@/lib/db';
import { calculateCycleStatus, getPhaseRecommendation } from '@/lib/cycle-calculations';
import { generateId } from '@/lib/utils';
import { useUser } from '@/contexts/user-context';

interface CycleContextValue {
  periodLogs: PeriodLog[];
  symptomLogs: SymptomLog[];
  bbtLogs: BBTLog[];
  settings: CycleSettings | null;
  availableSymptoms: SymptomDefinition[];
  cycleStatus: CycleStatus | null;
  currentRecommendation: PhaseRecommendation | null;
  strengthProfile: PhaseStrengthProfile | null;

  logPeriod: (startDate: Date, flowLevel?: 'light' | 'medium' | 'heavy', notes?: string) => Promise<void>;
  endPeriod: (endDate: Date) => Promise<void>;
  updatePeriodLog: (id: string, updates: Partial<PeriodLog>) => Promise<void>;
  logSymptom: (date: Date, symptomId: string, severity: number, notes?: string) => Promise<void>;
  updateSymptomLog: (id: string, updates: Partial<SymptomLog>) => Promise<void>;
  logBBT: (date: Date, temperature: number, time: string, notes?: string) => Promise<void>;
  updateSettings: (updates: Partial<CycleSettings>) => Promise<void>;
  enableSymptom: (symptomId: string) => Promise<void>;
  disableSymptom: (symptomId: string) => Promise<void>;
  addCustomSymptom: (name: string, category: 'physical' | 'emotional' | 'energy') => Promise<void>;
  getSymptomsForDate: (date: Date) => SymptomLog[];
  getCycleDayForDate: (date: Date) => number | null;
  refresh: () => Promise<void>;
}

const CycleContext = createContext<CycleContextValue | undefined>(undefined);

export function CycleProvider({ children }: { children: React.ReactNode }) {
  const { user } = useUser();
  const [periodLogs, setPeriodLogs] = useState<PeriodLog[]>([]);
  const [symptomLogs, setSymptomLogs] = useState<SymptomLog[]>([]);
  const [bbtLogs, setBbtLogs] = useState<BBTLog[]>([]);
  const [settings, setSettings] = useState<CycleSettings | null>(null);
  const [availableSymptoms, setAvailableSymptoms] = useState<SymptomDefinition[]>([]);
  const [cycleStatus, setCycleStatus] = useState<CycleStatus | null>(null);
  const [currentRecommendation, setCurrentRecommendation] = useState<PhaseRecommendation | null>(null);
  const [strengthProfile] = useState<PhaseStrengthProfile | null>(null);

  function createDefaultSettings(userId: string): CycleSettings {
    return {
      id: generateId(),
      userId,
      averageCycleLength: 28,
      averagePeriodLength: 5,
      lutealPhaseLength: 14,
      enabledSymptomIds: [],
      notificationsEnabled: true
    };
  }

  const loadData = useCallback(async () => {
    if (!user) return;

    const [
      loadedPeriodLogs,
      loadedSymptomLogs,
      loadedBBTLogs,
      loadedSettings,
      loadedSymptoms
    ] = await Promise.all([
      getPeriodLogs(user.id),
      getSymptomLogs(user.id),
      getBBTLogs(user.id),
      getCycleSettings(user.id),
      getSymptomDefinitions(user.id)
    ]);

    setPeriodLogs(loadedPeriodLogs);
    setSymptomLogs(loadedSymptomLogs);
    setBbtLogs(loadedBBTLogs);
    setSettings(loadedSettings || createDefaultSettings(user.id));
    setAvailableSymptoms(loadedSymptoms);
  }, [user]);

  useEffect(() => {
    if (user) {
      loadData();
    }
  }, [user, loadData]);

  useEffect(() => {
    if (user && settings && periodLogs.length > 0) {
      const newCycleStatus = calculateCycleStatus(periodLogs, settings);
      setCycleStatus(newCycleStatus);
      if (newCycleStatus) {
        setCurrentRecommendation(getPhaseRecommendation(newCycleStatus.currentPhase));
      }
    }
  }, [user, periodLogs, settings]);

  async function logPeriod(
    startDate: Date,
    flowLevel?: 'light' | 'medium' | 'heavy',
    notes?: string
  ): Promise<void> {
    if (!user) return;

    const newLog: PeriodLog = {
      id: generateId(),
      userId: user.id,
      startDate,
      flowLevel,
      notes,
      createdAt: new Date()
    };

    await savePeriodLog(newLog);
    setPeriodLogs(prev => [newLog, ...prev]);
  }

  async function endPeriod(endDate: Date): Promise<void> {
    if (!user) return;

    const currentPeriod = periodLogs.find(log => !log.endDate);
    if (!currentPeriod) return;

    await dbUpdatePeriodLog(currentPeriod.id, { endDate });
    setPeriodLogs(prev =>
      prev.map(log => log.id === currentPeriod.id ? { ...log, endDate } : log)
    );
  }

  async function handleUpdatePeriodLog(id: string, updates: Partial<PeriodLog>): Promise<void> {
    await dbUpdatePeriodLog(id, updates);
    setPeriodLogs(prev =>
      prev.map(log => log.id === id ? { ...log, ...updates } : log)
    );
  }

  async function logSymptom(
    date: Date,
    symptomId: string,
    severity: number,
    notes?: string
  ): Promise<void> {
    if (!user) return;

    const newLog: SymptomLog = {
      id: generateId(),
      userId: user.id,
      date,
      symptomId,
      severity: severity as SymptomLog['severity'],
      notes
    };

    await saveSymptomLog(newLog);
    setSymptomLogs(prev => [newLog, ...prev]);
  }

  async function handleUpdateSymptomLog(id: string, updates: Partial<SymptomLog>): Promise<void> {
    await dbUpdateSymptomLog(id, updates);
    setSymptomLogs(prev =>
      prev.map(log => log.id === id ? { ...log, ...updates } : log)
    );
  }

  async function logBBT(
    date: Date,
    temperature: number,
    time: string,
    notes?: string
  ): Promise<void> {
    if (!user) return;

    const newLog: BBTLog = {
      id: generateId(),
      userId: user.id,
      date,
      temperature,
      time,
      notes
    };

    await saveBBTLog(newLog);
    setBbtLogs(prev => [newLog, ...prev]);
  }

  async function handleUpdateSettings(updates: Partial<CycleSettings>): Promise<void> {
    if (!user || !settings) return;

    const updatedSettings: CycleSettings = { ...settings, ...updates };
    await saveCycleSettings(updatedSettings);
    setSettings(updatedSettings);
  }

  async function enableSymptom(symptomId: string): Promise<void> {
    if (!user || !settings) return;

    const updatedSettings = {
      ...settings,
      enabledSymptomIds: [...settings.enabledSymptomIds, symptomId]
    };
    await saveCycleSettings(updatedSettings);
    setSettings(updatedSettings);
  }

  async function disableSymptom(symptomId: string): Promise<void> {
    if (!user || !settings) return;

    const updatedSettings = {
      ...settings,
      enabledSymptomIds: settings.enabledSymptomIds.filter(id => id !== symptomId)
    };
    await saveCycleSettings(updatedSettings);
    setSettings(updatedSettings);
  }

  async function addCustomSymptom(
    name: string,
    category: 'physical' | 'emotional' | 'energy'
  ): Promise<void> {
    if (!user) return;

    const newSymptom: SymptomDefinition = {
      id: generateId(),
      name,
      category,
      isDefault: false,
      userId: user.id
    };

    await saveSymptomDefinition(newSymptom);
    setAvailableSymptoms(prev => [...prev, newSymptom]);
    await enableSymptom(newSymptom.id);
  }

  function getSymptomsForDate(date: Date): SymptomLog[] {
    const dateStr = date.toISOString().split('T')[0];
    return symptomLogs.filter(log =>
      new Date(log.date).toISOString().split('T')[0] === dateStr
    );
  }

  function getCycleDayForDate(date: Date): number | null {
    if (!settings || periodLogs.length === 0) return null;

    const mostRecentPeriod = periodLogs.reduce((latest, current) =>
      new Date(current.startDate) > new Date(latest.startDate) ? current : latest
    , periodLogs[0]);

    const cycleStart = new Date(mostRecentPeriod.startDate);
    const daysSinceStart = Math.floor((date.getTime() - cycleStart.getTime()) / (1000 * 60 * 60 * 24));
    return (daysSinceStart % settings.averageCycleLength) + 1;
  }

  async function refresh(): Promise<void> {
    if (user) {
      await loadData();
    }
  }

  const value: CycleContextValue = {
    periodLogs,
    symptomLogs,
    bbtLogs,
    settings,
    availableSymptoms,
    cycleStatus,
    currentRecommendation,
    strengthProfile,
    logPeriod,
    endPeriod,
    updatePeriodLog: handleUpdatePeriodLog,
    logSymptom,
    updateSymptomLog: handleUpdateSymptomLog,
    logBBT,
    updateSettings: handleUpdateSettings,
    enableSymptom,
    disableSymptom,
    addCustomSymptom,
    getSymptomsForDate,
    getCycleDayForDate,
    refresh
  };

  return (
    <CycleContext.Provider value={value}>
      {children}
    </CycleContext.Provider>
  );
}

export function useCycle() {
  const context = useContext(CycleContext);
  if (!context) {
    throw new Error('useCycle must be used within CycleProvider');
  }
  return context;
}
