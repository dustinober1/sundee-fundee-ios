import { db } from './dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet, PeriodLog, SymptomLog, BBTLog, SymptomDefinition, CycleSettings } from '@/types';
import { generateId } from '@/lib/utils';

export async function createUser(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
  const user: User = {
    id: generateId(),
    ...data,
    createdAt: new Date()
  };
  await db.users.add(user);
  return user;
}

export async function getUser(): Promise<User | undefined> {
  return await db.users.toCollection().first();
}

export async function updateUser(id: string, updates: Partial<User>): Promise<void> {
  await db.users.update(id, updates);
}

export async function getActiveCycles(userId: string): Promise<ActiveCycle[]> {
  return await db.activeCycles
    .where('userId')
    .equals(userId)
    .and(cycle => cycle.status === 'active')
    .toArray();
}

export async function getLatest1RM(userId: string, exerciseId: string): Promise<OneRepMax | undefined> {
  return await db.oneRepMaxes
    .where('userId')
    .equals(userId)
    .and(orm => orm.exerciseId === exerciseId)
    .reverse()
    .first();
}

export async function saveCompletedWorkout(workout: CompletedWorkout): Promise<void> {
  await db.completedWorkouts.add(workout);
}

export async function saveCompletedSet(set: CompletedSet): Promise<void> {
  await db.completedSets.add(set);
}

export async function saveOneRepMax(oneRepMax: OneRepMax): Promise<void> {
  await db.oneRepMaxes.add(oneRepMax);
}

export async function getOneRepMaxesByUser(userId: string): Promise<OneRepMax[]> {
  return await db.oneRepMaxes
    .where('userId')
    .equals(userId)
    .toArray();
}

// Cycle tracking functions

export async function getPeriodLogs(userId: string): Promise<PeriodLog[]> {
  return await db.periodLogs
    .where('userId')
    .equals(userId)
    .reverse()
    .sortBy('startDate');
}

export async function savePeriodLog(log: PeriodLog): Promise<void> {
  await db.periodLogs.add(log);
}

export async function updatePeriodLog(id: string, updates: Partial<PeriodLog>): Promise<void> {
  await db.periodLogs.update(id, updates);
}

export async function getSymptomLogs(userId: string): Promise<SymptomLog[]> {
  return await db.symptomLogs
    .where('userId')
    .equals(userId)
    .reverse()
    .sortBy('date');
}

export async function saveSymptomLog(log: SymptomLog): Promise<void> {
  await db.symptomLogs.add(log);
}

export async function updateSymptomLog(id: string, updates: Partial<SymptomLog>): Promise<void> {
  await db.symptomLogs.update(id, updates);
}

export async function getBBTLogs(userId: string): Promise<BBTLog[]> {
  return await db.bbtLogs
    .where('userId')
    .equals(userId)
    .reverse()
    .sortBy('date');
}

export async function saveBBTLog(log: BBTLog): Promise<void> {
  await db.bbtLogs.add(log);
}

export async function getCycleSettings(userId: string): Promise<CycleSettings | undefined> {
  return await db.cycleSettings
    .where('userId')
    .equals(userId)
    .first();
}

export async function saveCycleSettings(settings: CycleSettings): Promise<void> {
  const existing = await db.cycleSettings.where('userId').equals(settings.userId).first();
  if (existing) {
    await db.cycleSettings.put(settings);
  } else {
    await db.cycleSettings.add(settings);
  }
}

export async function getDefaultSymptoms(): Promise<SymptomDefinition[]> {
  return await db.symptomDefinitions
    .filter(def => def.isDefault === true)
    .toArray();
}

export async function saveSymptomDefinition(definition: SymptomDefinition): Promise<void> {
  await db.symptomDefinitions.add(definition);
}

export async function getSymptomDefinitions(userId?: string): Promise<SymptomDefinition[]> {
  if (userId) {
    return await db.symptomDefinitions
      .filter(def => def.isDefault || def.userId === userId)
      .toArray();
  }
  return await db.symptomDefinitions.toArray();
}

// Default symptoms for seeding
const DEFAULT_SYMPTOMS: Omit<SymptomDefinition, 'id' | 'isDefault' | 'userId'>[] = [
  { name: 'Cramps', category: 'physical' },
  { name: 'Bloating', category: 'physical' },
  { name: 'Breast tenderness', category: 'physical' },
  { name: 'Headaches', category: 'physical' },
  { name: 'Acne', category: 'physical' },
  { name: 'Lower back pain', category: 'physical' },
  { name: 'Joint pain', category: 'physical' },
  { name: 'Mood swings', category: 'emotional' },
  { name: 'Anxiety', category: 'emotional' },
  { name: 'Irritability', category: 'emotional' },
  { name: 'Depression', category: 'emotional' },
  { name: 'Feeling overwhelmed', category: 'emotional' },
  { name: 'Low motivation', category: 'emotional' },
  { name: 'Fatigue', category: 'energy' },
  { name: 'Insomnia', category: 'energy' },
  { name: 'Low energy', category: 'energy' },
  { name: 'High energy', category: 'energy' },
  { name: 'Difficulty concentrating', category: 'energy' },
  { name: 'Food cravings', category: 'energy' },
];

export async function initializeDefaultSymptoms(): Promise<void> {
  const existingDefaults = await db.symptomDefinitions
    .filter(def => def.isDefault === true)
    .count();

  if (existingDefaults === 0) {
    const defaultSymptomsWithIds: SymptomDefinition[] = DEFAULT_SYMPTOMS.map(symptom => ({
      id: generateId(),
      isDefault: true,
      ...symptom
    }));
    await db.symptomDefinitions.bulkAdd(defaultSymptomsWithIds);
  }
}
