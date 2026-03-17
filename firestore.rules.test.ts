/**
 * Firestore Security Rules Tests
 *
 * Tests the user-owned data pattern defined in firestore.rules.
 * Requires the Firebase Emulator to run — excluded from default Jest run
 * via testPathIgnorePatterns in jest.config.js.
 *
 * Run with: npm run test:rules
 * (Runs: firebase emulators:exec --only firestore 'npx jest firestore.rules.test.ts')
 *
 * Tests cover:
 * - Unauthenticated access denial
 * - Owner read/write access
 * - Cross-user access denial
 * - Subcollection access patterns
 * - Read-only collections (programs, wods)
 */
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import path from 'path';

let testEnv: RulesTestEnvironment;

const RULES_PATH = path.join(__dirname, 'firestore.rules');

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'sundee-fundee-test',
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// ─── Unauthenticated Access ───────────────────────────────────────────────────

describe('Unauthenticated access', () => {
  test('DENY: unauthenticated user cannot read /users/{uid}', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb.collection('users').doc('alice').get()
    );
  });

  test('DENY: unauthenticated user cannot write /users/{uid}', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb.collection('users').doc('alice').set({ name: 'Alice' })
    );
  });

  test('DENY: unauthenticated user cannot read /programs', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb.collection('programs').doc('any-program').get()
    );
  });

  test('DENY: unauthenticated user cannot read /wods', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb.collection('wods').doc('any-wod').get()
    );
  });
});

// ─── Owner Access ─────────────────────────────────────────────────────────────

describe('Owner access to /users/{uid}', () => {
  const ALICE_UID = 'alice-uid-123';

  test('ALLOW: authenticated user can read their own /users/{uid}', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb.collection('users').doc(ALICE_UID).get()
    );
  });

  test('ALLOW: authenticated user can write their own /users/{uid}', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb.collection('users').doc(ALICE_UID).set({ name: 'Alice', updatedAt: new Date() })
    );
  });
});

// ─── Cross-User Access Denial ─────────────────────────────────────────────────

describe('Cross-user access denial', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('DENY: user cannot read another user\'s /users/{uid}', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(BOB_UID).get()
    );
  });

  test('DENY: user cannot write to another user\'s /users/{uid}', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(BOB_UID).set({ name: 'Bob' })
    );
  });
});

// ─── Subcollection Access ─────────────────────────────────────────────────────

describe('Subcollection access', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('ALLOW: user can read/write their own workout subcollection', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('workouts')
        .doc('workout-1')
        .set({ type: 'squat', reps: 5 })
    );
  });

  test('ALLOW: user can read their own workout subcollection', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('workouts')
        .doc('workout-1')
        .get()
    );
  });

  test('DENY: user cannot read another user\'s subcollection', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users')
        .doc(BOB_UID)
        .collection('workouts')
        .doc('workout-1')
        .get()
    );
  });

  test('DENY: user cannot write to another user\'s subcollection', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users')
        .doc(BOB_UID)
        .collection('injuries')
        .doc('injury-1')
        .set({ location: 'knee' })
    );
  });
});

// ─── Read-Only Collections ────────────────────────────────────────────────────

describe('/programs collection — read-only for authenticated users', () => {
  const USER_UID = 'some-user-uid';

  test('ALLOW: authenticated user can read /programs/{programId}', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(
      db.collection('programs').doc('program-abc').get()
    );
  });

  test('DENY: authenticated user cannot write to /programs/{programId}', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(
      db.collection('programs').doc('program-abc').set({ name: 'My Program' })
    );
  });
});

describe('/wods collection — read-only for authenticated users', () => {
  const USER_UID = 'some-user-uid';

  test('ALLOW: authenticated user can read /wods/{wodId}', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertSucceeds(
      db.collection('wods').doc('2026-03-14').get()
    );
  });

  test('DENY: authenticated user cannot write to /wods/{wodId}', async () => {
    const db = testEnv.authenticatedContext(USER_UID).firestore();
    await assertFails(
      db.collection('wods').doc('2026-03-14').set({ name: 'WOD of the Day' })
    );
  });
});

// ─── Pain Log Subcollection ───────────────────────────────────────────────────

describe('Pain log subcollection — /users/{uid}/injuries/{injuryId}/painLogs/{logId}', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('ALLOW: authenticated user can write their own pain log', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('injuries')
        .doc('injury-1')
        .collection('painLogs')
        .doc('log-1')
        .set({ painLevel: 4, date: '2026-03-15T00:00:00.000Z', notes: 'knee ache after squats' })
    );
  });

  test('ALLOW: authenticated user can read their own pain logs', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('injuries')
        .doc('injury-1')
        .collection('painLogs')
        .doc('log-1')
        .get()
    );
  });

  test('DENY: user cannot write another user\'s pain log', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users')
        .doc(BOB_UID)
        .collection('injuries')
        .doc('injury-1')
        .collection('painLogs')
        .doc('log-1')
        .set({ painLevel: 2, date: '2026-03-15T00:00:00.000Z', notes: 'test' })
    );
  });

  test('DENY: user cannot read another user\'s pain logs', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users')
        .doc(BOB_UID)
        .collection('injuries')
        .doc('injury-1')
        .collection('painLogs')
        .doc('log-1')
        .get()
    );
  });

  test('DENY: unauthenticated user cannot write pain logs', async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      unauthedDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('injuries')
        .doc('injury-1')
        .collection('painLogs')
        .doc('log-1')
        .set({ painLevel: 1, date: '2026-03-15T00:00:00.000Z', notes: 'test' })
    );
  });
});
