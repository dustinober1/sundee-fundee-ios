/**
 * OnboardingContext tests — RED phase
 *
 * Tests for OnboardingProvider, useOnboarding hook, and completeOnboarding
 */

import React from 'react';
import { renderHook, act } from '@testing-library/react-native';
import { OnboardingProvider, useOnboarding } from '../OnboardingContext';

// ─── Mock OnboardingProfileRepo ───────────────────────────────────────────────

const mockSaveProfile = jest.fn().mockResolvedValue(undefined);

jest.mock('@/src/repositories/OnboardingProfileRepo', () => ({
  getOnboardingProfileRepo: jest.fn(() => ({
    saveProfile: mockSaveProfile,
    getProfile: jest.fn().mockResolvedValue(null),
  })),
}));

// ─── Helpers ──────────────────────────────────────────────────────────────────

function wrapper({ children }: { children: React.ReactNode }) {
  return <OnboardingProvider>{children}</OnboardingProvider>;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('OnboardingContext draft initial state', () => {
  it('starts with empty name', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.name).toBe('');
  });

  it('starts with null experienceLevel', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.experienceLevel).toBeNull();
  });

  it('starts with null primaryGoal', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.primaryGoal).toBeNull();
  });

  it('starts with null gender', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.gender).toBeNull();
  });

  it('starts with cycleOptIn false', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.cycleOptIn).toBe(false);
  });
});

describe('OnboardingContext setters', () => {
  it('updates name via setName', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => {
      result.current.setName('Alice');
    });
    expect(result.current.draft.name).toBe('Alice');
  });

  it('updates experienceLevel via setExperienceLevel', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => {
      result.current.setExperienceLevel('intermediate');
    });
    expect(result.current.draft.experienceLevel).toBe('intermediate');
  });

  it('updates primaryGoal via setPrimaryGoal', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => {
      result.current.setPrimaryGoal('strength');
    });
    expect(result.current.draft.primaryGoal).toBe('strength');
  });

  it('updates gender via setGender', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => {
      result.current.setGender('female');
    });
    expect(result.current.draft.gender).toBe('female');
  });

  it('updates cycleOptIn via setCycleOptIn', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => {
      result.current.setCycleOptIn(true);
    });
    expect(result.current.draft.cycleOptIn).toBe(true);
  });
});

describe('completeOnboarding', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('calls saveProfile with all draft fields plus hasCompletedOnboarding: true', async () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });

    // Set all fields
    act(() => {
      result.current.setName('Alice');
      result.current.setExperienceLevel('intermediate');
      result.current.setPrimaryGoal('strength');
      result.current.setGender('female');
      result.current.setCycleOptIn(true);
    });

    await act(async () => {
      await result.current.completeOnboarding('user-123', false);
    });

    expect(mockSaveProfile).toHaveBeenCalledTimes(1);
    expect(mockSaveProfile).toHaveBeenCalledWith('user-123', {
      name: 'Alice',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength',
      gender: 'female',
      cycleOptIn: true,
      hasCompletedOnboarding: true,
    });
  });

  it('uses guest repo (isGuest=true) when completing as guest', async () => {
    const { getOnboardingProfileRepo } = jest.requireMock(
      '@/src/repositories/OnboardingProfileRepo'
    ) as { getOnboardingProfileRepo: jest.Mock };

    const { result } = renderHook(() => useOnboarding(), { wrapper });

    await act(async () => {
      await result.current.completeOnboarding('guest-uid', true);
    });

    expect(getOnboardingProfileRepo).toHaveBeenCalledWith(true);
  });

  it('uses non-guest repo (isGuest=false) when completing as authenticated user', async () => {
    const { getOnboardingProfileRepo } = jest.requireMock(
      '@/src/repositories/OnboardingProfileRepo'
    ) as { getOnboardingProfileRepo: jest.Mock };

    const { result } = renderHook(() => useOnboarding(), { wrapper });

    await act(async () => {
      await result.current.completeOnboarding('auth-uid', false);
    });

    expect(getOnboardingProfileRepo).toHaveBeenCalledWith(false);
  });
});

describe('useOnboarding outside provider', () => {
  it('throws when used outside OnboardingProvider', () => {
    // Suppress console.error for this expected error
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => {
      renderHook(() => useOnboarding());
    }).toThrow('useOnboarding must be used within an OnboardingProvider');
    consoleSpy.mockRestore();
  });
});
