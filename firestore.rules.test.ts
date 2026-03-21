/**
 * Firestore Security Rules Tests
 *
 * Tests the user-owned data pattern defined in firestore.rules.
 * Requires the Firebase Emulator to run — excluded from default Jest run
 * via testPathIgnorePatterns in jest.config.js.
 *
 * Run with: npm run test:rules
 * (Runs: firebase emulators:exec --only firestore 'npx jest --config jest.rules.config.js')
 *
 * Tests cover:
 * - Unauthenticated access denial
 * - Owner read/write access
 * - Cross-user access denial
 * - Subcollection access patterns (depth-1 and depth-2)
 * - Read-only collections (programs, wods)
 * - SEC-02: premiumEntitlement field block on create and update
 * - Depth-2 subcollection: injuries/{id}/painLogs/{id}
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

  test("DENY: user cannot read another user's /users/{uid}", async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(BOB_UID).get()
    );
  });

  test("DENY: user cannot write to another user's /users/{uid}", async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(BOB_UID).set({ name: 'Bob' })
    );
  });
});

// ─── Depth-1 Subcollection Access ─────────────────────────────────────────────

describe('Depth-1 subcollection access', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('ALLOW: user can write to their own workout subcollection', async () => {
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

  test("DENY: user cannot read another user's subcollection", async () => {
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

  test("DENY: user cannot write to another user's subcollection", async () => {
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

// ─── SEC-02: premiumEntitlement Field Block ───────────────────────────────────
//
// The premiumEntitlement field is only written by the stripeWebhook Cloud Function
// via Firebase Admin SDK (which bypasses security rules). Client SDK cannot write it.

describe('SEC-02: premiumEntitlement field block', () => {
  const ALICE_UID = 'alice-uid-123';

  test('DENY: user cannot create their own user doc with premiumEntitlement field', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(ALICE_UID).set({
        name: 'Alice',
        premiumEntitlement: { status: 'active', planId: 'monthly' },
      })
    );
  });

  test('ALLOW: user can create their own user doc without premiumEntitlement field', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb.collection('users').doc(ALICE_UID).set({ name: 'Alice' })
    );
  });

  test('DENY: user cannot update their own user doc to add premiumEntitlement field', async () => {
    // Seed the document using admin context (bypasses rules) so we can test update behavior.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore()
        .collection('users')
        .doc(ALICE_UID)
        .set({ name: 'Alice' });
    });

    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(ALICE_UID).update({
        premiumEntitlement: { status: 'active' },
      })
    );
  });

  test('ALLOW: user can update their own user doc without touching premiumEntitlement', async () => {
    // Seed the document using admin context.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore()
        .collection('users')
        .doc(ALICE_UID)
        .set({ name: 'Alice', weightUnit: 'lbs' });
    });

    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb.collection('users').doc(ALICE_UID).update({
        weightUnit: 'kg',
        updatedAt: new Date(),
      })
    );
  });

  test('DENY: user cannot update premiumEntitlement even alongside other valid fields', async () => {
    // Seed the document.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore()
        .collection('users')
        .doc(ALICE_UID)
        .set({ name: 'Alice', weightUnit: 'lbs' });
    });

    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb.collection('users').doc(ALICE_UID).update({
        name: 'Alice Updated',
        premiumEntitlement: { status: 'active' },
      })
    );
  });
});

// ─── Depth-2 Subcollection: injuries/{id}/painLogs/{id} ──────────────────────
//
// Verifies the {nested=**} wildcard covers depth-2 paths.
// Without it, painLogs would be denied by the default-deny rule.

describe('Depth-2 subcollection access (injuries/{id}/painLogs/{id})', () => {
  const ALICE_UID = 'alice-uid-123';
  const BOB_UID = 'bob-uid-456';

  test('ALLOW: user can write to depth-2 subcollection (injuries/{id}/painLogs/{id})', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('injuries')
        .doc('inj-1')
        .collection('painLogs')
        .doc('log-1')
        .set({ severity: 3, date: '2026-03-21', notes: 'mild discomfort' })
    );
  });

  test('ALLOW: user can read from depth-2 subcollection (injuries/{id}/painLogs/{id})', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertSucceeds(
      aliceDb
        .collection('users')
        .doc(ALICE_UID)
        .collection('injuries')
        .doc('inj-1')
        .collection('painLogs')
        .doc('log-1')
        .get()
    );
  });

  test("DENY: user cannot access another user's depth-2 subcollection", async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      aliceDb
        .collection('users')
        .doc(BOB_UID)
        .collection('injuries')
        .doc('inj-1')
        .collection('painLogs')
        .doc('log-1')
        .get()
    );
  });
});
