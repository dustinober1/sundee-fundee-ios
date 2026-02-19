import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test('logs period flow and shows cycle status', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page, 'Cycle Test User');

  await expect(page).toHaveURL('/dashboard');

  // Navigate to cycle page and wait for async data to load
  await page.goto('/cycle');
  // Wait for page to be fully loaded and CycleProvider to initialize
  await page.waitForLoadState('networkidle');
  // Wait additional time for IndexedDB async operations to complete
  await page.waitForTimeout(500);
  // Verify initial state - no recommendation yet
  await expect(page.locator('text=Training Guidance')).toHaveCount(0);

  // Click Log Period button
  await page.click('button:has-text("Log Period")');

  // Wait for the Training Guidance text to appear with increased timeout
  await expect(page.getByText('Training Guidance')).toBeVisible({ timeout: 10000 });
});
