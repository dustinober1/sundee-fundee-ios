'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User, OneRepMax, SyncStatus } from '@/types';
import { getUser, updateUser, getOneRepMaxesByUser, saveOneRepMax } from '@/lib/db';
import { generateId } from '@/lib/utils';

interface UserContextValue {
  user: User | null;
  oneRepMaxes: OneRepMax[];
  syncStatus: SyncStatus;
  updateUserProfile: (updates: Partial<User>) => Promise<void>;
  update1RM: (exerciseId: string, weight: number) => Promise<void>;
  refresh: () => Promise<void>;
}

const UserContext = createContext<UserContextValue | undefined>(undefined);

export function UserProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [oneRepMaxes, setOneRepMaxes] = useState<OneRepMax[]>([]);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>('offline');

  useEffect(() => {
    loadUserData();
  }, []);

  async function loadUserData() {
    const userData = await getUser();
    if (userData) {
      setUser(userData);
      const orms = await getOneRepMaxesByUser(userData.id);
      setOneRepMaxes(orms);
    }
  }

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
      date: new Date()
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
      syncStatus,
      updateUserProfile,
      update1RM,
      refresh
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
