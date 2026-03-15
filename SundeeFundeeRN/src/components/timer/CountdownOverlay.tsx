/**
 * CountdownOverlay — Full-screen 3-2-1-Go countdown before timer starts.
 *
 * Each number is shown for 1 second with a scale animation.
 * Beep sound plays on each count; a different tone plays on "GO".
 * Blocks all interaction underneath while visible.
 */

import React, { useEffect, useRef } from 'react';
import {
  Animated,
  Modal,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { CREAM, NAVY, ORANGE } from '../../theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

interface CountdownOverlayProps {
  visible: boolean;
  countdownValue: number;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function CountdownOverlay({
  visible,
  countdownValue,
}: CountdownOverlayProps): React.JSX.Element | null {
  const scaleAnim = useRef(new Animated.Value(0.5)).current;
  const opacityAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!visible) return;

    // Reset and animate in
    scaleAnim.setValue(0.5);
    opacityAnim.setValue(0);

    Animated.parallel([
      Animated.spring(scaleAnim, {
        toValue: 1,
        useNativeDriver: true,
        speed: 20,
        bounciness: 8,
      }),
      Animated.timing(opacityAnim, {
        toValue: 1,
        duration: 150,
        useNativeDriver: true,
      }),
    ]).start();
  }, [countdownValue, visible, scaleAnim, opacityAnim]);

  if (!visible) return null;

  const isGo = countdownValue === 0;
  const displayText = isGo ? 'GO!' : String(countdownValue);
  const textColor = isGo ? CREAM : ORANGE;

  return (
    <Modal
      visible={visible}
      transparent
      animationType="none"
      statusBarTranslucent
    >
      <View style={styles.overlay}>
        <Animated.View
          style={[
            styles.numberContainer,
            {
              transform: [{ scale: scaleAnim }],
              opacity: opacityAnim,
            },
          ]}
        >
          <Text style={[styles.countdownNumber, { color: textColor }]}>
            {displayText}
          </Text>
          {isGo && (
            <Text style={styles.goSubtext}>START MOVING</Text>
          )}
        </Animated.View>
      </View>
    </Modal>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: NAVY,
    alignItems: 'center',
    justifyContent: 'center',
  },
  numberContainer: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  countdownNumber: {
    fontSize: 128,
    fontWeight: '900',
    letterSpacing: -2,
    textAlign: 'center',
  },
  goSubtext: {
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 6,
    color: ORANGE,
    marginTop: -8,
    textAlign: 'center',
  },
});

export default CountdownOverlay;
