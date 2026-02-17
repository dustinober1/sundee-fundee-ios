import React, { useState } from 'react';
import { View, Text, ScrollView, StyleSheet, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Button } from '@/components/ui/button';
import { StepIndicator } from './components/onboarding/step-indicator';
import { NameStep } from './components/onboarding/name-step';
import { ExperienceStep } from './components/onboarding/experience-step';
import { GoalStep } from './components/onboarding/goal-step';
import { useUser } from '@/contexts/user-context';
import { createUser } from '@/lib/storage/database';
import { Colors, Spacing, Typography } from '@/constants';
import type { ExperienceLevel, PrimaryGoal } from '@/types';

interface OnboardingData {
  name: string;
  experienceLevel: ExperienceLevel;
  primaryGoal: PrimaryGoal;
}

export default function OnboardingScreen() {
  const router = useRouter();
  const { refresh } = useUser();
  const [currentStep, setCurrentStep] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [data, setData] = useState<OnboardingData>({
    name: '',
    experienceLevel: 'beginner',
    primaryGoal: 'strength',
  });
  const [errors, setErrors] = useState<{ [key: string]: string }>({});

  const totalSteps = 3;

  function validateStep(step: number): boolean {
    const newErrors: { [key: string]: string } = {};

    if (step === 1 && !data.name.trim()) {
      newErrors.name = 'Please enter your name';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }

  async function handleNext() {
    if (!validateStep(currentStep)) {
      return;
    }

    if (currentStep < totalSteps) {
      setCurrentStep(currentStep + 1);
    } else {
      await handleComplete();
    }
  }

  function handleBack() {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  }

  async function handleComplete() {
    setIsLoading(true);
    try {
      await createUser({
        name: data.name,
        experienceLevel: data.experienceLevel,
        primaryGoal: data.primaryGoal,
      });
      await refresh();
      router.push('/dashboard');
    } catch (error) {
      setIsLoading(false);
      Alert.alert('Error', "Couldn't create profile. Please try again.");
    }
  }

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        <StepIndicator currentStep={currentStep} totalSteps={totalSteps} />

        {currentStep === 1 && (
          <>
            <Text style={styles.heading}>Welcome to Strength 💪</Text>
            <Text style={styles.subheading}>Let's get to know you</Text>
            <NameStep
              value={data.name}
              onChange={(name) => setData({ ...data, name })}
              error={errors.name}
            />
          </>
        )}

        {currentStep === 2 && (
          <>
            <Text style={styles.heading}>Training Experience</Text>
            <Text style={styles.subheading}>How long have you been lifting?</Text>
            <ExperienceStep
              value={data.experienceLevel}
              onChange={(experienceLevel) => setData({ ...data, experienceLevel })}
            />
          </>
        )}

        {currentStep === 3 && (
          <>
            <Text style={styles.heading}>Your Goals</Text>
            <Text style={styles.subheading}>What do you want to achieve?</Text>
            <GoalStep
              value={data.primaryGoal}
              onChange={(primaryGoal) => setData({ ...data, primaryGoal })}
            />
          </>
        )}
      </ScrollView>

      <View style={styles.footer}>
        {currentStep > 1 && (
          <Button
            mode="outlined"
            onPress={handleBack}
            style={styles.backButton}
          >
            Back
          </Button>
        )}

        <Button
          mode="contained"
          onPress={handleNext}
          disabled={isLoading}
          style={styles.nextButton}
        >
          {isLoading ? (
            <ActivityIndicator color="#fff" />
          ) : currentStep === 3 ? (
            'Get Started'
          ) : (
            'Next'
          )}
        </Button>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scrollContent: {
    flexGrow: 1,
    padding: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  heading: {
    ...Typography.headingLarge,
    marginBottom: Spacing.xs,
    color: Colors.text.primary,
  },
  subheading: {
    ...Typography.body,
    marginBottom: Spacing.lg,
    color: Colors.text.secondary,
  },
  footer: {
    flexDirection: 'row',
    padding: Spacing.lg,
    gap: Spacing.md,
    backgroundColor: Colors.background,
  },
  backButton: {
    flex: 1,
  },
  nextButton: {
    flex: 2,
  },
});
