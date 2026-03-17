/**
 * Guest-to-auth data migration.
 *
 * Reads all guest data from AsyncStorage, batch-writes to Firestore under the
 * authenticated user's uid, then clears AsyncStorage.
 *
 * Critical invariant: AsyncStorage is ONLY cleared after ALL batch.commit() calls
 * succeed. If any commit throws, AsyncStorage is preserved so the caller can retry.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getFirestoreInstance } from '../firebase/firestore';

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

/** Maximum Firestore batch operations before splitting into a new batch. */
const MAX_BATCH_OPS = 499;

/** A deferred batch write operation: a doc ref + data (+ optional merge flag). */
interface BatchOp {
  ref: FirebaseFirestore.DocumentReference;
  data: unknown;
  merge?: boolean;
}

/**
 * Commit an array of BatchOp objects in sequential chunks of MAX_BATCH_OPS.
 *
 * If any chunk commit throws, the error propagates immediately — no partial cleanup.
 */
async function commitInChunks(
  db: FirebaseFirestore.Firestore,
  ops: BatchOp[]
): Promise<void> {
  for (let i = 0; i < ops.length; i += MAX_BATCH_OPS) {
    const chunk = ops.slice(i, i + MAX_BATCH_OPS);
    const batch = db.batch();
    for (const op of chunk) {
      if (op.merge) {
        batch.set(op.ref as never, op.data, { merge: true });
      } else {
        batch.set(op.ref as never, op.data);
      }
    }
    await batch.commit();
  }
}

/**
 * Migrates all guest AsyncStorage data to Firestore under the given uid.
 *
 * Handles the 500-operation Firestore batch limit by splitting into sequential
 * chunks. All 13 AsyncStorage data types are migrated and cleared only after
 * ALL batch commits succeed.
 *
 * @param uid - The authenticated user's Firebase UID to migrate data into
 * @throws Will rethrow any Firestore error; AsyncStorage is NOT cleared on failure
 */
export async function migrateGuestDataToFirestore(uid: string): Promise<void> {
  const db = getFirestoreInstance();

  // Fetch all guest data in a single round-trip
  const pairs = await AsyncStorage.multiGet([...MIGRATION_KEYS]);

  const ops: BatchOp[] = [];

  for (const [key, value] of pairs) {
    // Per research pitfall 6: multiGet returns [key, null] for missing keys
    if (value == null) {
      continue;
    }

    const data = JSON.parse(value) as unknown;

    switch (key) {
      case '@sundee/onboarding_profile': {
        const ref = db.collection('users').doc(uid);
        ops.push({ ref: ref as never, data, merge: true });
        break;
      }

      case '@sundee/settings': {
        const ref = db.collection('users').doc(uid);
        ops.push({ ref: ref as never, data, merge: true });
        break;
      }

      case '@sundee/workouts': {
        const workouts = data as Array<{ id: string }>;
        for (const workout of workouts) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .doc(workout.id);
          ops.push({ ref: ref as never, data: workout });
        }
        break;
      }

      case '@sundee/readiness_surveys': {
        const surveys = data as Array<{ date: string }>;
        for (const survey of surveys) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('readiness')
            .doc(survey.date);
          ops.push({ ref: ref as never, data: survey });
        }
        break;
      }

      case '@sundee/exercise-maxes': {
        const maxes = data as Array<{ exerciseId: string; repRange: string }>;
        for (const max of maxes) {
          const compositeId = `${max.exerciseId}_${max.repRange}`;
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('exerciseMaxes')
            .doc(compositeId);
          ops.push({ ref: ref as never, data: max });
        }
        break;
      }

      case '@sundee/injuries': {
        const injuries = data as Array<{ id: string }>;
        for (const injury of injuries) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('injuries')
            .doc(injury.id);
          ops.push({ ref: ref as never, data: injury });
        }
        break;
      }

      case '@sundee/pain_logs': {
        const logs = data as Array<{ id: string; injuryId: string }>;
        for (const log of logs) {
          // NESTED path: /users/{uid}/injuries/{injuryId}/painLogs/{id}
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('injuries')
            .doc(log.injuryId)
            .collection('painLogs')
            .doc(log.id);
          ops.push({ ref: ref as never, data: log });
        }
        break;
      }

      case '@sundee/period_logs': {
        const logs = data as Array<{ id: string }>;
        for (const log of logs) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('periodLogs')
            .doc(log.id);
          ops.push({ ref: ref as never, data: log });
        }
        break;
      }

      case '@sundee/cycle_settings': {
        // Single object — fixed doc ID 'settings'
        const ref = db
          .collection('users')
          .doc(uid)
          .collection('cycleSettings')
          .doc('settings');
        ops.push({ ref: ref as never, data });
        break;
      }

      case '@sundee/benchmark_results': {
        const results = data as Array<{ id: string }>;
        for (const result of results) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('benchmarkResults')
            .doc(result.id);
          ops.push({ ref: ref as never, data: result });
        }
        break;
      }

      case '@sundee/custom_benchmarks': {
        const benchmarks = data as Array<{ id: string }>;
        for (const benchmark of benchmarks) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('customBenchmarks')
            .doc(benchmark.id);
          ops.push({ ref: ref as never, data: benchmark });
        }
        break;
      }

      case '@sundee/program_enrollment': {
        // Single object — fixed doc ID 'active'
        const ref = db
          .collection('users')
          .doc(uid)
          .collection('enrollment')
          .doc('active');
        ops.push({ ref: ref as never, data });
        break;
      }

      case '@sundee/custom-exercises': {
        const exercises = data as Array<{ id: string }>;
        for (const exercise of exercises) {
          const ref = db
            .collection('users')
            .doc(uid)
            .collection('customExercises')
            .doc(exercise.id);
          ops.push({ ref: ref as never, data: exercise });
        }
        break;
      }
    }
  }

  // Commit all writes in sequential chunks — let any error propagate to the caller
  await commitInChunks(db as never, ops);

  // Only clear local storage after ALL commits succeed
  await AsyncStorage.multiRemove([...MIGRATION_KEYS, '@sundee/migration_pending']);
}
