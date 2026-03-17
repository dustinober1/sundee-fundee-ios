/**
 * AdaptationIndicator.tsx — Inline adaptation delta indicator for workout sets.
 *
 * Displays a subtle text label next to weight/rep values indicating the
 * adaptation applied (e.g., "down 10%" for 0.9, "up 5%" for 1.05).
 *
 * Props:
 *   multiplier: number  — blended adaptation multiplier (1.0 = no change)
 *   reason?: string     — tooltip/label reason text (e.g., "Luteal phase + readiness")
 *
 * Returns null when multiplier === 1.0 (no adaptation to show).
 *
 * Styling: small gray text, non-intrusive — per locked decision.
 */

import React, { useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import * as colors from '@/src/theme/colors';

// ─── Static helpers ───────────────────────────────────────────────────────────

/**
 * Format a multiplier as a human-readable delta string.
 *
 * Examples:
 *   0.9   → "down 10%"
 *   1.05  → "up 5%"
 *   1.0   → ""
 *   0.75  → "down 25%"
 */
export function formatDelta(multiplier: number): string {
  if (multiplier === 1.0) return '';
  const deltaPercent = Math.round(Math.abs(multiplier - 1.0) * 100);
  if (deltaPercent === 0) return '';
  const direction = multiplier < 1.0 ? 'down' : 'up';
  return `${direction} ${deltaPercent}%`;
}

// ─── Component ────────────────────────────────────────────────────────────────

interface AdaptationIndicatorProps {
  multiplier: number;
  reason?: string;
}

export function AdaptationIndicator({
  multiplier,
  reason,
}: AdaptationIndicatorProps): React.JSX.Element | null {
  const [showReason, setShowReason] = useState(false);

  const deltaText = formatDelta(multiplier);
  if (deltaText === '') {
    return null;
  }

  return (
    <View style={styles.container} testID="adaptation-indicator">
      <TouchableOpacity
        onPress={() => setShowReason((prev) => !prev)}
        activeOpacity={0.7}
        hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
      >
        <Text style={styles.deltaText} testID="adaptation-delta-text">
          {deltaText}
        </Text>
      </TouchableOpacity>
      {showReason && reason != null && reason.length > 0 && (
        <View style={styles.tooltip} testID="adaptation-tooltip">
          <Text style={styles.tooltipText}>{reason}</Text>
        </View>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    position: 'relative',
  },
  deltaText: {
    fontSize: 11,
    color: colors.GREY,
    fontWeight: '400',
    letterSpacing: 0.2,
  },
  tooltip: {
    position: 'absolute',
    bottom: 20,
    left: 0,
    backgroundColor: colors.NAVY,
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 5,
    minWidth: 140,
    zIndex: 100,
  },
  tooltipText: {
    fontSize: 11,
    color: colors.CREAM,
    lineHeight: 15,
  },
});
