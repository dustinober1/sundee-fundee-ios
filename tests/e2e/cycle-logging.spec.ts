import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

async function completeOnboarding(page: Page) {
  // Use type() instead of fill() for React controlled inputs
  await page.type('input[id="name"]', 'Cycle Test User', { delay: 50 });
  // Wait for Next button to become enabled
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');
  // Wait a moment for step 2 to render
  await page.waitForTimeout(100);
  // Click the label for the beginner radio option
  await page.click('label[for="beginner"]');
  // Wait for Next button to become enabled
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');
  await page.click('button:has-text("Start Training")');
}

test('logs period flow and shows cycle status', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page);

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
