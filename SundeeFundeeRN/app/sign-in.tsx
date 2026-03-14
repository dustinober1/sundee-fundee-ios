/**
 * sign-in.tsx — Auth screen.
 *
 * Per locked design decisions:
 * - Platform-adaptive: Apple button on iOS, Google button on Android/Web
 * - Stacked full-width buttons with proper ordering
 * - All buttons disabled during any auth operation (button-level spinner on tapped button)
 * - Inline error messages below failed button (NOT modals)
 * - CREAM background, NAVY text, ORANGE accent
 *
 * Sign-up mode toggle switches between "Sign In" and "Sign Up" without navigation.
 * After successful auth, onAuthStateChanged in SessionProvider triggers navigation automatically.
 */

import React, { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { Redirect, useRouter } from 'expo-router';
import { AuthButton } from '@/src/components/AuthButton';
import { OfflineBanner } from '@/src/components/OfflineBanner';
import { useSession } from '@/src/auth/AuthContext';
import { useAppleSignIn } from '@/src/auth/useAppleSignIn';
import { useGoogleSignIn } from '@/src/auth/useGoogleSignIn';
import { useEmailAuth } from '@/src/auth/useEmailAuth';
import { useGuestSignIn } from '@/src/auth/useGuestSignIn';
import * as colors from '@/src/theme/colors';

// ─── SignInScreen ─────────────────────────────────────────────────────────────

export default function SignInScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isLoading: sessionLoading } = useSession();

  // If already authenticated, redirect to the app
  if (!sessionLoading && user) {
    return <Redirect href="/(app)/(tabs)" />;
  }

  // Email form state
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUpMode, setIsSignUpMode] = useState(false);

  // Auth hooks
  const apple = useAppleSignIn();
  const google = useGoogleSignIn();
  const emailAuth = useEmailAuth();
  const guest = useGuestSignIn();

  // Global loading state — when any auth is in progress, ALL buttons are disabled
  const anyLoading =
    apple.isLoading || google.isLoading || emailAuth.isLoading || guest.isLoading;

  // ─── Handlers ───────────────────────────────────────────────────────────────

  async function handleAppleSignIn(): Promise<void> {
    try {
      await apple.signIn();
      // Navigation triggered automatically via onAuthStateChanged
    } catch {
      // Error already set in hook
    }
  }

  async function handleGoogleSignIn(): Promise<void> {
    try {
      await google.signIn();
    } catch {
      // Error already set in hook
    }
  }

  async function handleEmailAuth(): Promise<void> {
    try {
      if (isSignUpMode) {
        const result = await emailAuth.signUp(email, password);
        if (result.needsVerification) {
          router.replace('/verify-email');
        }
      } else {
        await emailAuth.signIn(email, password);
        // Navigation triggered automatically via onAuthStateChanged
      }
    } catch {
      // Error already set in hook
    }
  }

  async function handleGuestSignIn(): Promise<void> {
    try {
      await guest.signIn();
      // Navigation triggered automatically via onAuthStateChanged
    } catch {
      // Error already set in hook
    }
  }

  // ─── Render ─────────────────────────────────────────────────────────────────

  return (
    <KeyboardAvoidingView
      style={styles.keyboardAvoid}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <OfflineBanner />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator={false}
      >
        {/* Logo and tagline */}
        <View style={styles.logoContainer}>
          <View style={styles.logoPlaceholder}>
            <Text style={styles.logoText}>SF</Text>
          </View>
          <Text style={styles.appName}>Sundee Fundee</Text>
          <Text style={styles.tagline}>Strength Training, Evolved</Text>
        </View>

        {/* Auth buttons */}
        <View style={styles.authContainer}>
          {/* Platform-adaptive: Apple on iOS, Google on Android/Web */}
          {Platform.OS === 'ios' ? (
            <AuthButton
              title="Sign In with Apple"
              onPress={handleAppleSignIn}
              isLoading={apple.isLoading}
              error={apple.error}
              variant="primary"
              disabled={anyLoading && !apple.isLoading}
            />
          ) : (
            <AuthButton
              title="Sign In with Google"
              onPress={handleGoogleSignIn}
              isLoading={google.isLoading}
              error={google.error}
              variant="primary"
              disabled={anyLoading && !google.isLoading}
            />
          )}

          {/* Email section */}
          <View style={styles.divider}>
            <View style={styles.dividerLine} />
            <Text style={styles.dividerText}>or</Text>
            <View style={styles.dividerLine} />
          </View>

          <TextInput
            style={styles.input}
            placeholder="Email address"
            placeholderTextColor={colors.GREY}
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoCorrect={false}
            editable={!anyLoading}
            testID="email-input"
          />

          <TextInput
            style={styles.input}
            placeholder="Password"
            placeholderTextColor={colors.GREY}
            value={password}
            onChangeText={setPassword}
            secureTextEntry={true}
            autoCapitalize="none"
            autoCorrect={false}
            editable={!anyLoading}
            testID="password-input"
          />

          <AuthButton
            title={isSignUpMode ? 'Create Account' : 'Sign In'}
            onPress={handleEmailAuth}
            isLoading={emailAuth.isLoading}
            error={emailAuth.error}
            variant="secondary"
            disabled={anyLoading && !emailAuth.isLoading}
          />

          {/* Toggle sign-in / sign-up mode */}
          <TouchableOpacity
            onPress={() => setIsSignUpMode((prev) => !prev)}
            disabled={anyLoading}
            style={styles.toggleLink}
            testID="toggle-mode-link"
          >
            <Text style={styles.toggleText}>
              {isSignUpMode
                ? 'Already have an account? Sign In'
                : "Don't have an account? Create one"}
            </Text>
          </TouchableOpacity>

          {/* De-emphasized guest link (per locked decision) */}
          <View style={styles.guestContainer}>
            <AuthButton
              title="Continue as Guest"
              onPress={handleGuestSignIn}
              isLoading={guest.isLoading}
              error={guest.error}
              variant="text"
              disabled={anyLoading && !guest.isLoading}
            />
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  keyboardAvoid: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  scroll: {
    flex: 1,
  },
  content: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingVertical: 48,
  },
  logoContainer: {
    alignItems: 'center',
    marginBottom: 48,
  },
  logoPlaceholder: {
    width: 80,
    height: 80,
    borderRadius: 16,
    backgroundColor: colors.NAVY,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  logoText: {
    color: colors.CREAM,
    fontSize: 28,
    fontWeight: '700',
    letterSpacing: 2,
  },
  appName: {
    fontSize: 26,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 1,
    marginBottom: 8,
  },
  tagline: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.5,
    fontStyle: 'italic',
  },
  authContainer: {
    width: '100%',
    alignItems: 'center',
    gap: 12,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    marginVertical: 4,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: colors.GREY_LIGHT,
  },
  dividerText: {
    marginHorizontal: 12,
    fontSize: 13,
    color: colors.GREY,
  },
  input: {
    width: '100%',
    height: 48,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM_LIGHT,
    paddingHorizontal: 14,
    fontSize: 15,
    color: colors.NAVY,
  },
  toggleLink: {
    paddingVertical: 4,
  },
  toggleText: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    textDecorationLine: 'underline',
  },
  guestContainer: {
    width: '100%',
    marginTop: 8,
  },
});
