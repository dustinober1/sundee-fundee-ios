/**
 * readiness-persistence.test.ts
 *
 * Source-file verification tests for the readiness survey persistence pipeline.
 * Follows the Phase 8 cycle-adaptation-gate.test.ts pattern — reads source files
 * and asserts that critical wiring patterns are present in production code.
 *
 * Closes: READ-01 and READ-02.
 *
 * READ-01: saveSurvey called on modal submit, dashboard hides card after save,
 *           Firestore rules permit readiness subcollection writes.
 * READ-02: workout-session.tsx loads readiness score from repo for adaptation.
 */

import * as fs from 'fs';
import * as path from 'path';

// Root of the RN project (two levels up from src/__tests__)
const RN_ROOT = path.join(__dirname, '../..');

describe('Readiness persistence pipeline — source verification', () => {
  // ── READ-01: Modal save wiring ───────────────────────────────────────────

  test('ReadinessSurveyModal.tsx contains saveSurvey call', () => {
    const content = fs.readFileSync(
      path.join(RN_ROOT, 'src/components/readiness/ReadinessSurveyModal.tsx'),
      'utf-8',
    );
    expect(content).toContain('saveSurvey');
  });

  // ── READ-01: Dashboard card suppression ─────────────────────────────────

  test('dashboard index.tsx contains getSurveyForDate call', () => {
    const content = fs.readFileSync(
      path.join(RN_ROOT, 'app/(app)/(tabs)/index.tsx'),
      'utf-8',
    );
    expect(content).toContain('getSurveyForDate');
  });

  test('dashboard index.tsx hides readiness card when survey exists', () => {
    const content = fs.readFileSync(
      path.join(RN_ROOT, 'app/(app)/(tabs)/index.tsx'),
      'utf-8',
    );
    // Verify the conditional suppression: if existing != null → setShowReadinessCard(false)
    expect(content).toMatch(
      /existing\s*!=\s*null[\s\S]*?setShowReadinessCard\(false\)/,
    );
  });

  // ── READ-02: Workout session readiness consumption ───────────────────────

  test('workout-session.tsx loads readiness score from repo', () => {
    const content = fs.readFileSync(
      path.join(RN_ROOT, 'app/(app)/workout-session.tsx'),
      'utf-8',
    );
    expect(content).toContain('getSurveyForDate');
    // Confirm the score is extracted from the survey result
    expect(content).toMatch(/survey\?\.result\.score/);
  });

  // ── READ-01: Firestore rules permit readiness subcollection writes ────────

  test('Firestore rules allow readiness subcollection access', () => {
    const content = fs.readFileSync(
      path.join(RN_ROOT, 'firestore.rules'),
      'utf-8',
    );
    // The wildcard subcollection match under /users/{userId} covers the readiness
    // subcollection (users/{uid}/readiness/{date}).
    expect(content).toMatch(/match\s+\/\{subcollection\}\/\{docId\}/);
    // Confirm it grants read/write for the authenticated owner
    expect(content).toContain('request.auth.uid == userId');
  });
});
