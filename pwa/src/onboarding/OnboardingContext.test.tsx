import { describe, it, expect, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { OnboardingProvider, useOnboarding } from './OnboardingContext';
import type { ReactNode } from 'react';

// Mock the repo
vi.mock('../repositories/OnboardingProfileRepo', () => ({
  getOnboardingProfileRepo: () => ({
    saveProfile: vi.fn().mockResolvedValue(undefined),
  }),
}));

function wrapper({ children }: { children: ReactNode }) {
  return <OnboardingProvider>{children}</OnboardingProvider>;
}

describe('OnboardingContext', () => {
  it('provides initial draft with empty values', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    expect(result.current.draft.name).toBe('');
    expect(result.current.draft.experienceLevel).toBeNull();
    expect(result.current.draft.primaryGoal).toBeNull();
    expect(result.current.draft.gender).toBeNull();
    expect(result.current.draft.cycleOptIn).toBe(false);
  });

  it('updates name', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => result.current.setName('Alice'));
    expect(result.current.draft.name).toBe('Alice');
  });

  it('updates experience level', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => result.current.setExperienceLevel('advanced'));
    expect(result.current.draft.experienceLevel).toBe('advanced');
  });

  it('updates gender', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => result.current.setGender('female'));
    expect(result.current.draft.gender).toBe('female');
  });

  it('updates cycle opt-in', () => {
    const { result } = renderHook(() => useOnboarding(), { wrapper });
    act(() => result.current.setCycleOptIn(true));
    expect(result.current.draft.cycleOptIn).toBe(true);
  });

  it('throws when used outside provider', () => {
    expect(() => {
      renderHook(() => useOnboarding());
    }).toThrow('useOnboarding must be used within an OnboardingProvider');
  });
});
