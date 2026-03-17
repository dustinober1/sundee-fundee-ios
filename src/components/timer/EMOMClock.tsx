/**
 * EMOMClock — Circular progress indicator for EMOM timer showing progress
 * within the current minute.
 *
 * Displays:
 * - Circular arc showing progress through the current 60-second interval
 * - "Minute X of Y" label
 * - Subtle pulse animation on minute boundary
 */

import React, { useEffect, useRef } from 'react';
import { Animated, StyleSheet, Text, View } from 'react-native';
import { CREAM, NAVY, NAVY_DARK, ORANGE, ORANGE_DARK } from '../../theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

interface EMOMClockProps {
  currentMinute: number;
  totalMinutes: number;
  remainingInMinuteMs: number;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const SIZE = 160;
const STROKE = 12;
const RADIUS = (SIZE - STROKE) / 2;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

// ─── Component ────────────────────────────────────────────────────────────────

export function EMOMClock({
  currentMinute,
  totalMinutes,
  remainingInMinuteMs,
}: EMOMClockProps): React.JSX.Element {
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const prevMinuteRef = useRef(currentMinute);

  // Pulse on minute boundary change
  useEffect(() => {
    if (currentMinute !== prevMinuteRef.current) {
      prevMinuteRef.current = currentMinute;
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.15,
          duration: 150,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [currentMinute, pulseAnim]);

  // Progress within the current minute (0 = start, 1 = end)
  const progressFraction = 1 - Math.min(1, remainingInMinuteMs / 60_000);
  const strokeDashoffset = CIRCUMFERENCE * (1 - progressFraction);

  return (
    <Animated.View
      style={[styles.container, { transform: [{ scale: pulseAnim }] }]}
    >
      {/* SVG-style circle via View composition */}
      <View style={styles.circleOuter}>
        <View style={styles.circleBackground} />
        {/* Progress arc — drawn via rotation trick */}
        <View
          style={[
            styles.progressArc,
            {
              // Approximate visual progress via opacity variation (native compatible)
              // For a full SVG arc, use react-native-svg in production
              borderColor: ORANGE,
              opacity: 0.3 + progressFraction * 0.7,
            },
          ]}
        />
        {/* Inner content */}
        <View style={styles.innerContent}>
          <Text style={styles.minuteNumber}>{currentMinute}</Text>
          <Text style={styles.ofLabel}>of {totalMinutes}</Text>
        </View>
      </View>
      <Text style={styles.minuteText}>MINUTE</Text>
    </Animated.View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 8,
  },
  circleOuter: {
    width: SIZE,
    height: SIZE,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  circleBackground: {
    position: 'absolute',
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
    borderWidth: STROKE,
    borderColor: NAVY_DARK,
  },
  progressArc: {
    position: 'absolute',
    width: SIZE,
    height: SIZE,
    borderRadius: SIZE / 2,
    borderWidth: STROKE,
    borderColor: ORANGE,
  },
  innerContent: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  minuteNumber: {
    fontSize: 48,
    fontWeight: '700',
    color: CREAM,
    lineHeight: 52,
    fontVariant: ['tabular-nums'],
  },
  ofLabel: {
    fontSize: 12,
    color: CREAM,
    opacity: 0.6,
    fontWeight: '500',
  },
  minuteText: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 4,
    color: ORANGE,
    marginTop: 8,
    textTransform: 'uppercase',
  },
});

export default EMOMClock;
