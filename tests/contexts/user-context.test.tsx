import { describe, it, expect, beforeEach } from 'vitest';
import { renderHook, act, waitFor } from '@testing-library/react';
import { ReactNode } from 'react';
import { UserProvider, useUser } from '@/contexts/user-context';
import { db } from '@/lib/db/dexie';
import { createUser } from '@/lib/db';

describe('User Context', () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  const wrapper = ({ children }: { children: ReactNode }) => (
    <UserProvider>{children}</UserProvider>
  );

  it('starts with null user when no user exists', async () => {
    const { result } = renderHook(() => useUser(), { wrapper });

    await waitFor(() => {
      expect(result.current.user).toBeNull();
    });
  });

  it('loads existing user on mount', async () => {
    const createdUser = await createUser({
      name: 'Test User',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength'
    });

    const { result } = renderHook(() => useUser(), { wrapper });

    await waitFor(() => {
      expect(result.current.user).not.toBeNull();
      expect(result.current.user?.name).toBe('Test User');
    });
  });

  it('updates user profile', async () => {
    await createUser({
      name: 'Test User',
      experienceLevel: 'beginner',
      primaryGoal: 'strength'
    });

    const { result } = renderHook(() => useUser(), { wrapper });

    await waitFor(() => {
      expect(result.current.user).not.toBeNull();
    });

    await act(async () => {
      await result.current.updateUserProfile({ name: 'Updated Name' });
    });

    expect(result.current.user?.name).toBe('Updated Name');
  });

  it('adds a new 1RM', async () => {
    await createUser({
      name: 'Test User',
      experienceLevel: 'intermediate',
      primaryGoal: 'strength'
    });

    const { result } = renderHook(() => useUser(), { wrapper });

    await waitFor(() => {
      expect(result.current.user).not.toBeNull();
    });

    await act(async () => {
      await result.current.update1RM('back-squat', 300);
    });

    expect(result.current.oneRepMaxes).toHaveLength(1);
    expect(result.current.oneRepMaxes[0].weight).toBe(300);
  });
});
