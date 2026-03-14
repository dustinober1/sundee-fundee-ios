/**
 * step-cycle.tsx — Onboarding Step 5 (final for female/other): Cycle tracking opt-in.
 *
 * Shows description of cycle-aware training benefits + a toggle switch.
 * Tapping Complete calls completeOnboarding atomically and navigates to the app.
 * Only shown for female/other users — male users are routed from step-gender directly to app.
 * Back navigates to step-gender.
 */
import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Switch,
  Alert,
} from 'react-native';
import { router } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useOnboarding } from '@/src/onboarding/OnboardingContext';
import { getTotalSteps, getPreviousStep } from '@/src/onboarding/useOnboardingFlow';
import {
  CREAM,
  NAVY,
  ORANGE,
  CREAM_LIGHT,
  GREY_LIGHT,
  GREY,
  ORANGE_DARK,
  NAVY_MEDIUM,
} from '@/src/theme/colors';

const STEP_NUMBER = 5;

export default function StepCycle(): React.JSX.Element {
  const { draft, setCycleOptIn, completeOnboarding } = useOnboarding();
  const { user, isGuest } = useSession();
  const totalSteps = getTotalSteps(draft.gender);

  async function handleComplete(): Promise<void> {
    const uid = user?.uid ?? '';
    try {
      await completeOnboarding(uid, isGuest);
      router.replace('/(app)/(tabs)' as never);
    } catch (error) {
      console.error('[StepCycle] Failed to complete onboarding:', error);
      Alert.alert(
        'Error',
        'Failed to save your profile. Please try again.',
        [{ text: 'OK' }]
      );
    }
  }

  function handleBack(): void {
    const prev = getPreviousStep('step-cycle');
    if (prev) {
      router.push(`/(onboarding)/${prev}` as never);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Progress bar */}
      <View style={styles.progressContainer}>
        <View style={styles.progressTrack}>
          <View
            style={[
              styles.progressFill,
              { width: `${(STEP_NUMBER / totalSteps) * 100}%` },
            ]}
          />
        </View>
        <Text style={styles.progressText}>
          Step {STEP_NUMBER} of {totalSteps}
        </Text>
      </View>

      {/* Content */}
      <View style={styles.content}>
        <Text style={styles.title}>Cycle-Aware Training</Text>
        <Text style={styles.subtitle}>
          Track your menstrual cycle to unlock personalized training adaptations across your cycle phases.
        </Text>

        <View style={styles.benefitsList}>
          <View style={styles.benefit}>
            <Text style={styles.benefitDot}>•</Text>
            <Text style={styles.benefitText}>
              Higher intensity in your follicular and ovulation phases when energy peaks
            </Text>
          </View>
          <View style={styles.benefit}>
            <Text style={styles.benefitDot}>•</Text>
            <Text style={styles.benefitText}>
              Lower intensity during menstrual phase when recovery takes priority
            </Text>
          </View>
          <View style={styles.benefit}>
            <Text style={styles.benefitDot}>•</Text>
            <Text style={styles.benefitText}>
              Luteal phase adaptations to match reduced performance capacity
            </Text>
          </View>
        </View>

        {/* Toggle */}
        <View style={styles.toggleRow}>
          <View style={styles.toggleLabel}>
            <Text style={styles.toggleTitle}>Enable cycle tracking</Text>
            <Text style={styles.toggleDescription}>
              You can change this at any time in Settings
            </Text>
          </View>
          <Switch
            value={draft.cycleOptIn}
            onValueChange={setCycleOptIn}
            trackColor={{ false: GREY_LIGHT, true: ORANGE }}
            thumbColor={CREAM}
            accessibilityLabel="Enable cycle tracking"
            accessibilityRole="switch"
            accessibilityState={{ checked: draft.cycleOptIn }}
          />
        </View>
      </View>

      {/* Navigation */}
      <View style={styles.navRow}>
        <TouchableOpacity
          style={styles.nextButton}
          onPress={handleComplete}
          accessibilityRole="button"
          accessibilityLabel="Complete onboarding"
        >
          <Text style={styles.nextButtonText}>Complete</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.backButton}
          onPress={handleBack}
          accessibilityRole="button"
          accessibilityLabel="Back"
        >
          <Text style={styles.backButtonText}>Back</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 40,
    backgroundColor: CREAM,
  },
  progressContainer: {
    marginBottom: 48,
  },
  progressTrack: {
    height: 4,
    backgroundColor: GREY_LIGHT,
    borderRadius: 2,
    overflow: 'hidden',
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: ORANGE,
    borderRadius: 2,
  },
  progressText: {
    fontSize: 13,
    color: GREY,
    textAlign: 'right',
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: NAVY,
    marginBottom: 12,
    letterSpacing: 0.3,
  },
  subtitle: {
    fontSize: 16,
    color: NAVY,
    opacity: 0.7,
    marginBottom: 24,
    lineHeight: 24,
  },
  benefitsList: {
    backgroundColor: CREAM_LIGHT,
    borderRadius: 12,
    padding: 20,
    marginBottom: 32,
    gap: 12,
  },
  benefit: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
  },
  benefitDot: {
    color: ORANGE,
    fontSize: 18,
    fontWeight: '700',
    lineHeight: 22,
  },
  benefitText: {
    flex: 1,
    fontSize: 15,
    color: NAVY_MEDIUM,
    lineHeight: 22,
  },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: CREAM_LIGHT,
    borderRadius: 12,
    padding: 20,
    gap: 16,
  },
  toggleLabel: {
    flex: 1,
  },
  toggleTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: NAVY,
    marginBottom: 4,
  },
  toggleDescription: {
    fontSize: 13,
    color: GREY,
  },
  navRow: {
    marginTop: 32,
  },
  nextButton: {
    backgroundColor: ORANGE,
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 12,
  },
  nextButtonText: {
    color: CREAM,
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  backButton: {
    paddingVertical: 12,
    alignItems: 'center',
  },
  backButtonText: {
    color: ORANGE_DARK,
    fontSize: 16,
    fontWeight: '600',
  },
});
