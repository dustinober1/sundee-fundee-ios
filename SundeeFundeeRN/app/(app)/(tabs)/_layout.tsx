/**
 * app/(app)/(tabs)/_layout.tsx — Tab bar layout.
 *
 * Phase 1 tabs: Dashboard (index) and Settings.
 * Additional tabs will be added in subsequent phases.
 *
 * Styling: NAVY background, ORANGE active tint, CREAM inactive tint.
 * Icons: text/emoji placeholders — proper icons added in Phase 3+ (UI phase).
 */

import { Tabs } from 'expo-router';
import { Text } from 'react-native';
import * as colors from '@/src/theme/colors';

function TabIcon({ symbol, focused }: { symbol: string; focused: boolean }): React.JSX.Element {
  return (
    <Text style={{ fontSize: 20, opacity: focused ? 1 : 0.6 }}>{symbol}</Text>
  );
}

export default function TabLayout(): React.JSX.Element {
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
