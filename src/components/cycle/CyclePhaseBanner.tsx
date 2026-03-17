/**
 * CyclePhaseBanner.tsx — Dashboard cycle phase banner.
 *
 * Displays the current cycle phase and training recommendation.
 * Returns null when cycleStatus is null (graceful hide for non-logged users).
 *
 * Props:
 *   cycleStatus  — Current cycle status from calculateCycleStatus(), or null
 *   onPress      — Optional callback when banner is tapped (navigates to Cycle tab)
 *
 * Phase colors:
 *   menstrual  — soft red   (#E57373) – warm, not clinical
 *   follicular — green      (#81C784) – growth/energy
 *   ovulation  — amber      (#FFB74D) – peak/warmth
 *   luteal     — purple     (#BA68C8) – transition/introspection
 *
 * Static helper `phaseColor(phase)` is exported for unit testing.
 */

import React from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import type { CyclePhase } from '@/src/domain/types/index';
import type { CycleStatusResult } from '@/src/domain/cycle/cycle-calculations';
import { getPhaseRecommendation } from '@/src/domain/cycle/cycle-calculations';
import * as colors from '@/src/theme/colors';

// ─── Phase Color Map ──────────────────────────────────────────────────────────

const PHASE_COLORS: Record<CyclePhase, string> = {
  menstrual: '#E57373',
  follicular: '#81C784',
  ovulation: '#FFB74D',
  luteal: '#BA68C8',
};

/**
 * Returns the display color for a given cycle phase.
 * Exported as a static helper for unit testability without rendering.
 */
export function phaseColor(phase: CyclePhase): string {
  return PHASE_COLORS[phase];
}

/**
 * Human-readable phase label (capitalized).
 */
export function phaseLabel(phase: CyclePhase): string {
  switch (phase) {
    case 'menstrual':
      return 'Menstrual';
    case 'follicular':
      return 'Follicular';
    case 'ovulation':
      return 'Ovulation';
    case 'luteal':
      return 'Luteal';
  }
}

// ─── Component ────────────────────────────────────────────────────────────────

interface CyclePhaseBannerProps {
  cycleStatus: CycleStatusResult | null;
  onPress?: () => void;
}

export default function CyclePhaseBanner({
  cycleStatus,
  onPress,
}: CyclePhaseBannerProps): React.JSX.Element | null {
  if (cycleStatus === null) {
    return null;
  }

  const phase = cycleStatus.currentPhase;
  const color = phaseColor(phase);
  const recommendation = getPhaseRecommendation(phase);

  const bannerContent = (
    <View style={[styles.banner, { borderLeftColor: color }]}>
      <View style={[styles.colorDot, { backgroundColor: color }]} />
      <View style={styles.textContainer}>
        <Text style={styles.phaseLabel} testID="cycle-phase-label">
          {phaseLabel(phase)} — Day {cycleStatus.cycleDay}
        </Text>
        <Text style={styles.recommendation} numberOfLines={1}>
          {recommendation.intensityRecommendation === 'peak'
            ? 'Peak performance — great time for PRs'
            : recommendation.intensityRecommendation === 'low'
              ? 'Take it easy — recovery focus today'
              : recommendation.trainingFocus}
        </Text>
      </View>
      {onPress != null && (
        <Text style={styles.chevron}>›</Text>
      )}
    </View>
  );

  if (onPress != null) {
    return (
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.8}
        testID="cycle-phase-banner"
      >
        {bannerContent}
      </TouchableOpacity>
    );
  }

  return (
    <View testID="cycle-phase-banner">
      {bannerContent}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  banner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    borderLeftWidth: 4,
    paddingVertical: 12,
    paddingHorizontal: 14,
    marginBottom: 16,
  },
  colorDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: 10,
  },
  textContainer: {
    flex: 1,
  },
  phaseLabel: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 2,
  },
  recommendation: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
    lineHeight: 16,
  },
  chevron: {
    fontSize: 20,
    color: colors.GREY,
    marginLeft: 8,
    marginTop: -1,
  },
});
