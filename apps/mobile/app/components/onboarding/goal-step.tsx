import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { RadioButton } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';
import type { PrimaryGoal } from '@/types';

interface GoalStepProps {
  value: PrimaryGoal;
  onChange: (goal: PrimaryGoal) => void;
}

const OPTIONS = [
  { value: 'strength' as PrimaryGoal, label: 'Build Strength' },
  { value: 'hypertrophy' as PrimaryGoal, label: 'Build Muscle' },
  { value: 'endurance' as PrimaryGoal, label: 'Improve Endurance' },
];

export function GoalStep({ value, onChange }: GoalStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>What do you want to achieve?</Text>
      <RadioButton.Group
        onValueChange={(value) => onChange(value as PrimaryGoal)}
        value={value}
      >
        {OPTIONS.map((option) => (
          <View key={option.value} style={styles.option}>
            <RadioButton value={option.value} />
            <Text style={styles.optionLabel}>{option.label}</Text>
          </View>
        ))}
      </RadioButton.Group>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    ...Typography.body,
    marginBottom: Spacing.md,
    color: Colors.text.primary,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  optionLabel: {
    ...Typography.body,
    marginLeft: Spacing.sm,
    color: Colors.text.primary,
  },
});
