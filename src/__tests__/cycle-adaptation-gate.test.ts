/**
 * cycle-adaptation-gate.test.ts
 *
 * Unit tests for the cycle adaptation gate logic used in:
 *   - app/(app)/workout-session.tsx (loadAdaptationContext)
 *   - app/(app)/(tabs)/index.tsx (loadCycleStatus)
 *
 * The gate pattern: profile?.cycleOptIn === true && periodLogCount > 0
 * This ensures cycle adaptation only activates for users who opted in during
 * onboarding AND have period log history — never for opted-out or untracked users.
 */

import * as fs from 'fs';
import * as path from 'path';

// ─── Gate logic (pure function extracted from both files) ─────────────────────

/**
 * Returns true when cycle adaptation should be loaded.
 * Mirrors the gate condition in workout-session.tsx and (tabs)/index.tsx.
 */
function shouldLoadCycleAdaptation(
  profile: { cycleOptIn?: boolean } | null,
  periodLogCount: number,
): boolean {
  return profile?.cycleOptIn === true && periodLogCount > 0;
}

// ─── Gate logic tests ─────────────────────────────────────────────────────────

describe('Cycle adaptation gate', () => {
  test('activates when user opted in and has period logs', () => {
    expect(shouldLoadCycleAdaptation({ cycleOptIn: true }, 3)).toBe(true);
  });

  test('does NOT activate when user did not opt in', () => {
    expect(shouldLoadCycleAdaptation({ cycleOptIn: false }, 3)).toBe(false);
  });

  test('does NOT activate when no period logs exist', () => {
    expect(shouldLoadCycleAdaptation({ cycleOptIn: true }, 0)).toBe(false);
  });

  test('does NOT activate when profile is null', () => {
    expect(shouldLoadCycleAdaptation(null, 5)).toBe(false);
  });

  test('does NOT activate when cycleOptIn is undefined', () => {
    expect(shouldLoadCycleAdaptation({}, 3)).toBe(false);
  });
});

// ─── Source file verification ─────────────────────────────────────────────────

describe('Source file verification', () => {
  test('workout-session.tsx uses cycleOptIn not cycleTrackingEnabled', () => {
    const content = fs.readFileSync(
      path.join(__dirname, '../../app/(app)/workout-session.tsx'),
      'utf-8',
    );
    expect(content).toContain('profile?.cycleOptIn === true');
    expect(content).not.toContain('cycleTrackingEnabled');
  });

  test('dashboard index.tsx uses cycleOptIn not cycleTrackingEnabled', () => {
    const content = fs.readFileSync(
      path.join(__dirname, '../../app/(app)/(tabs)/index.tsx'),
      'utf-8',
    );
    expect(content).toContain('profile?.cycleOptIn === true');
    expect(content).not.toContain('cycleTrackingEnabled');
  });
});
