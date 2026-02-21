import React, { useState } from 'react';
import { Alert, StyleSheet, Text, TextInput, View } from 'react-native';
import ArtDecoButton from '../components/ArtDecoButton';
import ArtDecoCard from '../components/ArtDecoCard';
import { signInWithEmail, signUpWithEmail } from '../lib/supabase';
import { artDecoTheme } from '../theme/tokens';

export default function SignInScreen({
  onSignedIn,
  onBack,
}: {
  onSignedIn: () => void;
  onBack: () => void;
}) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [isSignIn, setIsSignIn] = useState(true);

  async function handleSubmit() {
    if (!email.trim() || !password.trim()) {
      Alert.alert('Missing fields', 'Please enter both email and password.');
      return;
    }

    setLoading(true);
    try {
      const res = isSignIn
        ? await signInWithEmail(email.trim(), password)
        : await signUpWithEmail(email.trim(), password);

      if (res.error) {
        Alert.alert('Authentication failed', res.error.message || 'Unknown error');
      } else {
        onSignedIn();
      }
    } catch (error) {
      Alert.alert('Authentication error', String(error));
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={styles.container}>
      <ArtDecoCard>
        <Text style={styles.title}>{isSignIn ? 'Sign in' : 'Create account'}</Text>
        <TextInput
          placeholder="Email"
          placeholderTextColor={artDecoTheme.colors.textSecondary}
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          style={styles.input}
        />
        <TextInput
          placeholder="Password"
          placeholderTextColor={artDecoTheme.colors.textSecondary}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          style={styles.input}
        />
        <ArtDecoButton
          title={
            loading
              ? isSignIn
                ? 'Signing in...'
                : 'Creating account...'
              : isSignIn
                ? 'Sign in'
                : 'Create account'
          }
          onPress={handleSubmit}
          disabled={loading}
        />
        <View style={styles.spacing} />
        <ArtDecoButton title="Back" variant="secondary" onPress={onBack} />
        <View style={styles.spacing} />
        <ArtDecoButton
          title={isSignIn ? 'Need an account? Sign up' : 'Already have an account? Sign in'}
          variant="secondary"
          onPress={() => setIsSignIn(prev => !prev)}
          disabled={loading}
        />
      </ArtDecoCard>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
    justifyContent: 'center',
    padding: artDecoTheme.spacing.md,
  },
  title: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.subtitle,
    fontWeight: '700',
    marginBottom: artDecoTheme.spacing.sm,
  },
  input: {
    borderWidth: 1,
    borderColor: artDecoTheme.colors.border,
    borderRadius: artDecoTheme.radius.sm,
    color: artDecoTheme.colors.textPrimary,
    padding: artDecoTheme.spacing.sm,
    marginBottom: artDecoTheme.spacing.sm,
    backgroundColor: artDecoTheme.colors.surfaceMuted,
  },
  spacing: {
    height: artDecoTheme.spacing.sm,
  },
});
