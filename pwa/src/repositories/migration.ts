/**
 * Guest-to-auth data migration (web version).
 * Reads all guest data from localStorage, batch-writes to Firestore,
 * then clears localStorage keys.
 */
import { doc, collection, writeBatch } from 'firebase/firestore';
import { getFirestoreInstance } from '../firebase/firestore';
import type { Firestore, WriteBatch, DocumentReference } from 'firebase/firestore';

const MIGRATION_KEYS = [
  '@sundee/onboarding_profile',
  '@sundee/settings',
  '@sundee/workouts',
  '@sundee/readiness_surveys',
  '@sundee/exercise-maxes',
  '@sundee/injuries',
  '@sundee/pain_logs',
  '@sundee/period_logs',
  '@sundee/cycle_settings',
  '@sundee/benchmark_results',
  '@sundee/custom_benchmarks',
  '@sundee/program_enrollment',
  '@sundee/custom-exercises',
] as const;

const MAX_BATCH_OPS = 499;

interface BatchOp {
  ref: DocumentReference;
  data: Record<string, unknown>;
  merge?: boolean;
}

async function commitInChunks(db: Firestore, ops: BatchOp[]): Promise<void> {
  for (let i = 0; i < ops.length; i += MAX_BATCH_OPS) {
    const chunk = ops.slice(i, i + MAX_BATCH_OPS);
    const batch: WriteBatch = writeBatch(db);
    for (const op of chunk) {
      if (op.merge) {
        batch.set(op.ref, op.data, { merge: true });
      } else {
        batch.set(op.ref, op.data);
      }
    }
    await batch.commit();
  }
}

export async function migrateGuestDataToFirestore(uid: string): Promise<void> {
  const db = getFirestoreInstance();
  const ops: BatchOp[] = [];

  for (const key of MIGRATION_KEYS) {
    const value = localStorage.getItem(key);
    if (value == null) continue;

    const data = JSON.parse(value) as unknown;

    switch (key) {
      case '@sundee/onboarding_profile':
      case '@sundee/settings': {
        ops.push({ ref: doc(db, 'users', uid), data: data as Record<string, unknown>, merge: true });
        break;
      }
      case '@sundee/workouts': {
        for (const workout of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'workouts'), workout.id), data: workout as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/readiness_surveys': {
        for (const survey of data as Array<{ date: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'readiness'), survey.date), data: survey as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/exercise-maxes': {
        for (const max of data as Array<{ exerciseId: string; repRange: string }>) {
          const compositeId = `${max.exerciseId}_${max.repRange}`;
          ops.push({ ref: doc(collection(db, 'users', uid, 'exerciseMaxes'), compositeId), data: max as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/injuries': {
        for (const injury of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'injuries'), injury.id), data: injury as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/pain_logs': {
        for (const log of data as Array<{ id: string; injuryId: string }>) {
          ops.push({ ref: doc(db, 'users', uid, 'injuries', log.injuryId, 'painLogs', log.id), data: log as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/period_logs': {
        for (const log of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'periodLogs'), log.id), data: log as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/cycle_settings': {
        ops.push({ ref: doc(db, 'users', uid, 'cycleSettings', 'settings'), data: data as Record<string, unknown> });
        break;
      }
      case '@sundee/benchmark_results': {
        for (const result of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'benchmarkResults'), result.id), data: result as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/custom_benchmarks': {
        for (const benchmark of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'customBenchmarks'), benchmark.id), data: benchmark as Record<string, unknown> });
        }
        break;
      }
      case '@sundee/program_enrollment': {
        ops.push({ ref: doc(db, 'users', uid, 'enrollment', 'active'), data: data as Record<string, unknown> });
        break;
      }
      case '@sundee/custom-exercises': {
        for (const exercise of data as Array<{ id: string }>) {
          ops.push({ ref: doc(collection(db, 'users', uid, 'customExercises'), exercise.id), data: exercise as Record<string, unknown> });
        }
        break;
      }
    }
  }

  await commitInChunks(db, ops);

  // Only clear after all commits succeed
  for (const key of MIGRATION_KEYS) {
    localStorage.removeItem(key);
  }
}
