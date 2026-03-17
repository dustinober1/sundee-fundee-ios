/**
 * step-experience.tsx — Onboarding Step 2: Select experience level.
 *
 * 3 option cards: Beginner, Intermediate, Advanced.
 * Next disabled until selection made. Back navigates to step-name.
 */
import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { router } from 'expo-router';
import { useOnboarding } from '@/src/onboarding/OnboardingContext';
import { getNextStep, getTotalSteps, getPreviousStep } from '@/src/onboarding/useOnboardingFlow';
import type { ExperienceLevel } from '@/src/repositories/OnboardingProfileRepo';
import {
  CREAM,
  NAVY,
  ORANGE,
  CREAM_LIGHT,
  GREY_LIGHT,
  GREY,
  ORANGE_LIGHT,
  ORANGE_DARK,
} from '@/src/theme/colors';

const STEP_NAME = 'step-experience';
const STEP_NUMBER = 2;

interface Option {
  value: ExperienceLevel;
  label: string;
  description: string;
}

const OPTIONS: Option[] = [
  {
    value: 'beginner',
    label: 'Beginner',
    description: 'New to strength training',
  },
  {
    value: 'intermediate',
    label: 'Intermediate',
    description: '1-3 years of training',
  },
  {
    value: 'advanced',
    label: 'Advanced',
    description: '3+ years of training',
  },
];

export default function StepExperience(): React.JSX.Element {
  const { draft, setExperienceLevel } = useOnboarding();
  const totalSteps = getTotalSteps(draft.gender);
  const canProceed = draft.experienceLevel !== null;

  function handleSelect(value: ExperienceLevel): void {
    setExperienceLevel(value);
  }

  function handleNext(): void {
    if (!canProceed) return;
    const nextStep = getNextStep(STEP_NAME, draft);
    if (nextStep) {
      router.push(`/(onboarding)/${nextStep}` as never);
    }
  }

  function handleBack(): void {
    const prev = getPreviousStep(STEP_NAME);
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
        <Text style={styles.title}>What is your training experience?</Text>
        <Text style={styles.subtitle}>
          We will calibrate your workout intensity to your level.
        </Text>

        {OPTIONS.map((option) => {
          const selected = draft.experienceLevel === option.value;
          return (
            <TouchableOpacity
              key={option.value}
              style={[styles.card, selected && styles.cardSelected]}
              onPress={() => handleSelect(option.value)}
              accessibilityRole="radio"
              accessibilityState={{ selected }}
              accessibilityLabel={option.label}
            >
              <Text style={[styles.cardLabel, selected && styles.cardLabelSelected]}>
                {option.label}
              </Text>
              <Text style={[styles.cardDescription, selected && styles.cardDescriptionSelected]}>
                {option.description}
              </Text>
            </TouchableOpacity>
          );
        })}
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
    marginBottom: 32,
    lineHeight: 24,
  },
  card: {
    backgroundColor: CREAM_LIGHT,
    borderWidth: 2,
    borderColor: GREY_LIGHT,
    borderRadius: 12,
    padding: 20,
    marginBottom: 12,
  },
  cardSelected: {
    backgroundColor: ORANGE_LIGHT,
    borderColor: ORANGE,
  },
  cardLabel: {
    fontSize: 18,
    fontWeight: '700',
    color: NAVY,
    marginBottom: 4,
  },
  cardLabelSelected: {
    color: ORANGE_DARK,
  },
  cardDescription: {
    fontSize: 14,
    color: NAVY,
    opacity: 0.7,
  },
  cardDescriptionSelected: {
    color: NAVY,
    opacity: 1,
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
