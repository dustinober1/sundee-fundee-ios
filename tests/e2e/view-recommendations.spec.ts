import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

async function completeOnboarding(page: Page) {
  // Use type() instead of fill() for React controlled inputs
  await page.type('input[id="name"]', 'Recommendation Test User', { delay: 50 });
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

test('views cycle recommendations after logging period', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page);

  await expect(page).toHaveURL('/dashboard');

  // Navigate to cycle page and wait for async data to load
  await page.goto('/cycle');
  await page.waitForLoadState('networkidle');
  // Wait additional time for IndexedDB async operations to complete
  await page.waitForTimeout(500);

  await page.click('button:has-text("Log Period")');

  // Wait for the Training Guidance text to appear
  await expect(page.getByText('Training Guidance')).toBeVisible({ timeout: 10000 });
  await expect(page.getByText('Focus: Recovery and light movement')).toBeVisible();
  await expect(page.getByText('Intensity: low')).toBeVisible();
  await expect(page.getByText('Focus on')).toBeVisible();
  await expect(page.getByText('yoga')).toBeVisible();
  await expect(page.getByText('Consider avoiding')).toBeVisible();
  await expect(page.getByText('heavy compound lifts')).toBeVisible();
});
