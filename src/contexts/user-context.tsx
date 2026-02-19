'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import type { User as SupabaseUser } from '@supabase/supabase-js';
import type { User, OneRepMax, SyncStatus } from '@/types';
import { getUser, updateUser, getOneRepMaxesByUser, saveOneRepMax } from '@/lib/db';
import { generateId } from '@/lib/utils';
import { createClient } from '@/lib/supabase/client';
import {
  pushWorkout,
  pullLatest,
  uploadAllLocalData as uploadAll,
  withRetry,
  getQueue,
  enqueueWorkout,
  dequeueWorkout,
  clearQueue,
} from '@/lib/sync';
import { useOnlineStatus } from '@/hooks/use-online-status';

interface UserContextValue {
  // Local user data (existing)
  user: User | null;
  oneRepMaxes: OneRepMax[];
  updateUserProfile: (updates: Partial<User>) => Promise<void>;
  update1RM: (exerciseId: string, weight: number) => Promise<void>;
  refresh: () => Promise<void>;

  // Auth & Sync (new)
  authUser: SupabaseUser | null;
  isAuthenticated: boolean;
  syncStatus: SyncStatus;
  lastSyncedAt: Date | null;
  isOnline: boolean;

  // Sync operations (new)
  syncAfterWorkout: (workoutId: string) => Promise<void>;
  pullFromCloud: () => Promise<void>;
  uploadExistingData: () => Promise<boolean>;
  signOut: () => Promise<void>;
}

const UserContext = createContext<UserContextValue | undefined>(undefined);

export function UserProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [oneRepMaxes, setOneRepMaxes] = useState<OneRepMax[]>([]);

  // Auth state
  const [authUser, setAuthUser] = useState<SupabaseUser | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>('offline');
  const [lastSyncedAt, setLastSyncedAt] = useState<Date | null>(null);

  const isOnline = useOnlineStatus();
  const isAuthenticated = authUser !== null;

  const supabase = createClient();

  // ── Local data loading ──────────────────────────────────────────────────

  async function loadUserData() {
    const userData = await getUser();
    if (userData) {
      setUser(userData);
      const orms = await getOneRepMaxesByUser(userData.id);
      setOneRepMaxes(orms);
    }
  }

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const userData = await getUser();
      if (!isActive || !userData) return;
      const orms = await getOneRepMaxesByUser(userData.id);
      if (!isActive) return;
      setUser(userData);
      setOneRepMaxes(orms);
    })();

    return () => {
      isActive = false;
    };
  }, []);

  // ── Auth initialization ─────────────────────────────────────────────────

  useEffect(() => {
    // Get current session on mount
    supabase.auth.getUser().then(({ data }) => {
      setAuthUser(data.user ?? null);
    });

    // Listen for auth state changes (sign-in, sign-out, token refresh)
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setAuthUser(session?.user ?? null);
    });

    return () => {
      subscription.unsubscribe();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Offline queue processing ────────────────────────────────────────────

  const processQueue = useCallback(async () => {
    if (!isOnline || !isAuthenticated) return;

    const queue = getQueue();
    if (queue.length === 0) return;

    setSyncStatus('syncing');
    let allSucceeded = true;

    for (const workoutId of queue) {
      try {
        await withRetry(() => pushWorkout(workoutId));
        dequeueWorkout(workoutId);
      } catch {
        allSucceeded = false;
      }
    }

    if (allSucceeded) {
      setSyncStatus('synced');
      setLastSyncedAt(new Date());
    } else {
      setSyncStatus('error');
    }
  }, [isOnline, isAuthenticated]);

  // ── Auto-sync when coming online or authenticating ──────────────────────

  useEffect(() => {
    if (!isOnline || !isAuthenticated) {
      if (!isOnline) setSyncStatus('offline');
      return;
    }

    // Process queue then pull latest
    void (async () => {
      await processQueue();
      try {
        await pullLatest();
        setSyncStatus('synced');
        setLastSyncedAt(new Date());
      } catch {
        // Pull failure is non-fatal — local data still intact
      }
    })();
  }, [isOnline, isAuthenticated, processQueue]);

  // ── Auto-pull on tab visibility change ──────────────────────────────────

  useEffect(() => {
    function handleVisibilityChange() {
      if (document.visibilityState === 'visible' && isAuthenticated && isOnline) {
        void pullLatest().then(() => {
          setSyncStatus('synced');
          setLastSyncedAt(new Date());
        }).catch(() => {
          // Ignore pull failures on visibility change
        });
      }
    }

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [isAuthenticated, isOnline]);

  // ── Sync operations ─────────────────────────────────────────────────────

  async function syncAfterWorkout(workoutId: string) {
    if (isOnline && isAuthenticated) {
      setSyncStatus('syncing');
      try {
        await withRetry(() => pushWorkout(workoutId));
        setSyncStatus('synced');
        setLastSyncedAt(new Date());
      } catch {
        // Enqueue for later if push fails after retries
        enqueueWorkout(workoutId);
        setSyncStatus('error');
      }
    } else {
      // Offline: enqueue for when connectivity returns
      enqueueWorkout(workoutId);
      setSyncStatus('pending');
    }
  }

  async function pullFromCloud() {
    if (!isOnline || !isAuthenticated) return;
    setSyncStatus('syncing');
    try {
      await pullLatest();
      setSyncStatus('synced');
      setLastSyncedAt(new Date());
    } catch {
      setSyncStatus('error');
    }
  }

  async function uploadExistingData(): Promise<boolean> {
    if (!isOnline || !isAuthenticated) return false;
    setSyncStatus('syncing');
    try {
      await uploadAll();
      setSyncStatus('synced');
      setLastSyncedAt(new Date());
      return true;
    } catch {
      setSyncStatus('error');
      return false;
    }
  }

  async function signOut() {
    await supabase.auth.signOut();
    clearQueue();
    setAuthUser(null);
    setSyncStatus('disabled');
    setLastSyncedAt(null);
  }

  // ── Local data mutations ─────────────────────────────────────────────────

  async function updateUserProfile(updates: Partial<User>) {
    if (!user) return;
    await updateUser(user.id, updates);
    setUser(prev => prev ? { ...prev, ...updates } : null);
  }

  async function update1RM(exerciseId: string, weight: number) {
    if (!user) return;

    const new1RM: OneRepMax = {
      id: generateId(),
      userId: user.id,
      exerciseId,
      weight,
      date: new Date(),
    };

    await saveOneRepMax(new1RM);
    setOneRepMaxes(prev => [...prev, new1RM]);
  }

  async function refresh() {
    await loadUserData();
  }

  return (
    <UserContext.Provider value={{
      user,
      oneRepMaxes,
      updateUserProfile,
      update1RM,
      refresh,
      authUser,
      isAuthenticated,
      syncStatus,
      lastSyncedAt,
      isOnline,
      syncAfterWorkout,
      pullFromCloud,
      uploadExistingData,
      signOut,
    }}>
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
}

