/**
 * step-name.tsx — Onboarding Step 1: Enter your name.
 *
 * Art Deco styling (cream background, navy text, orange accents).
 * Next button disabled until name is non-empty.
 * No Back button (first step).
 */
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { router } from 'expo-router';
import { useOnboarding } from '@/src/onboarding/OnboardingContext';
import { getNextStep, getTotalSteps } from '@/src/onboarding/useOnboardingFlow';
import {
  CREAM,
  NAVY,
  ORANGE,
  GREY_LIGHT,
  GREY,
  ORANGE_DARK,
} from '@/src/theme/colors';

const STEP_NAME = 'step-name';
const STEP_NUMBER = 1;

export default function StepName(): React.JSX.Element {
  const { draft, setName } = useOnboarding();
  const [localName, setLocalName] = useState(draft.name);

  const totalSteps = getTotalSteps(draft.gender);
  const canProceed = localName.trim().length > 0;

  function handleNext(): void {
    const trimmed = localName.trim();
    setName(trimmed);
    const nextStep = getNextStep(STEP_NAME, { ...draft, name: trimmed });
    if (nextStep) {
      router.push(`/(onboarding)/${nextStep}` as never);
    }
  }

  return (
    <KeyboardAvoidingView
      style={styles.flex}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.container}
        keyboardShouldPersistTaps="handled"
      >
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
          <Text style={styles.title}>What should we call you?</Text>
          <Text style={styles.subtitle}>
            This is how your workouts will be personalized.
          </Text>

          <TextInput
            style={styles.input}
            value={localName}
            onChangeText={setLocalName}
            placeholder="Your name"
            placeholderTextColor={GREY}
            autoFocus
            returnKeyType="next"
            onSubmitEditing={canProceed ? handleNext : undefined}
            maxLength={50}
          />
        </View>

        {/* Navigation */}
        <View style={styles.navRow}>
          <TouchableOpacity
            style={[styles.nextButton, !canProceed && styles.nextButtonDisabled]}
            onPress={handleNext}
            disabled={!canProceed}
            accessibilityRole="button"
            accessibilityLabel="Next"
            accessibilityState={{ disabled: !canProceed }}
          >
            <Text style={[styles.nextButtonText, !canProceed && styles.nextButtonTextDisabled]}>
              Next
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
    backgroundColor: CREAM,
  },
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
    marginBottom: 32,
    lineHeight: 24,
  },
  input: {
    borderWidth: 2,
    borderColor: NAVY,
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 18,
    color: NAVY,
    backgroundColor: CREAM,
  },
  navRow: {
    marginTop: 32,
  },
  nextButton: {
    backgroundColor: ORANGE,
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
  },
  nextButtonDisabled: {
    backgroundColor: GREY_LIGHT,
  },
  nextButtonText: {
    color: CREAM,
    fontSize: 17,
    fontWeight: '700',
    letterSpacing: 0.5,
  },
  nextButtonTextDisabled: {
    color: GREY,
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
