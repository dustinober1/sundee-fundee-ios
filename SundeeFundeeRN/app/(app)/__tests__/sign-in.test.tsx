/**
 * Tests for SignInScreen — guest upgrade and normal sign-in branches.
 *
 * Covers:
 * - Test 1: handleAppleSignIn calls guest.upgrade(credential) when isAnonymous
 * - Test 2: handleGoogleSignIn calls guest.upgrade(credential) when isAnonymous
 * - Test 3: handleEmailAuth in sign-up mode calls guest.upgrade(credential) when isAnonymous
 * - Test 4: handleEmailAuth in sign-in mode calls emailAuth.signIn normally even when isAnonymous
 * - Test 5: handleAppleSignIn calls firebaseSignIn(credential) when NOT anonymous (regression)
 * - Test 6: handleGoogleSignIn calls firebaseSignIn(credential) when NOT anonymous (regression)
 * - Test 7: handleEmailAuth calls emailAuth.signUp normally when NOT anonymous (regression)
 * - Test 8: auth/credential-already-in-use error from guest.upgrade is caught gracefully
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports (Babel hoisting safety)
// All factories use inline jest.fn() to avoid TDZ issues with const variables
// ---------------------------------------------------------------------------

const mockRouterReplace = jest.fn();

jest.mock('expo-router', () => ({
  useRouter: jest.fn(() => ({ replace: mockRouterReplace })),
  Redirect: () => null,
}));

jest.mock('@/src/theme/colors', () => ({
  CREAM: '#F4F0DF',
  CREAM_LIGHT: '#FAF7EE',
  NAVY: '#0D1A40',
  NAVY_MEDIUM: '#3A4A6B',
  ORANGE: '#F2731A',
  GREY: '#9E9E9E',
  GREY_LIGHT: '#E0E0E0',
  RED: '#D32F2F',
}));

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: jest.fn(() => ({ user: null, isLoading: false })),
}));

jest.mock('@/src/auth/useAppleSignIn', () => ({
  useAppleSignIn: jest.fn(() => ({
    signIn: jest.fn().mockResolvedValue(undefined),
    getCredential: jest.fn().mockResolvedValue({ providerId: 'apple.com', token: 'mock-apple-token' }),
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useGoogleSignIn', () => ({
  useGoogleSignIn: jest.fn(() => ({
    signIn: jest.fn().mockResolvedValue(undefined),
    getCredential: jest.fn().mockResolvedValue({ providerId: 'google.com', token: 'mock-google-token' }),
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useEmailAuth', () => ({
  useEmailAuth: jest.fn(() => ({
    signUp: jest.fn().mockResolvedValue({ needsVerification: false }),
    signIn: jest.fn().mockResolvedValue(undefined),
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useGuestSignIn', () => ({
  useGuestSignIn: jest.fn(() => ({
    signIn: jest.fn().mockResolvedValue(undefined),
    upgrade: jest.fn().mockResolvedValue(undefined),
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/firebase/auth', () => ({
  getCurrentUser: jest.fn().mockReturnValue({ isAnonymous: false }),
  signInWithCredential: jest.fn().mockResolvedValue({ uid: 'user-123' }),
  EmailAuthProvider: {
    credential: jest.fn().mockReturnValue({ providerId: 'password', token: 'mock-email-token' }),
  },
}));

// Mock AuthButton as a simple Pressable with testID={title} to avoid mocking native button internals
jest.mock('@/src/components/AuthButton', () => {
  const { Pressable, Text } = require('react-native');
  return {
    AuthButton: ({ title, onPress }: { title: string; onPress: () => void }) => (
      <Pressable testID={title} onPress={onPress}>
        <Text>{title}</Text>
      </Pressable>
    ),
  };
});

jest.mock('@/src/components/OfflineBanner', () => ({
  OfflineBanner: () => null,
}));

// ---------------------------------------------------------------------------
// Imports — after mocks
// ---------------------------------------------------------------------------

import React from 'react';
import { Platform } from 'react-native';
import { render, screen, fireEvent, waitFor } from '@testing-library/react-native';
import SignInScreen from '../../sign-in';

// Import mocked modules to get references to the jest.fn() instances
import { useAppleSignIn } from '@/src/auth/useAppleSignIn';
import { useGoogleSignIn } from '@/src/auth/useGoogleSignIn';
import { useEmailAuth } from '@/src/auth/useEmailAuth';
import { useGuestSignIn } from '@/src/auth/useGuestSignIn';
import * as firebaseAuth from '@/src/firebase/auth';

// ---------------------------------------------------------------------------
// Constants for mock credentials
// ---------------------------------------------------------------------------

const mockAppleCredential = { providerId: 'apple.com', token: 'mock-apple-token' };
const mockGoogleCredential = { providerId: 'google.com', token: 'mock-google-token' };
const mockEmailCredential = { providerId: 'password', token: 'mock-email-token' };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('SignInScreen — guest upgrade and normal sign-in', () => {
  // Capture hook mock return value references
  let appleHook: ReturnType<typeof useAppleSignIn>;
  let googleHook: ReturnType<typeof useGoogleSignIn>;
  let emailHook: ReturnType<typeof useEmailAuth>;
  let guestHook: ReturnType<typeof useGuestSignIn>;

  beforeEach(() => {
    jest.clearAllMocks();

    // Default: iOS platform (renders Apple button)
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });

    // Default: user is NOT anonymous
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: false });
    (firebaseAuth.signInWithCredential as jest.Mock).mockResolvedValue({ uid: 'user-123' });
    (firebaseAuth.EmailAuthProvider.credential as jest.Mock).mockReturnValue(mockEmailCredential);

    // Set up hook return values with fresh jest.fn() per test
    appleHook = {
      signIn: jest.fn().mockResolvedValue(undefined),
      getCredential: jest.fn().mockResolvedValue(mockAppleCredential),
      isLoading: false,
      error: null,
    };
    googleHook = {
      signIn: jest.fn().mockResolvedValue(undefined),
      getCredential: jest.fn().mockResolvedValue(mockGoogleCredential),
      isLoading: false,
      error: null,
    };
    emailHook = {
      signUp: jest.fn().mockResolvedValue({ needsVerification: false }),
      signIn: jest.fn().mockResolvedValue(undefined),
      isLoading: false,
      error: null,
    };
    guestHook = {
      signIn: jest.fn().mockResolvedValue(undefined),
      upgrade: jest.fn().mockResolvedValue(undefined),
      isLoading: false,
      error: null,
    };

    (useAppleSignIn as jest.Mock).mockReturnValue(appleHook);
    (useGoogleSignIn as jest.Mock).mockReturnValue(googleHook);
    (useEmailAuth as jest.Mock).mockReturnValue(emailHook);
    (useGuestSignIn as jest.Mock).mockReturnValue(guestHook);
  });

  // ── Test 1: Apple — guest upgrade path ──────────────────────────────────

  it('Test 1: handleAppleSignIn calls guest.upgrade(credential) when isAnonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(appleHook.getCredential).toHaveBeenCalledTimes(1);
      expect(guestHook.upgrade).toHaveBeenCalledWith(mockAppleCredential);
    });
    expect(appleHook.signIn).not.toHaveBeenCalled();
    expect(firebaseAuth.signInWithCredential).not.toHaveBeenCalled();
  });

  // ── Test 2: Google — guest upgrade path ─────────────────────────────────

  it('Test 2: handleGoogleSignIn calls guest.upgrade(credential) when isAnonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: true });
    // Use Android platform to render Google button
    Object.defineProperty(Platform, 'OS', { value: 'android', configurable: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Google'));

    await waitFor(() => {
      expect(googleHook.getCredential).toHaveBeenCalledTimes(1);
      expect(guestHook.upgrade).toHaveBeenCalledWith(mockGoogleCredential);
    });
    expect(googleHook.signIn).not.toHaveBeenCalled();
    expect(firebaseAuth.signInWithCredential).not.toHaveBeenCalled();
  });

  // ── Test 3: Email sign-up — guest upgrade path ───────────────────────────

  it('Test 3: handleEmailAuth in sign-up mode calls guest.upgrade(credential) when isAnonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    // Toggle to sign-up mode
    fireEvent.press(screen.getByTestId('toggle-mode-link'));
    // Enter email and password
    fireEvent.changeText(screen.getByTestId('email-input'), 'new@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'password123');
    fireEvent.press(screen.getByTestId('Create Account'));

    await waitFor(() => {
      expect(firebaseAuth.EmailAuthProvider.credential).toHaveBeenCalledWith(
        'new@example.com',
        'password123'
      );
      expect(guestHook.upgrade).toHaveBeenCalledWith(mockEmailCredential);
    });
    expect(emailHook.signUp).not.toHaveBeenCalled();
  });

  // ── Test 4: Email sign-in — always normal path even when anonymous ────────

  it('Test 4: handleEmailAuth in sign-in mode calls emailAuth.signIn normally even when isAnonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    fireEvent.changeText(screen.getByTestId('email-input'), 'existing@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'password123');
    fireEvent.press(screen.getByTestId('Sign In'));

    await waitFor(() => {
      expect(emailHook.signIn).toHaveBeenCalledWith('existing@example.com', 'password123');
    });
    expect(guestHook.upgrade).not.toHaveBeenCalled();
  });

  // ── Test 5: Apple — normal path when NOT anonymous (regression) ──────────

  it('Test 5: handleAppleSignIn calls firebaseSignIn(credential) when NOT anonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: false });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(appleHook.getCredential).toHaveBeenCalledTimes(1);
      expect(firebaseAuth.signInWithCredential).toHaveBeenCalledWith(mockAppleCredential);
    });
    expect(guestHook.upgrade).not.toHaveBeenCalled();
  });

  // ── Test 6: Google — normal path when NOT anonymous (regression) ─────────

  it('Test 6: handleGoogleSignIn calls firebaseSignIn(credential) when NOT anonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: false });
    // Use Android platform to render Google button
    Object.defineProperty(Platform, 'OS', { value: 'android', configurable: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Google'));

    await waitFor(() => {
      expect(googleHook.getCredential).toHaveBeenCalledTimes(1);
      expect(firebaseAuth.signInWithCredential).toHaveBeenCalledWith(mockGoogleCredential);
    });
    expect(guestHook.upgrade).not.toHaveBeenCalled();
  });

  // ── Test 7: Email sign-up — normal path when NOT anonymous (regression) ───

  it('Test 7: handleEmailAuth calls emailAuth.signUp normally when NOT anonymous', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: false });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('toggle-mode-link'));
    fireEvent.changeText(screen.getByTestId('email-input'), 'new@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'newpassword');
    fireEvent.press(screen.getByTestId('Create Account'));

    await waitFor(() => {
      expect(emailHook.signUp).toHaveBeenCalledWith('new@example.com', 'newpassword');
    });
    expect(guestHook.upgrade).not.toHaveBeenCalled();
  });

  // ── Test 8: credential-already-in-use error surfaces to UI ───────────────

  it('Test 8: auth/credential-already-in-use error from guest.upgrade surfaces gracefully', async () => {
    (firebaseAuth.getCurrentUser as jest.Mock).mockReturnValue({ isAnonymous: true });
    const credentialError = new Error('auth/credential-already-in-use');
    guestHook.upgrade = jest.fn().mockRejectedValue(credentialError);
    (useGuestSignIn as jest.Mock).mockReturnValue(guestHook);

    // The error should be caught without crashing the app
    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(guestHook.upgrade).toHaveBeenCalledWith(mockAppleCredential);
    });
    // No crash — error is caught in the handler's catch block
    // Render does not throw, UI remains visible
    expect(screen.getByTestId('Sign In with Apple')).toBeTruthy();
  });
});
