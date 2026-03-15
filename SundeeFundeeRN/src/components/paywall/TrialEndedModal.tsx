/**
 * TrialEndedModal — one-time modal shown after a trial expires.
 *
 * Shown once when the app detects trial has ended and the user hasn't
 * dismissed it (AsyncStorage key: trialEndedModalShown).
 *
 * Features listed are the 4 premium features the user had during trial.
 * Two CTAs: "Subscribe Now" and "Continue with Free".
 *
 * Art Deco styling: cream/navy/orange palette consistent with PaywallModal.
 */
import React from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import * as colors from '@/src/theme/colors';

interface TrialEndedModalProps {
  visible: boolean;
  onDismiss: () => void;
  onSubscribe: () => void;
}

const TRIAL_FEATURES = [
  { icon: '🤖', name: 'AI Workouts', description: 'Personalized AI-generated training' },
  { icon: '🌙', name: 'Cycle Adaptation', description: 'Training adapted to your cycle' },
  { icon: '📋', name: 'Programs', description: 'Full structured program catalog' },
  { icon: '🩹', name: 'Injury Adaptation', description: 'Smart exercise substitutions' },
] as const;

export function TrialEndedModal({
  visible,
  onDismiss,
  onSubscribe,
}: TrialEndedModalProps): React.JSX.Element {
  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent
      onRequestClose={onDismiss}
    >
      <View style={styles.overlay}>
        <View style={styles.container}>
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.headerTitle}>Your Trial Has Ended</Text>
            <Text style={styles.headerSubtitle}>
              Your 7-day free trial is over. Subscribe to keep your premium features.
            </Text>
          </View>

          <ScrollView
            style={styles.scrollView}
            contentContainerStyle={styles.scrollContent}
            showsVerticalScrollIndicator={false}
          >
            {/* Features used during trial */}
            <Text style={styles.sectionLabel}>YOU USED DURING YOUR TRIAL</Text>
            {TRIAL_FEATURES.map((feature) => (
              <View key={feature.name} style={styles.featureRow}>
                <Text style={styles.featureIcon}>{feature.icon}</Text>
                <View style={styles.featureText}>
                  <Text style={styles.featureName}>{feature.name}</Text>
                  <Text style={styles.featureDesc}>{feature.description}</Text>
                </View>
              </View>
            ))}

            {/* Subscribe CTA */}
            <Pressable
              testID="trial-ended-subscribe-btn"
              style={styles.subscribeBtn}
              onPress={onSubscribe}
              accessibilityLabel="Subscribe Now"
            >
              <Text style={styles.subscribeBtnText}>Subscribe Now</Text>
            </Pressable>

            {/* Continue with Free */}
            <Pressable
              testID="trial-ended-continue-free-btn"
              style={styles.continueBtn}
              onPress={onDismiss}
              accessibilityLabel="Continue with Free"
            >
              <Text style={styles.continueBtnText}>Continue with Free</Text>
            </Pressable>

            <Text style={styles.finePrint}>
              Free trial auto-renews unless cancelled. Cancel anytime.
            </Text>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(13, 26, 64, 0.7)',
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: colors.CREAM,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '85%',
    overflow: 'hidden',
  },
  header: {
    backgroundColor: colors.NAVY,
    paddingHorizontal: 20,
    paddingVertical: 20,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 0.3,
    marginBottom: 6,
  },
  headerSubtitle: {
    fontSize: 14,
    color: colors.CREAM,
    opacity: 0.8,
    lineHeight: 20,
  },
  scrollView: {
    flexGrow: 0,
  },
  scrollContent: {
    padding: 20,
    paddingBottom: 32,
  },
  sectionLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1.2,
    marginBottom: 14,
    marginTop: 4,
  },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 14,
    gap: 12,
  },
  featureIcon: {
    fontSize: 20,
    width: 28,
    textAlign: 'center',
  },
  featureText: {
    flex: 1,
  },
  featureName: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  featureDesc: {
    fontSize: 13,
    color: colors.GREY,
    lineHeight: 17,
  },
  subscribeBtn: {
    backgroundColor: colors.ORANGE,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
    marginBottom: 12,
  },
  subscribeBtnText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  continueBtn: {
    paddingVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  continueBtnText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.GREY,
    letterSpacing: 0.2,
  },
  finePrint: {
    fontSize: 11,
    color: colors.GREY,
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 15,
  },
});
