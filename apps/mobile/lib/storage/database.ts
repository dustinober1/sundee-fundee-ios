import { getItem, setItem, STORAGE_KEYS } from './async-storage';
import { generateId } from '../utils';
import type { User, OneRepMax, ActiveCycle } from '@/types';

// User operations
export async function createUser(data: Omit<User, 'id' | 'createdAt'>): Promise<User> {
  const user: User = {
    id: generateId(),
    ...data,
    createdAt: new Date(),
  };
  await setItem(STORAGE_KEYS.USER, user);
  return user;
}

export async function getUser(): Promise<User | null> {
  return getItem<User>(STORAGE_KEYS.USER);
}

export async function updateUser(id: string, updates: Partial<User>): Promise<void> {
  const user = await getUser();
  if (user && user.id === id) {
    await setItem(STORAGE_KEYS.USER, { ...user, ...updates });
  }
}

// 1RM operations
export async function saveOneRepMax(oneRepMax: OneRepMax): Promise<void> {
  const all1RMs = await getItem<OneRepMax[]>(STORAGE_KEYS.ONE_REP_MAXES) || [];
  all1RMs.push(oneRepMax);
  await setItem(STORAGE_KEYS.ONE_REP_MAXES, all1RMs);
}

export async function getLatest1RM(userId: string, exerciseId: string): Promise<OneRepMax | undefined> {
  const all1RMs = await getItem<OneRepMax[]>(STORAGE_KEYS.ONE_REP_MAXES) || [];
  const user1RMs = all1RMs
    .filter(orm => orm.userId === userId && orm.exerciseId === exerciseId)
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  return user1RMs[0];
}

// Active cycles operations
export async function saveActiveCycle(cycle: ActiveCycle): Promise<void> {
  const cycles = await getItem<ActiveCycle[]>(STORAGE_KEYS.ACTIVE_CYCLES) || [];
  const existingIndex = cycles.findIndex(c => c.id === cycle.id);

  if (existingIndex >= 0) {
    cycles[existingIndex] = cycle;
  } else {
    cycles.push(cycle);
  }

  await setItem(STORAGE_KEYS.ACTIVE_CYCLES, cycles);
}

export async function getActiveCycles(userId: string): Promise<ActiveCycle[]> {
  const cycles = await getItem<ActiveCycle[]>(STORAGE_KEYS.ACTIVE_CYCLES) || [];
  return cycles.filter(c => c.userId === userId && c.status === 'active');
}
