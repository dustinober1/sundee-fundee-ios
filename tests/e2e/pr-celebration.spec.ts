import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test.describe('PR Celebration (TEST-02)', () => {
  test('shows PR celebration overlay when user lifts more than seeded 1RM', async ({ page }) => {
    // 1. Complete onboarding — creates a user in IndexedDB
    await page.goto('/onboarding');
    await completeOnboarding(page, 'PR Test User');
    await expect(page).toHaveURL('/dashboard');

    // 2. Read the userId from IndexedDB (needed to seed the 1RM with the correct userId)
    //    NOTE: Dexie stores version*10 in IDB (so Dexie version 4 = IDB version 40).
    //    Open WITHOUT specifying a version to avoid the "lower version" error.
    const userId = await page.evaluate(async (): Promise<string> => {
      return new Promise<string>((resolve, reject) => {
        // Open without version number — uses the current IDB version (40 for Dexie v4)
        const request = indexedDB.open('StrengthApp');
        request.onsuccess = (event) => {
          const db = (event.target as IDBOpenDBRequest).result;
          const tx = db.transaction('users', 'readonly');
          const store = tx.objectStore('users');
          const getAll = store.getAll();
          getAll.onsuccess = () => {
            const users = getAll.result as Array<{ id: string }>;
            if (users.length > 0) resolve(users[0].id);
            else reject(new Error('No user found in IndexedDB'));
          };
          getAll.onerror = () => reject(new Error(`getAll error: ${getAll.error?.message}`));
          tx.oncomplete = () => db.close();
        };
        request.onerror = () => reject(new Error(`IDB open error: ${request.error?.message}`));
        request.onblocked = () => reject(new Error('IDB open blocked'));
      });
    });

    expect(userId).toBeTruthy();

    // 3. Seed a prior 1RM record for 'pause-squat' (first exercise in Support Session A)
    //    This establishes currentMax = 100 so checkWeightPR will fire when we enter 135.
    //    Guard: currentMax > 0 is required for PR detection to trigger.
    await page.evaluate(async ({ uid }: { uid: string }) => {
      return new Promise<void>((resolve, reject) => {
        // Open without version number — Dexie uses version*10 (v4 = IDB version 40)
        const request = indexedDB.open('StrengthApp');
        request.onsuccess = (event) => {
          const db = (event.target as IDBOpenDBRequest).result;
          const tx = db.transaction('oneRepMaxes', 'readwrite');
          const store = tx.objectStore('oneRepMaxes');
          store.put({
            id: 'seed-1rm-pause-squat',
            userId: uid,
            exerciseId: 'pause-squat',
            weight: 100,
            date: new Date().toISOString(),
          });
          tx.oncomplete = () => {
            db.close();
            resolve();
          };
          tx.onerror = () => reject(new Error(`Transaction error: ${tx.error?.message}`));
        };
        request.onerror = () => reject(new Error(`IDB open error: ${request.error?.message}`));
        request.onblocked = () => reject(new Error('IDB open blocked'));
      });
    }, { uid: userId });

    // 4. Reload the page so UserContext re-mounts and reads the seeded 1RM from Dexie.
    //    Without reload, the in-memory context from onboarding has oneRepMaxes = []
    //    and checkWeightPR sees currentMax === 0, never triggering a PR.
    await page.reload();
    await page.waitForURL('**/dashboard', { timeout: 5000 });
    await page.waitForLoadState('domcontentloaded');

    // 5. Navigate to the Back Squat Complete Cycle workout
    await page.goto('/workout/back-squat-complete-cycle');
    await page.waitForLoadState('domcontentloaded');

    // Wait for UserProvider useEffect to load user + oneRepMaxes from IndexedDB
    await page.waitForFunction(() => document.querySelector('h1') !== null, { timeout: 5000 });
    await page.waitForTimeout(500);

    // 6. Click "Support Session A" — contains 'pause-squat' as first exercise
    await expect(page.locator('text=Support Session A')).toBeVisible({ timeout: 5000 });
    await page.click('text=Support Session A');

    // 7. Wait for exercise card to render (Positional Strength is the session focus for pause-squat)
    await page.waitForSelector('input[type="number"]', { timeout: 5000 });

    // 8. Fill in 135 lbs — exceeds seeded 1RM of 100 lbs.
    //    checkWeightPR('pause-squat', 135): 135 > 100 && 100 > 0 → true → PRCelebration renders
    const firstWeightInput = page.locator('#weight-1').first();
    await firstWeightInput.fill('135');
    // Trigger React onChange by firing an input event
    await firstWeightInput.press('Tab');

    // 9. Assert the PR celebration overlay appears
    //    PRCelebration renders: <h2>New PR!</h2> and subtitle "New Weight Record!"
    await expect(page.getByText('New PR!')).toBeVisible({ timeout: 5000 });
    await expect(page.getByText('New Weight Record!')).toBeVisible({ timeout: 3000 });
  });
});
