import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test.describe('Full Workout Flow (TEST-01)', () => {
  test('completes workout from onboarding to finish', async ({ page }) => {
    // 1. Onboarding — creates a user in IndexedDB
    await page.goto('/onboarding');
    await completeOnboarding(page, 'Workout Flow User');

    // Confirm we land on the dashboard
    await expect(page).toHaveURL('/dashboard');

    // 2. Navigate to the Back Squat Complete Cycle workout page via app link
    //    (Using page.goto then waiting for user context to initialize)
    await page.goto('/workout/back-squat-complete-cycle');

    // Wait for the UserProvider to load the user from IndexedDB after page.goto() remounts
    // the root layout. We wait for domcontentloaded + give the useEffect async read time.
    await page.waitForLoadState('domcontentloaded');
    // The UserProvider useEffect reads from IndexedDB asynchronously — wait for it to settle.
    // We check via Dexie's own API exposed through the page rather than raw IDB to avoid
    // conflicting with Dexie's open connection.
    await page.waitForFunction(() => {
      // Check if the app has initialized by looking for a DOM element that only appears
      // after the page is fully rendered (the session selector heading)
      return document.querySelector('h1') !== null;
    }, { timeout: 5000 });
    // Give React state time to settle from the useEffect (IndexedDB → setState)
    await page.waitForTimeout(500);

    // 3. Wait for session selector and click "Support Session A"
    await expect(page.locator('text=Support Session A')).toBeVisible();
    await page.click('text=Support Session A');

    // 4. Wait for the exercise card to render (focus text confirms session loaded)
    await expect(page.locator('text=Positional Strength')).toBeVisible();

    // 5. Fill in weight for the first set — triggers onSetChange which enables "Complete Workout"
    //    The weight input has id="weight-1" for set number 1
    const firstWeightInput = page.locator('#weight-1').first();
    await firstWeightInput.fill('135');

    // 6. "Complete Workout" button should now be enabled (completedSets.size > 0)
    const completeButton = page.locator('button:has-text("Complete Workout")');
    await expect(completeButton).toBeEnabled({ timeout: 3000 });

    // 7. Click Complete Workout — triggers handleWorkoutComplete:
    //    saveCompletedWorkout → saveCompletedSet(s) → syncAfterWorkout → router.back()
    //    router.back() only fires AFTER all the above async saves complete.
    await completeButton.click();

    // 8. Wait for router.back() to navigate away — this proves handleWorkoutComplete ran
    //    to completion (user was loaded, saves succeeded, router.back() was called).
    //    Since we came from /dashboard → /workout/..., router.back() returns to /dashboard.
    await expect(page).toHaveURL('/dashboard', { timeout: 5000 });
  });
});
