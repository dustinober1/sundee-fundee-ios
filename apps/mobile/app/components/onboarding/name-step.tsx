import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { TextInput } from 'react-native-paper';
import { Colors, Spacing, Typography } from '@/constants';

interface NameStepProps {
  value: string;
  onChange: (name: string) => void;
  error?: string;
}

export function NameStep({ value, onChange, error }: NameStepProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>What's your name?</Text>
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder="Enter your name"
        mode="outlined"
        style={styles.input}
        error={!!error}
      />
      {error && <Text style={styles.error}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
  label: {
    ...Typography.body,
    marginBottom: Spacing.sm,
    color: Colors.text.primary,
  },
  input: {
    backgroundColor: Colors.surface,
  },
  error: {
    ...Typography.small,
    color: Colors.error,
    marginTop: Spacing.xs,
  },
});
