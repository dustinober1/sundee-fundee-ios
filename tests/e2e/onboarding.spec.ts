import { test, expect } from '@playwright/test';

test('completes onboarding flow', async ({ page }) => {
  await page.goto('/');

  // Should redirect to onboarding
  await expect(page).toHaveURL('/onboarding');

  // Step 1: Enter name
  await page.type('input[id="name"]', 'Test User', { delay: 50 });
  await page.click('button:has-text("Next")');

  // Step 2: Select experience
  await page.click('label:has-text("Beginner")');
  await page.click('button:has-text("Next")');

  // Step 3: Select goal and submit
  await page.click('button:has-text("Start Training")');

  // Should redirect to dashboard
  await expect(page).toHaveURL('/dashboard');
});

test('validates name input', async ({ page }) => {
  await page.goto('/onboarding');

  // Next button should be disabled without name
  const nextButton = page.locator('button:has-text("Next")');
  await expect(nextButton).toBeDisabled();

  // Type name
  await page.type('input[id="name"]', 'John', { delay: 50 });

  // Now button should be enabled
  await expect(nextButton).toBeEnabled();
});

test('navigates back through steps', async ({ page }) => {
  await page.goto('/onboarding');

  // Go to step 2
  await page.type('input[id="name"]', 'Test User', { delay: 50 });
  await page.click('button:has-text("Next")');

  // Back button should work
  const backButton = page.locator('button:has-text("Back")');
  await expect(backButton).toBeEnabled();
  await backButton.click();

  // Should be back on step 1
  await expect(page.locator('input[id="name"]')).toHaveValue('Test User');
});
