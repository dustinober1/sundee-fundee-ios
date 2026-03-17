/**
 * verify-email.tsx — Email verification waiting screen.
 *
 * Shown after sign-up when email verification is required.
 * Firebase does not auto-detect verification — user must re-sign-in after verifying.
 *
 * Design: simple, clean, Art Deco styling (CREAM background, NAVY text).
 */

import React, { useState } from 'react';
import { Alert, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { useSession } from '@/src/auth/AuthContext';
import * as colors from '@/src/theme/colors';

// ─── VerifyEmailScreen ────────────────────────────────────────────────────────

export default function VerifyEmailScreen(): React.JSX.Element {
  const { user, signOut } = useSession();
  const [isSending, setIsSending] = useState(false);

  async function handleResend(): Promise<void> {
    if (!user) return;
    setIsSending(true);
    try {
      await user.sendEmailVerification();
      Alert.alert(
        'Email Sent',
        'A new verification email has been sent. Check your inbox.',
        [{ text: 'OK' }]
      );
    } catch {
      Alert.alert(
        'Error',
        'Failed to send verification email. Please try again.',
        [{ text: 'OK' }]
      );
    } finally {
      setIsSending(false);
    }
  }

  async function handleBackToSignIn(): Promise<void> {
    await signOut();
    // onAuthStateChanged will trigger redirect to sign-in automatically
  }

  return (
    <View style={styles.container}>
      {/* Icon placeholder */}
      <View style={styles.iconContainer}>
        <Text style={styles.iconText}>✉</Text>
      </View>

      <Text style={styles.title}>Check Your Email</Text>

      <Text style={styles.body}>
        We've sent a verification link to{' '}
        {user?.email != null ? (
          <Text style={styles.emailText}>{user.email}</Text>
        ) : (
          'your email address'
        )}
        .{'\n\n'}
        Please verify your email before signing in. After verifying, return here
        and sign in again.
      </Text>

      <TouchableOpacity
        style={[styles.resendButton, isSending && styles.resendButtonDisabled]}
        onPress={handleResend}
        disabled={isSending}
        activeOpacity={0.7}
        testID="resend-button"
      >
        <Text style={styles.resendButtonText}>
          {isSending ? 'Sending...' : 'Resend Verification Email'}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.backLink}
        onPress={handleBackToSignIn}
        testID="back-to-signin-link"
      >
        <Text style={styles.backLinkText}>Back to Sign In</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingVertical: 48,
  },
  iconContainer: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.ORANGE_LIGHT,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 24,
  },
  iconText: {
    fontSize: 36,
  },
  title: {
    fontSize: 26,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 16,
    textAlign: 'center',
  },
  body: {
    fontSize: 15,
    color: colors.NAVY_MEDIUM,
    lineHeight: 22,
    textAlign: 'center',
    marginBottom: 32,
  },
  emailText: {
    fontWeight: '600',
    color: colors.NAVY,
  },
  resendButton: {
    width: '100%',
    height: 52,
    borderRadius: 8,
    backgroundColor: colors.NAVY,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  resendButtonDisabled: {
    opacity: 0.5,
  },
  resendButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
  backLink: {
    paddingVertical: 8,
  },
  backLinkText: {
    fontSize: 14,
    color: colors.NAVY_MEDIUM,
    textDecorationLine: 'underline',
  },
});
