/**
 * RestTimerBar — fixed bottom bar showing rest timer countdown with skip button.
 *
 * Art Deco styling: NAVY background, CREAM text, ORANGE progress bar.
 * Slides up when timer active, hidden when not.
 */

import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Animated,
} from 'react-native';
import {
  NAVY,
  NAVY_DARK,
  CREAM,
  ORANGE,
  GREY,
} from '../../theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface RestTimerBarProps {
  isActive: boolean;
  remainingSeconds: number;
  totalSeconds: number;
  onSkip: () => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function RestTimerBar({
  isActive,
  remainingSeconds,
  totalSeconds,
  onSkip,
}: RestTimerBarProps): React.JSX.Element | null {
  const slideAnim = useRef(new Animated.Value(100)).current;

  useEffect(() => {
    Animated.timing(slideAnim, {
      toValue: isActive ? 0 : 100,
      duration: 250,
      useNativeDriver: true,
    }).start();
  }, [isActive, slideAnim]);

  const progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;
  const progressPercent = Math.max(0, Math.min(1, progress)) * 100;

  const formatSeconds = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (mins > 0) {
      return `${mins}:${String(secs).padStart(2, '0')}`;
    }
    return String(secs);
  };

  if (!isActive && remainingSeconds === 0) {
    return null;
  }

  return (
    <Animated.View
      style={[
        styles.container,
        { transform: [{ translateY: slideAnim }] },
      ]}
      accessibilityRole="timer"
      accessibilityLabel={`Rest timer: ${formatSeconds(remainingSeconds)} remaining`}
    >
      {/* Progress bar */}
      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${progressPercent}%` as `${number}%` }]} />
      </View>

      {/* Content row */}
      <View style={styles.content}>
        <View style={styles.timerInfo}>
          <Text style={styles.label}>REST</Text>
          <Text style={styles.countdown}>{formatSeconds(remainingSeconds)}</Text>
        </View>

        <TouchableOpacity
          style={styles.skipButton}
          onPress={onSkip}
          accessibilityRole="button"
          accessibilityLabel="Skip rest timer"
        >
          <Text style={styles.skipText}>Skip</Text>
        </TouchableOpacity>
      </View>
    </Animated.View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: NAVY,
    borderTopWidth: 2,
    borderTopColor: ORANGE,
  },
  progressTrack: {
    height: 3,
    backgroundColor: NAVY_DARK,
  },
  progressFill: {
    height: '100%',
    backgroundColor: ORANGE,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    paddingBottom: 24, // extra bottom padding for home indicator
  },
  timerInfo: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: 12,
  },
  label: {
    fontSize: 11,
    fontWeight: '800',
    color: GREY,
    letterSpacing: 2,
  },
  countdown: {
    fontSize: 32,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: -1,
    fontVariant: ['tabular-nums'],
  },
  skipButton: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: ORANGE,
  },
  skipText: {
    fontSize: 14,
    fontWeight: '700',
    color: ORANGE,
  },
});
