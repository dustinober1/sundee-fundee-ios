/**
 * NotificationPermissionModal — Art Deco pre-permission modal shown after
 * the user's first workout completion.
 *
 * Deferred permission pattern: user sees value proposition first,
 * then the OS dialog fires only when they tap "Enable".
 *
 * Props:
 *   - visible: whether the modal is currently shown
 *   - onEnable: called when the user taps "Enable" — caller fires OS dialog
 *   - onDismiss: called when the user taps "Not Now" — caller sets AsyncStorage flag
 */

import React from 'react';
import {
  Modal,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
} from 'react-native';
import {
  CREAM,
  NAVY,
  ORANGE,
  GREY,
} from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface NotificationPermissionModalProps {
  visible: boolean;
  onEnable: () => void;
  onDismiss: () => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function NotificationPermissionModal({
  visible,
  onEnable,
  onDismiss,
}: NotificationPermissionModalProps): React.JSX.Element {
  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      statusBarTranslucent
    >
      <View style={styles.overlay}>
        <View style={styles.card}>
          {/* Art Deco accent line */}
          <View style={styles.accentLine} />

          {/* Icon */}
          <Text style={styles.icon}>🔔</Text>

          {/* Title */}
          <Text style={styles.title}>Stay on Track</Text>

          {/* Body */}
          <Text style={styles.body}>
            Get notified when your rest timer ends, receive daily training
            reminders timed to your cycle, and never miss a new WOD drop.
          </Text>

          {/* Feature list */}
          <View style={styles.featureList}>
            <FeatureRow label="Rest timer alerts" />
            <FeatureRow label="Daily workout reminders" />
            <FeatureRow label="WOD availability drops" />
          </View>

          {/* Primary action */}
          <TouchableOpacity
            style={styles.enableButton}
            onPress={onEnable}
            accessibilityRole="button"
            accessibilityLabel="Enable notifications"
          >
            <Text style={styles.enableButtonText}>Enable</Text>
          </TouchableOpacity>

          {/* Secondary action */}
          <TouchableOpacity
            style={styles.notNowButton}
            onPress={onDismiss}
            accessibilityRole="button"
            accessibilityLabel="Not now, dismiss notifications prompt"
          >
            <Text style={styles.notNowButtonText}>Not Now</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

// ─── Feature row ──────────────────────────────────────────────────────────────

function FeatureRow({ label }: { label: string }): React.JSX.Element {
  return (
    <View style={styles.featureRow}>
      <Text style={styles.featureBullet}>•</Text>
      <Text style={styles.featureLabel}>{label}</Text>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(13, 26, 64, 0.6)', // Navy translucent backdrop
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  card: {
    backgroundColor: CREAM,
    borderRadius: 4,
    paddingHorizontal: 28,
    paddingTop: 0,
    paddingBottom: 28,
    width: '100%',
    maxWidth: 360,
    alignItems: 'center',
    shadowColor: NAVY,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.25,
    shadowRadius: 12,
    elevation: 8,
  },
  accentLine: {
    height: 4,
    backgroundColor: ORANGE,
    width: '100%',
    borderRadius: 2,
    marginBottom: 24,
    alignSelf: 'stretch',
  },
  icon: {
    fontSize: 36,
    marginBottom: 12,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: NAVY,
    letterSpacing: 0.5,
    marginBottom: 12,
    textAlign: 'center',
  },
  body: {
    fontSize: 14,
    color: GREY,
    lineHeight: 21,
    textAlign: 'center',
    marginBottom: 20,
  },
  featureList: {
    width: '100%',
    marginBottom: 24,
    gap: 6,
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
  },
  featureBullet: {
    fontSize: 14,
    color: ORANGE,
    fontWeight: '700',
    lineHeight: 20,
  },
  featureLabel: {
    fontSize: 14,
    color: NAVY,
    lineHeight: 20,
  },
  enableButton: {
    backgroundColor: ORANGE,
    borderRadius: 8,
    paddingVertical: 14,
    paddingHorizontal: 32,
    width: '100%',
    alignItems: 'center',
    marginBottom: 12,
  },
  enableButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: CREAM,
    letterSpacing: 0.3,
  },
  notNowButton: {
    paddingVertical: 10,
    paddingHorizontal: 16,
    alignItems: 'center',
  },
  notNowButtonText: {
    fontSize: 14,
    color: GREY,
    fontWeight: '500',
  },
});
