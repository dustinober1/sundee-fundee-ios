/**
 * ReadinessSurveyModal.test.tsx
 *
 * Verifies that ReadinessSurveyModal correctly persists the readiness survey
 * via saveSurvey on submit, calls onComplete after a successful save, and
 * calls onDismiss on save failure (graceful degradation).
 *
 * Closes: READ-01 — proves the save path exists and is exercised.
 */

import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';

// ─── Mock: ReadinessRepo ──────────────────────────────────────────────────────
// Declared with 'mock' prefix per Babel hoisting safety rule (Phase 09 decision).

const mockSaveSurvey = jest.fn();
jest.mock('@/src/repositories/ReadinessRepo', () => ({
  getReadinessRepo: () => ({
    saveSurvey: (...args: unknown[]) => mockSaveSurvey(...args),
    getSurveyForDate: jest.fn().mockResolvedValue(null),
    getRecentSurveys: jest.fn().mockResolvedValue([]),
  }),
}));

// ─── Mock: AuthContext ────────────────────────────────────────────────────────

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: () => ({
    user: { uid: 'test-user' },
    isGuest: false,
  }),
}));

// ─── Mock: date-fns ───────────────────────────────────────────────────────────
// Return a fixed date so record assertions are deterministic.

jest.mock('date-fns', () => ({
  format: () => '2026-03-15',
}));

// ─── Import component after mocks ────────────────────────────────────────────

import ReadinessSurveyModal from '../ReadinessSurveyModal';

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('ReadinessSurveyModal — persistence', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('calls saveSurvey with correct arguments on submit', async () => {
    mockSaveSurvey.mockResolvedValue(undefined);

    const onComplete = jest.fn();
    const onDismiss = jest.fn();

    const { getByTestId } = render(
      <ReadinessSurveyModal
        visible={true}
        onComplete={onComplete}
        onDismiss={onDismiss}
      />,
    );

    // The submit button is enabled by default (sliders start at non-zero values)
    const submitButton = getByTestId('readiness-submit-button');

    await act(async () => {
      fireEvent.press(submitButton);
    });

    await waitFor(() => {
      expect(mockSaveSurvey).toHaveBeenCalledTimes(1);
    });

    expect(mockSaveSurvey).toHaveBeenCalledWith(
      'test-user',
      expect.objectContaining({
        uid: 'test-user',
        date: '2026-03-15',
        id: '2026-03-15',
      }),
    );
  });

  it('calls onComplete callback after successful save', async () => {
    mockSaveSurvey.mockResolvedValue(undefined);

    const onComplete = jest.fn();
    const onDismiss = jest.fn();

    const { getByTestId } = render(
      <ReadinessSurveyModal
        visible={true}
        onComplete={onComplete}
        onDismiss={onDismiss}
      />,
    );

    await act(async () => {
      fireEvent.press(getByTestId('readiness-submit-button'));
    });

    await waitFor(() => {
      expect(mockSaveSurvey).toHaveBeenCalledTimes(1);
    });

    // The modal auto-dismisses after 2 seconds and calls onComplete
    await act(async () => {
      jest.advanceTimersByTime(2000);
    });

    expect(onComplete).toHaveBeenCalledTimes(1);
    expect(onComplete).toHaveBeenCalledWith(
      expect.objectContaining({
        score: expect.any(Number),
        tier: expect.any(String),
      }),
    );
  });

  it('calls onDismiss on save failure (graceful degradation)', async () => {
    mockSaveSurvey.mockRejectedValue(new Error('Firestore write failed'));

    const onComplete = jest.fn();
    const onDismiss = jest.fn();

    const { getByTestId } = render(
      <ReadinessSurveyModal
        visible={true}
        onComplete={onComplete}
        onDismiss={onDismiss}
      />,
    );

    await act(async () => {
      fireEvent.press(getByTestId('readiness-submit-button'));
    });

    await waitFor(() => {
      expect(onDismiss).toHaveBeenCalledTimes(1);
    });

    expect(onComplete).not.toHaveBeenCalled();
  });
});
