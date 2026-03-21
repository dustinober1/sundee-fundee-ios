/**
 * Firestore instance — web-only, IndexedDB persistence for offline support.
 */
import {
  getFirestore,
  initializeFirestore,
  persistentLocalCache,
  type Firestore,
} from 'firebase/firestore';
import { getFirebaseApp } from './app';

let instance: Firestore | null = null;

export function getFirestoreInstance(): Firestore {
  if (instance) return instance;

  const app = getFirebaseApp();

  try {
    instance = initializeFirestore(app, {
      localCache: persistentLocalCache({}),
    });
  } catch {
    // Already initialized (HMR) or IndexedDB unavailable
    instance = getFirestore(app);
  }

  return instance;
}
