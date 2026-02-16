import { db } from './dexie';
import type { User, OneRepMax, ActiveCycle, CompletedWorkout, CompletedSet } from '@/types';
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
