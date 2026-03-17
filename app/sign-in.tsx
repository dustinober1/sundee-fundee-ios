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
 *
 * Guest upgrade: When the current user is anonymous, sign-up actions route through
 * guest.upgrade(credential) to preserve UID and all locally stored data.
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
import {
  getCurrentUser,
  EmailAuthProvider,
  signInWithCredential as firebaseSignIn,
} from '@/src/firebase/auth';
import * as colors from '@/src/theme/colors';

// ─── SignInScreen ─────────────────────────────────────────────────────────────

export default function SignInScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isLoading: sessionLoading } = useSession();

  // If already authenticated (non-guest), redirect to the app.
  // Anonymous/guest users are allowed through so they can upgrade to a permanent account.
  if (!sessionLoading && user && !user.isAnonymous) {
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
      const credential = await apple.getCredential();
      const currentUser = getCurrentUser();
      if (currentUser?.isAnonymous) {
        // Guest user upgrading to permanent account — preserve UID and data
        await guest.upgrade(credential);
      } else {
        // Normal sign-in: sign in directly with the credential
        await firebaseSignIn(credential);
      }
      // Navigation triggered automatically via onAuthStateChanged
    } catch {
      // Error already set in hook or surfaced via guest.error
    }
  }

  async function handleGoogleSignIn(): Promise<void> {
    try {
      const credential = await google.getCredential();
      const currentUser = getCurrentUser();
      if (currentUser?.isAnonymous) {
        // Guest user upgrading to permanent account — preserve UID and data
        await guest.upgrade(credential);
      } else {
        // Normal sign-in: sign in directly with the credential
        await firebaseSignIn(credential);
      }
      // Navigation triggered automatically via onAuthStateChanged
    } catch {
      // Error already set in hook or surfaced via guest.error
    }
  }

  async function handleEmailAuth(): Promise<void> {
    try {
      const currentUser = getCurrentUser();
      if (isSignUpMode) {
        if (currentUser?.isAnonymous) {
          // Guest user creating account — upgrade via linkWithCredential
          const credential = EmailAuthProvider.credential(email, password);
          await guest.upgrade(credential);
          // Navigation triggered automatically via onAuthStateChanged
        } else {
          const result = await emailAuth.signUp(email, password);
          if (result.needsVerification) {
            router.replace('/verify-email');
          }
        }
      } else {
        // Sign-in mode: always use normal path.
        // A guest signing in with an existing email account has no upgrade path.
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
      // Anonymous users are excluded from the redirect guard above (to allow
      // guest-upgrade flow), so we navigate explicitly after sign-in.
      router.replace('/(app)/(tabs)');
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
          {/* Apple Sign In — iOS and Web */}
          {(Platform.OS === 'ios' || Platform.OS === 'web') && (
            <AuthButton
              title="Sign In with Apple"
              onPress={handleAppleSignIn}
              isLoading={apple.isLoading}
              error={apple.error}
              variant="primary"
              disabled={anyLoading && !apple.isLoading}
            />
          )}

          {/* Google Sign In — Android and Web */}
          {(Platform.OS === 'android' || Platform.OS === 'web') && (
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
