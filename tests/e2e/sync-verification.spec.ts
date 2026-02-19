import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

/**
 * TEST-03: Sync Verification
 *
 * Verifies that the sync wiring is active by confirming the workout ID is
 * enqueued in the localStorage sync queue after workout completion.
 *
 * Sync flow:
 *   handleWorkoutComplete → syncAfterWorkout(workoutId)
 *   → isSyncConfigured=true (fake Supabase env vars injected via playwright.config.ts)
 *   → isAuthenticated=false (no real auth session in tests)
 *   → enqueueWorkout(workoutId) → localStorage.setItem('sync_pending_workout_ids', [...])
 *
 * This test intentionally runs in the unauthenticated state — the offline queue
 * path is deterministic and requires no mock timing.
 */
test.describe('Sync Verification (TEST-03)', () => {
  test('enqueues workout ID in sync queue after workout completion', async ({ page }) => {
    // 1. Complete onboarding — creates a user in IndexedDB
    await page.goto('/onboarding');
    await completeOnboarding(page, 'Sync Test User');
    await expect(page).toHaveURL('/dashboard');

    // 2. Navigate to workout — gives UserProvider time to re-load user from IndexedDB
    await page.goto('/workout/back-squat-complete-cycle');
    await page.waitForLoadState('domcontentloaded');

    // Wait for UserProvider useEffect to read user from IndexedDB
    await page.waitForFunction(() => document.querySelector('h1') !== null, { timeout: 5000 });
    await page.waitForTimeout(500);

    // 3. Select Support Session A
    await expect(page.locator('text=Support Session A')).toBeVisible({ timeout: 5000 });
    await page.click('text=Support Session A');

    // 4. Wait for exercise card to render with weight input
    await page.waitForSelector('#weight-1', { timeout: 5000 });

    // 5. Fill weight input — triggers onSetChange, marks set complete, enables "Complete Workout"
    const firstWeightInput = page.locator('#weight-1').first();
    await firstWeightInput.fill('135');
    await firstWeightInput.press('Tab');

    // 6. Confirm "Complete Workout" button is enabled (completedSets.size > 0)
    const completeButton = page.locator('button:has-text("Complete Workout")');
    await expect(completeButton).toBeEnabled({ timeout: 3000 });

    // 7. Click Complete Workout
    //    handleWorkoutComplete: saveCompletedWorkout → saveCompletedSet(s) → syncAfterWorkout → router.back()
    await completeButton.click();

    // 8. Wait for the full async save chain and sync attempt to complete
    //    router.back() is the last line in handleWorkoutComplete — URL change confirms chain completed
    await expect(page).toHaveURL('/dashboard', { timeout: 5000 });

    // 9. Additional wait for async syncAfterWorkout (called before router.back but async in nature)
    await page.waitForTimeout(500);

    // 10. Verify the workout was enqueued in the localStorage sync queue
    //     Key: 'sync_pending_workout_ids' (from src/lib/sync/sync-queue.ts QUEUE_KEY constant)
    //     Since user is unauthenticated, syncAfterWorkout hits the else branch:
    //       enqueueWorkout(workoutId) → localStorage.setItem('sync_pending_workout_ids', JSON.stringify([workoutId]))
    const queue = await page.evaluate((): string[] => {
      const raw = localStorage.getItem('sync_pending_workout_ids');
      if (!raw) return [];
      try {
        return JSON.parse(raw) as string[];
      } catch {
        return [];
      }
    });

    // The workout ID should appear in the queue
    expect(queue.length).toBeGreaterThan(0);
    // Each entry should be a non-empty string (the workout UUID)
    expect(typeof queue[0]).toBe('string');
    expect(queue[0].length).toBeGreaterThan(0);
  });
});
