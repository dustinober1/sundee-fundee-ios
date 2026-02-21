import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import ArtDecoButton from '../components/ArtDecoButton';
import { artDecoTheme } from '../theme/tokens';

export default function OnboardingScreen({
  onContinue,
  onSignIn,
}: {
  onContinue: () => void;
  onSignIn?: () => void;
}) {
  return (
    <View style={styles.container}>
      <View style={styles.hero}>
        <Text style={styles.title}>Sundee-Fundee</Text>
        <Text style={styles.subtitle}>Art Deco Training Companion</Text>
        <Text style={styles.description}>
          Track workouts, cycles, and progress with an offline-first mobile flow.
        </Text>
      </View>

      <ArtDecoButton title="Get Started" onPress={onContinue} />
      {onSignIn ? (
        <View style={styles.secondaryButton}>
          <ArtDecoButton title="Sign in" variant="secondary" onPress={onSignIn} />
        </View>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
    padding: artDecoTheme.spacing.lg,
    justifyContent: 'center',
  },
  hero: {
    marginBottom: artDecoTheme.spacing.xl,
  },
  title: {
    color: artDecoTheme.colors.accent,
    fontSize: 36,
    fontWeight: '800',
    letterSpacing: 1.2,
    marginBottom: artDecoTheme.spacing.sm,
  },
  subtitle: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.subtitle,
    marginBottom: artDecoTheme.spacing.sm,
  },
  description: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.body,
    lineHeight: 22,
  },
  secondaryButton: {
    marginTop: artDecoTheme.spacing.sm,
  },
});
