import { expect, test } from '@playwright/test';

test.describe('Back Squat Program V2', () => {
  test('browses to program detail and sees phases', async ({ page }) => {
    await page.goto('/programs');
    await page.click('text=Back Squat: Complete 8-Week Cycle');

    await expect(page.locator('text=Training Phases')).toBeVisible();
    await expect(page.locator('text=Hypertrophy & Positional Foundation')).toBeVisible();
    await expect(page.locator('text=Strength & Rigidity')).toBeVisible();
    await expect(page.locator('text=Peak & Test')).toBeVisible();
  });

  test('starts workout and selects session', async ({ page }) => {
    await page.goto('/workout/back-squat-complete-cycle');

    await expect(page.locator('text=Week 1')).toBeVisible();
    await expect(page.locator('text=Support Session A')).toBeVisible();
    await expect(page.locator('text=Support Session B')).toBeVisible();
    await expect(page.locator('text=Sunday Anchor')).toBeVisible();

    await page.click('text=Support Session A');

    await expect(page.locator('text=Positional Strength')).toBeVisible();
    await expect(page.locator('text=Hypertrophy & Positional Foundation')).toBeVisible();
  });

  test('completes workout session', async ({ page }) => {
    await page.goto('/workout/back-squat-complete-cycle');
    await page.click('text=Support Session A');

    const firstWeightInput = page.locator('input[type=\"number\"]').first();
    await firstWeightInput.fill('195');

    await page.click('text=Complete Workout');
    await expect(page.locator('text=Complete Workout')).toBeVisible();
  });
});
