import type { Page } from '@playwright/test';
import { expect } from '@playwright/test';

/**
 * Completes the onboarding flow for a given page.
 *
 * IMPORTANT: Caller must navigate to `/onboarding` before calling this helper.
 * This helper does NOT call `page.goto()` internally.
 *
 * @param page - Playwright Page object
 * @param name - Name to type in the name field (default: 'Test User')
 */
export async function completeOnboarding(page: Page, name = 'Test User'): Promise<void> {
  // Step 1: Enter name — use type() with delay for React controlled inputs
  await page.type('input[id="name"]', name, { delay: 50 });

  // Wait for Next button to become enabled, then click
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');

  // Wait a moment for step 2 to render
  await page.waitForTimeout(100);

  // Step 2: Select experience level (beginner)
  await page.click('label[for="beginner"]');

  // Wait for Next button to become enabled, then click
  await expect(page.locator('button:has-text("Next")')).toBeEnabled();
  await page.click('button:has-text("Next")');

  // Step 3: Start Training
  await page.click('button:has-text("Start Training")');

  // Wait for redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
}
