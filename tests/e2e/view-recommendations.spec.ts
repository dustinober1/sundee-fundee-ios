import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

async function completeOnboarding(page: Page) {
  await page.fill('input[id="name"]', 'Recommendation Test User');
  await page.click('button:has-text("Next")');
  await page.click('label:has-text("Beginner")');
  await page.click('button:has-text("Next")');
  await page.click('button:has-text("Start Training")');
}

test('views cycle recommendations after logging period', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page);

  await expect(page).toHaveURL('/dashboard');
  await page.goto('/cycle');
  await page.click('button:has-text("Log Period")');

  await expect(page.getByRole('heading', { name: 'Training Guidance' })).toBeVisible();
  await expect(page.getByText('Focus: Recovery and light movement')).toBeVisible();
  await expect(page.getByText('Intensity: low')).toBeVisible();
  await expect(page.getByText('Focus on')).toBeVisible();
  await expect(page.getByText('yoga')).toBeVisible();
  await expect(page.getByText('Consider avoiding')).toBeVisible();
  await expect(page.getByText('heavy compound lifts')).toBeVisible();
});
