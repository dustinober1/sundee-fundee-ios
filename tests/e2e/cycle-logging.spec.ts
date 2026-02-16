import { test, expect } from '@playwright/test';
import type { Page } from '@playwright/test';

async function completeOnboarding(page: Page) {
  await page.fill('input[id="name"]', 'Cycle Test User');
  await page.click('button:has-text("Next")');
  await page.click('label:has-text("Beginner")');
  await page.click('button:has-text("Next")');
  await page.click('button:has-text("Start Training")');
}

test('logs period flow and shows cycle status', async ({ page }) => {
  await page.goto('/onboarding');
  await completeOnboarding(page);

  await expect(page).toHaveURL('/dashboard');

  await page.goto('/cycle');
  await expect(page.locator('text=Training Guidance')).toHaveCount(0);

  await page.click('button:has-text("Log Period")');

  await expect(page.getByRole('heading', { name: 'Training Guidance' })).toBeVisible();
  await expect(page.getByText('Menstrual Phase')).toBeVisible();
});
