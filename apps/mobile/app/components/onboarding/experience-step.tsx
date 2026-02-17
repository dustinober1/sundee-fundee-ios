import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { RadioButton } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';
import type { ExperienceLevel } from '@/types';

interface ExperienceStepProps {
  value: ExperienceLevel;
  onChange: (level: ExperienceLevel) => void;
}

const OPTIONS = [
  { value: 'beginner' as ExperienceLevel, label: '0-1 years (Beginner)' },
  { value: 'intermediate' as ExperienceLevel, label: '1-3 years (Intermediate)' },
  { value: 'advanced' as ExperienceLevel, label: '3+ years (Advanced)' },
];

export function ExperienceStep({ value, onChange }: ExperienceStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Training experience</Text>
      <RadioButton.Group
        onValueChange={(value) => onChange(value as ExperienceLevel)}
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
