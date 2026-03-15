/**
 * PRToast — top-of-screen PR celebration banner.
 *
 * Appears from top of screen, auto-dismisses after 3 seconds.
 * ORANGE background, CREAM text. Uses expo-haptics for celebration feedback.
 */

import React, { useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Animated,
} from 'react-native';
import * as Haptics from 'expo-haptics';
import type { PRCheckResult } from '../../domain/pr-detection/pr-types';
import {
  ORANGE,
  ORANGE_DARK,
  CREAM,
} from '../../theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface PRToastProps {
  pr: PRCheckResult & { exerciseName: string };
  onDismiss: () => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function PRToast({ pr, onDismiss }: PRToastProps): React.JSX.Element {
  const slideAnim = useRef(new Animated.Value(-100)).current;

  useEffect(() => {
    // Haptic feedback on show
    void Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);

    // Slide in
    Animated.spring(slideAnim, {
      toValue: 0,
      useNativeDriver: true,
      tension: 80,
      friction: 8,
    }).start();

    // Auto-dismiss after 3 seconds
    const timer = setTimeout(() => {
      Animated.timing(slideAnim, {
        toValue: -120,
        duration: 300,
        useNativeDriver: true,
      }).start(() => {
        onDismiss();
      });
    }, 3000);

    return () => {
      clearTimeout(timer);
    };
  }, [slideAnim, onDismiss]);

  const buildMessage = (): { title: string; subtitle: string } => {
    if (pr.is1RMPR && !pr.isWeightPR) {
      return {
        title: 'New est. 1RM PR!',
        subtitle: `${pr.exerciseName} — ${pr.newValue} lbs`,
      };
    }
    const rangeLabel = pr.repRange !== null ? ` @ ${pr.repRange} rep max` : '';
    return {
      title: 'New PR!',
      subtitle: `${pr.exerciseName} — ${pr.newValue} lbs${rangeLabel}`,
    };
  };

  const { title, subtitle } = buildMessage();

  return (
    <Animated.View
      style={[styles.container, { transform: [{ translateY: slideAnim }] }]}
      accessibilityRole="alert"
      accessibilityLabel={`${title} ${subtitle}`}
      accessibilityLiveRegion="assertive"
    >
      <View style={styles.content}>
        <Text style={styles.emoji}>🏆</Text>
        <View style={styles.textContainer}>
          <Text style={styles.title}>{title}</Text>
          <Text style={styles.subtitle}>{subtitle}</Text>
        </View>
      </View>
    </Animated.View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 100,
    backgroundColor: ORANGE,
    borderBottomWidth: 3,
    borderBottomColor: ORANGE_DARK,
    shadowColor: ORANGE_DARK,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 10,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 14,
    paddingTop: 50, // account for status bar
    gap: 12,
  },
  emoji: {
    fontSize: 28,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontSize: 16,
    fontWeight: '800',
    color: CREAM,
    letterSpacing: 0.3,
  },
  subtitle: {
    fontSize: 14,
    color: CREAM,
    opacity: 0.9,
    marginTop: 1,
  },
});
