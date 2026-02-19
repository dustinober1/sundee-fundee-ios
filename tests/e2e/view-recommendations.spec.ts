import { test, expect } from '@playwright/test';
import { completeOnboarding } from './helpers/onboarding';

test('views cycle recommendations after logging period', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page, 'Recommendation Test User');

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
