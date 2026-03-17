/**
 * app/(app)/(tabs)/_layout.tsx — Tab bar layout.
 *
 * Tabs: Dashboard, History, Maxes, Cycle (conditional), Settings.
 *
 * Cycle tab is hidden for users who did not opt into cycle tracking.
 * Uses `href: null` pattern from Expo Router to conditionally hide tabs.
 * Loads the user's onboarding profile to check cycleOptIn flag.
 *
 * Styling: NAVY background, ORANGE active tint, CREAM inactive tint.
 * Icons: text/emoji placeholders — proper icons added in Phase 3+ (UI phase).
 */

import React, { useEffect, useState } from 'react';
import { Text } from 'react-native';
import { Tabs } from 'expo-router';
import * as colors from '@/src/theme/colors';
import { useSession } from '@/src/auth/AuthContext';
import {
  getOnboardingProfileRepo,
  type OnboardingProfile,
} from '@/src/repositories/OnboardingProfileRepo';

function TabIcon({ symbol, focused }: { symbol: string; focused: boolean }): React.JSX.Element {
  return (
    <Text style={{ fontSize: 20, opacity: focused ? 1 : 0.6 }}>{symbol}</Text>
  );
}

export default function TabLayout(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const [profile, setProfile] = useState<OnboardingProfile | null>(null);

  // Load user's onboarding profile to check cycle opt-in
  useEffect(() => {
    if (!user) return;
    const loadProfile = async (): Promise<void> => {
      try {
        const repo = getOnboardingProfileRepo(isGuest);
        const p = await repo.getProfile(user.uid);
        setProfile(p);
      } catch {
        setProfile(null);
      }
    };
    void loadProfile();
  }, [user, isGuest]);

  // Cycle tab is shown only for users who opted in
  const cycleTabHref = profile?.cycleOptIn === true ? undefined : null;

  return (
    <Tabs
      screenOptions={{
        tabBarStyle: {
          backgroundColor: colors.NAVY,
          borderTopColor: colors.NAVY_DARK,
        },
        tabBarActiveTintColor: colors.ORANGE,
        tabBarInactiveTintColor: colors.CREAM,
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '500',
          letterSpacing: 0.3,
        },
        headerStyle: {
          backgroundColor: colors.NAVY,
        },
        headerTintColor: colors.CREAM,
        headerTitleStyle: {
          fontWeight: '700',
          letterSpacing: 0.5,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Dashboard',
          tabBarIcon: ({ focused }) => (
            <TabIcon symbol="🏋️" focused={focused} />
          ),
          headerTitle: 'Sundee Fundee',
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: 'History',
          tabBarIcon: ({ focused }) => (
            <TabIcon symbol="📋" focused={focused} />
          ),
          headerTitle: 'Workout History',
        }}
      />
      <Tabs.Screen
        name="maxes"
        options={{
          title: 'Maxes',
          tabBarIcon: ({ focused }) => (
            <TabIcon symbol="🏆" focused={focused} />
          ),
          headerTitle: 'Personal Records',
        }}
      />
      <Tabs.Screen
        name="cycle"
        options={{
          title: 'Cycle',
          href: cycleTabHref,
          tabBarIcon: ({ focused }) => (
            <TabIcon symbol="🌙" focused={focused} />
          ),
          headerTitle: 'Cycle Tracking',
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ focused }) => (
            <TabIcon symbol="⚙️" focused={focused} />
          ),
          headerTitle: 'Settings',
        }}
      />
    </Tabs>
  );
}
