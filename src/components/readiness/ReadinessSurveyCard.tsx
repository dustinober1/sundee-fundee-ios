/**
 * ReadinessSurveyCard — dismissable dashboard card prompting the daily readiness check-in.
 *
 * Shown at the top of the dashboard when no survey has been completed today.
 * Available to ALL users (not gated on cycle tracking, per locked decision).
 * Tapping opens ReadinessSurveyModal; the X button dismisses for this session.
 */

import React from 'react';
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import * as colors from '@/src/theme/colors';

// ─── Props ───────────────────────────────────────────────────────────────────

export interface ReadinessSurveyCardProps {
  /** Called when the user taps the card body to open the survey modal. */
  onPress: () => void;
  /** Called when the user taps the X dismiss button. */
  onDismiss: () => void;
}

// ─── Static helpers (testable without mounting the view) ─────────────────────

/** Returns the primary card heading text. */
export function cardHeadingText(): string {
  return 'How are you feeling today?';
}

/** Returns the card subtext. */
export function cardSubText(): string {
  return 'Quick check-in takes 15 seconds';
}

// ─── Component ───────────────────────────────────────────────────────────────

export default function ReadinessSurveyCard({
  onPress,
  onDismiss,
}: ReadinessSurveyCardProps): React.JSX.Element {
  return (
    <TouchableOpacity
      style={styles.card}
      onPress={onPress}
      activeOpacity={0.85}
      testID="readiness-survey-card"
    >
      {/* Dismiss button */}
      <TouchableOpacity
        style={styles.dismissButton}
        onPress={onDismiss}
        hitSlop={{ top: 8, right: 8, bottom: 8, left: 8 }}
        testID="readiness-dismiss-button"
      >
        <Text style={styles.dismissText}>✕</Text>
      </TouchableOpacity>

      {/* Content */}
      <View style={styles.content}>
        <View style={styles.iconRow}>
          <View style={styles.accentBar} />
          <Text style={styles.label}>DAILY CHECK-IN</Text>
        </View>
        <Text style={styles.heading} testID="readiness-card-heading">
          {cardHeadingText()}
        </Text>
        <Text style={styles.subtext} testID="readiness-card-subtext">
          {cardSubText()}
        </Text>
        <View style={styles.ctaRow}>
          <Text style={styles.ctaText}>Start Survey</Text>
          <Text style={styles.ctaArrow}>→</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 14,
    borderWidth: 1.5,
    borderColor: colors.NAVY,
    marginBottom: 16,
    overflow: 'hidden',
  },
  dismissButton: {
    position: 'absolute',
    top: 10,
    right: 12,
    zIndex: 1,
    padding: 4,
  },
  dismissText: {
    fontSize: 14,
    color: colors.GREY,
    fontWeight: '600',
  },
  content: {
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 16,
  },
  iconRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  accentBar: {
    width: 3,
    height: 14,
    backgroundColor: colors.ORANGE,
    borderRadius: 2,
    marginRight: 8,
  },
  label: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.ORANGE,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  heading: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
    marginBottom: 4,
  },
  subtext: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    marginBottom: 14,
    lineHeight: 18,
  },
  ctaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  ctaText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.ORANGE,
    letterSpacing: 0.3,
  },
  ctaArrow: {
    fontSize: 14,
    color: colors.ORANGE,
    fontWeight: '700',
  },
});
