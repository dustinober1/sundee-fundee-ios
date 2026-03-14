/**
 * Guest-to-auth data migration.
 *
 * Reads all guest data from AsyncStorage, batch-writes to Firestore under the
 * authenticated user's uid, then clears AsyncStorage.
 *
 * Critical invariant: AsyncStorage is ONLY cleared after a successful batch.commit().
 * If commit() throws, AsyncStorage is preserved so the caller can retry.
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import { getFirestoreInstance } from '../firebase/firestore';

const MIGRATION_KEYS = [
  '@sundee/onboarding_profile',
  '@sundee/workouts',
  '@sundee/settings',
  '@sundee/readiness_surveys',
] as const;

/**
 * Migrates all guest AsyncStorage data to Firestore under the given uid.
 *
 * @param uid - The authenticated user's Firebase UID to migrate data into
 * @throws Will rethrow any Firestore error; AsyncStorage is NOT cleared on failure
 */
export async function migrateGuestDataToFirestore(uid: string): Promise<void> {
  const db = getFirestoreInstance();
  const batch = db.batch();

  // Fetch all guest data in a single round-trip
  const pairs = await AsyncStorage.multiGet([...MIGRATION_KEYS]);

  for (const [key, value] of pairs) {
    // Per research pitfall 6: multiGet returns [key, null] for missing keys
    if (value == null) {
      continue;
    }

    const data = JSON.parse(value) as unknown;

    switch (key) {
      case '@sundee/onboarding_profile': {
        const docRef = db.collection('users').doc(uid);
        batch.set(docRef, data, { merge: true });
        break;
      }

      case '@sundee/settings': {
        const docRef = db.collection('users').doc(uid);
        batch.set(docRef, data, { merge: true });
        break;
      }

      case '@sundee/workouts': {
        const workouts = data as Array<{ id: string }>;
        for (const workout of workouts) {
          const docRef = db
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .doc(workout.id);
          batch.set(docRef, workout);
        }
        break;
      }

      case '@sundee/readiness_surveys': {
        const surveys = data as Array<{ date: string }>;
        for (const survey of surveys) {
          const docRef = db
            .collection('users')
            .doc(uid)
            .collection('readiness')
            .doc(survey.date);
          batch.set(docRef, survey);
        }
        break;
      }
    }
  }

  // Commit all writes atomically — let any error propagate to the caller
  await batch.commit();

  // Only clear local storage after successful commit
  await AsyncStorage.multiRemove([...MIGRATION_KEYS]);
}
