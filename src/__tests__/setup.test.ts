/**
 * Smoke test for Jest infrastructure setup.
 *
 * Verifies that:
 * - Jest runs with the jest-expo preset
 * - TypeScript path aliases (@/*) resolve correctly
 * - Theme tokens are importable and correct
 *
 * This is an infrastructure test — if it fails, Jest or the module
 * resolver is misconfigured.
 */

import { CREAM, NAVY, ORANGE, background, text, accent } from '@/src/theme/colors';
import { fontSize, fontWeight, textStyles } from '@/src/theme/typography';

describe('Theme colors', () => {
  test('CREAM equals #F4F0DF', () => {
    expect(CREAM).toBe('#F4F0DF');
  });

  test('NAVY equals #0D1A40', () => {
    expect(NAVY).toBe('#0D1A40');
  });

  test('ORANGE equals #F2731A', () => {
    expect(ORANGE).toBe('#F2731A');
  });

  test('semantic alias background equals CREAM', () => {
    expect(background).toBe(CREAM);
  });

  test('semantic alias text equals NAVY', () => {
    expect(text).toBe(NAVY);
  });

  test('semantic alias accent equals ORANGE', () => {
    expect(accent).toBe(ORANGE);
  });
});

describe('Theme typography', () => {
  test('body font size is 14', () => {
    expect(fontSize.body).toBe(14);
  });

  test('h1 font size is 32', () => {
    expect(fontSize.h1).toBe(32);
  });

  test('bold font weight is 700', () => {
    expect(fontWeight.bold).toBe('700');
  });

  test('textStyles.body has fontSize and fontWeight', () => {
    expect(textStyles.body.fontSize).toBe(14);
    expect(textStyles.body.fontWeight).toBe('400');
  });
});
