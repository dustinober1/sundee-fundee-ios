import { createClient } from '@/lib/supabase/client';
import { db } from '@/lib/db/dexie';
import { toSupabaseRows, fromSupabaseRows } from './sync-transforms';
import { dequeueWorkout } from './sync-queue';

/**
 * Retry wrapper with exponential backoff.
 * Attempts the operation up to maxAttempts times, waiting delayMs * attempt between tries.
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  maxAttempts = 3,
  delayMs = 1000
): Promise<T> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (attempt < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, delayMs * attempt));
      }
    }
  }
  throw lastError;
}

/**
 * Gets the currently authenticated Supabase user.
 * Throws if not authenticated.
 */
async function getAuthUser() {
  const supabase = createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();
  if (error || !user) throw new Error('Not authenticated');
  return user;
}

/**
 * Pushes a single workout (and its sets) to Supabase.
 * Uses upsert to handle duplicates gracefully.
 * Removes the workout from the offline queue on success.
 */
export async function pushWorkout(workoutId: string): Promise<void> {
  const user = await getAuthUser();
  const supabase = createClient();

  const [workout, sets] = await Promise.all([
    db.completedWorkouts.get(workoutId),
    db.completedSets.where('workoutId').equals(workoutId).toArray(),
  ]);

  if (!workout) throw new Error(`Workout ${workoutId} not found in local database`);

  await withRetry(async () => {
    const workoutRows = toSupabaseRows([workout], user.id);
    const { error: workoutError } = await supabase
      .from('completed_workouts')
      .upsert(workoutRows);
    if (workoutError) throw workoutError;

    if (sets.length > 0) {
      const setRows = toSupabaseRows(sets, user.id);
      const { error: setsError } = await supabase
        .from('completed_sets')
        .upsert(setRows);
      if (setsError) throw setsError;
    }
  });

  dequeueWorkout(workoutId);
}

/**
 * Pulls all cloud data for the authenticated user into Dexie.
 * Uses bulkPut (insert-or-replace) to merge without losing local-only records.
 */
export async function pullLatest(): Promise<void> {
  const user = await getAuthUser();
  const supabase = createClient();

  const pulls: Array<{
    tableName: string;
    put: (rows: Record<string, unknown>[]) => Promise<void>;
  }> = [
    {
      tableName: 'completed_workouts',
      put: async rows => {
        await db.completedWorkouts.bulkPut(
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          rows as any[]
        );
      },
    },
    {
      tableName: 'completed_sets',
      put: async rows => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await db.completedSets.bulkPut(rows as any[]);
      },
    },
    {
      tableName: 'one_rep_maxes',
      put: async rows => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await db.oneRepMaxes.bulkPut(rows as any[]);
      },
    },
    {
      tableName: 'active_cycles',
      put: async rows => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await db.activeCycles.bulkPut(rows as any[]);
      },
    },
    {
      tableName: 'personal_records',
      put: async rows => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await db.personalRecords.bulkPut(rows as any[]);
      },
    },
  ];

  for (const { tableName, put } of pulls) {
    const { data, error } = await supabase
      .from(tableName)
      .select('*')
      .eq('user_id', user.id);

    if (error) throw error;
    if (data && data.length > 0) {
      const records = fromSupabaseRows(data as Record<string, unknown>[]);
      await put(records);
    }
  }
}

/**
 * Uploads all local Dexie data to Supabase in a single batch.
 * Intended for initial sync when a user first authenticates.
 * Uses withRetry for resilience. Does NOT clear the offline queue —
 * call clearQueue() separately if desired after success.
 */
export async function uploadAllLocalData(): Promise<void> {
  const user = await getAuthUser();
  const supabase = createClient();

  const [workouts, sets, oneRepMaxes, activeCycles, personalRecords] =
    await Promise.all([
      db.completedWorkouts.toArray(),
      db.completedSets.toArray(),
      db.oneRepMaxes.toArray(),
      db.activeCycles.toArray(),
      db.personalRecords.toArray(),
    ]);

  await withRetry(async () => {
    if (workouts.length > 0) {
      const { error } = await supabase
        .from('completed_workouts')
        .upsert(toSupabaseRows(workouts, user.id));
      if (error) throw error;
    }

    if (sets.length > 0) {
      const { error } = await supabase
        .from('completed_sets')
        .upsert(toSupabaseRows(sets, user.id));
      if (error) throw error;
    }

    if (oneRepMaxes.length > 0) {
      const { error } = await supabase
        .from('one_rep_maxes')
        .upsert(toSupabaseRows(oneRepMaxes, user.id));
      if (error) throw error;
    }

    if (activeCycles.length > 0) {
      const { error } = await supabase
        .from('active_cycles')
        .upsert(toSupabaseRows(activeCycles, user.id));
      if (error) throw error;
    }

    if (personalRecords.length > 0) {
      const { error } = await supabase
        .from('personal_records')
        .upsert(toSupabaseRows(personalRecords, user.id));
      if (error) throw error;
    }
  });
}
