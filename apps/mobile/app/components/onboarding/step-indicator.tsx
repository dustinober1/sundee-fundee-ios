import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors, Spacing, Typography } from '@/constants';

interface StepIndicatorProps {
  currentStep: number;
  totalSteps: number;
}

export function StepIndicator({ currentStep, totalSteps }: StepIndicatorProps) {
  return (
    <View style={styles.container}>
      <View style={styles.dots}>
        {Array.from({ length: totalSteps }).map((_, index) => (
          <View
            key={index}
            style={[
              styles.dot,
              index === currentStep - 1 && styles.dotActive,
            ]}
          />
        ))}
      </View>
      <Text style={styles.label}>Step {currentStep} of {totalSteps}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    marginBottom: Spacing.lg,
  },
  dots: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginBottom: Spacing.xs,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.text.disabled,
  },
  dotActive: {
    backgroundColor: Colors.primary,
    width: 24,
  },
  label: {
    ...Typography.caption,
    color: Colors.text.secondary,
  },
});
