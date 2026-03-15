/**
 * PremiumBadge — small badge/lock icon component for premium feature indicators.
 *
 * Use inline to indicate that a feature requires a Premium subscription.
 * - Default: shows lock icon + "Premium" label
 * - Compact: shows only the lock icon (for tight spaces)
 *
 * Art Deco styling: ORANGE_LIGHT background, ORANGE text.
 */
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { ORANGE, ORANGE_LIGHT } from '@/src/theme/colors';

interface PremiumBadgeProps {
  /** When true, shows only the lock icon without the "Premium" text label */
  compact?: boolean;
}

export function PremiumBadge({ compact = false }: PremiumBadgeProps): React.JSX.Element {
  return (
    <View style={[styles.badge, compact && styles.badgeCompact]}>
      <Text style={styles.icon}>🔒</Text>
      {!compact && <Text style={styles.label}>Premium</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: ORANGE_LIGHT,
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 3,
    gap: 4,
    alignSelf: 'flex-start',
  },
  badgeCompact: {
    paddingHorizontal: 5,
    paddingVertical: 3,
  },
  icon: {
    fontSize: 10,
  },
  label: {
    fontSize: 11,
    fontWeight: '600',
    color: ORANGE,
    letterSpacing: 0.3,
  },
});
