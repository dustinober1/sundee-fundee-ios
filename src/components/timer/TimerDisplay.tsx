/**
 * TimerDisplay — Large prominent timer display for all three timer modes.
 *
 * ForTime: shows elapsed time counting up (MM:SS)
 * AMRAP: shows remaining time counting down (MM:SS), orange tint when < 30s
 * EMOM: shows current minute number prominently, remaining time in minute below
 */

import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { TimerMode } from '../../domain/timers/timer-state';
import {
  CREAM,
  NAVY,
  NAVY_DARK,
  ORANGE,
  ORANGE_DARK,
  ORANGE_LIGHT,
} from '../../theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

interface TimerDisplayProps {
  mode: TimerMode;
  displayTime: string;
  currentMinute?: number;
  totalMinutes?: number;
  remainingInMinute?: string;
  isUrgent?: boolean;
}

// ─── Mode labels ──────────────────────────────────────────────────────────────

const MODE_LABELS: Record<TimerMode, string> = {
  forTime: 'FOR TIME',
  amrap: 'AMRAP',
  emom: 'EMOM',
  rest: 'REST',
};

// ─── Component ────────────────────────────────────────────────────────────────

export function TimerDisplay({
  mode,
  displayTime,
  currentMinute = 1,
  totalMinutes,
  remainingInMinute,
  isUrgent = false,
}: TimerDisplayProps): React.JSX.Element {
  const modeLabel = MODE_LABELS[mode];
  const urgentBackground = isUrgent ? ORANGE_LIGHT : NAVY;
  const urgentTimeColor = isUrgent ? ORANGE_DARK : CREAM;

  if (mode === 'emom') {
    return (
      <View style={[styles.container, { backgroundColor: NAVY }]}>
        <Text style={styles.modeLabel}>{modeLabel}</Text>

        <View style={styles.emomMinuteRow}>
          <Text style={styles.emomMinuteNumber}>{currentMinute}</Text>
          {totalMinutes !== undefined && (
            <Text style={styles.emomMinuteDivider}>/{totalMinutes}</Text>
          )}
        </View>
        <Text style={styles.emomMinuteLabel}>MINUTE</Text>

        {remainingInMinute !== undefined && (
          <Text style={styles.emomRemainingTime}>{remainingInMinute}</Text>
        )}
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: urgentBackground }]}>
      <Text style={styles.modeLabel}>{modeLabel}</Text>
      <Text style={[styles.timeDisplay, { color: urgentTimeColor }]}>{displayTime}</Text>
      {mode === 'amrap' && isUrgent && (
        <Text style={styles.urgentText}>FINISH!</Text>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 32,
    paddingHorizontal: 24,
    backgroundColor: NAVY,
    borderRadius: 16,
  },
  modeLabel: {
    fontSize: 14,
    fontWeight: '700',
    letterSpacing: 4,
    color: ORANGE,
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  timeDisplay: {
    fontSize: 72,
    fontWeight: '700',
    letterSpacing: 2,
    color: CREAM,
    fontVariant: ['tabular-nums'],
  },
  urgentText: {
    fontSize: 18,
    fontWeight: '700',
    letterSpacing: 3,
    color: ORANGE_DARK,
    marginTop: 8,
  },
  // EMOM-specific styles
  emomMinuteRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
  },
  emomMinuteNumber: {
    fontSize: 80,
    fontWeight: '700',
    color: ORANGE,
    lineHeight: 88,
    fontVariant: ['tabular-nums'],
  },
  emomMinuteDivider: {
    fontSize: 36,
    fontWeight: '500',
    color: CREAM,
    marginBottom: 12,
    marginLeft: 4,
  },
  emomMinuteLabel: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 4,
    color: CREAM,
    opacity: 0.6,
    marginTop: -4,
    marginBottom: 12,
  },
  emomRemainingTime: {
    fontSize: 40,
    fontWeight: '500',
    color: CREAM,
    letterSpacing: 2,
    fontVariant: ['tabular-nums'],
  },
});

export default TimerDisplay;
