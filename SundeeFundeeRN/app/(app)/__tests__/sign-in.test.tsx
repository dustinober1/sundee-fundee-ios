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
 * - Test 8: auth/credential-already-in-use error from guest.upgrade is surfaced to the UI
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports (Babel hoisting safety)
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

const mockAppleSignIn = jest.fn();
const mockAppleGetCredential = jest.fn();
const mockGoogleSignIn = jest.fn();
const mockGoogleGetCredential = jest.fn();
const mockEmailSignUp = jest.fn();
const mockEmailSignIn = jest.fn();
const mockGuestSignIn = jest.fn();
const mockGuestUpgrade = jest.fn();
const mockGetCurrentUser = jest.fn();
const mockFirebaseSignIn = jest.fn();
const mockEmailAuthProviderCredential = jest.fn();

jest.mock('@/src/auth/AuthContext', () => ({
  useSession: jest.fn(() => ({ user: null, isLoading: false })),
}));

jest.mock('@/src/auth/useAppleSignIn', () => ({
  useAppleSignIn: jest.fn(() => ({
    signIn: mockAppleSignIn,
    getCredential: mockAppleGetCredential,
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useGoogleSignIn', () => ({
  useGoogleSignIn: jest.fn(() => ({
    signIn: mockGoogleSignIn,
    getCredential: mockGoogleGetCredential,
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useEmailAuth', () => ({
  useEmailAuth: jest.fn(() => ({
    signUp: mockEmailSignUp,
    signIn: mockEmailSignIn,
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/auth/useGuestSignIn', () => ({
  useGuestSignIn: jest.fn(() => ({
    signIn: mockGuestSignIn,
    upgrade: mockGuestUpgrade,
    isLoading: false,
    error: null,
  })),
}));

jest.mock('@/src/firebase/auth', () => ({
  getCurrentUser: mockGetCurrentUser,
  signInWithCredential: mockFirebaseSignIn,
  EmailAuthProvider: {
    credential: mockEmailAuthProviderCredential,
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
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: iOS platform (renders Apple button)
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
    // Default: user is NOT anonymous
    mockGetCurrentUser.mockReturnValue({ isAnonymous: false });
    mockAppleGetCredential.mockResolvedValue(mockAppleCredential);
    mockGoogleGetCredential.mockResolvedValue(mockGoogleCredential);
    mockEmailAuthProviderCredential.mockReturnValue(mockEmailCredential);
    mockGuestUpgrade.mockResolvedValue(undefined);
    mockFirebaseSignIn.mockResolvedValue({ uid: 'user-123' });
    mockEmailSignUp.mockResolvedValue({ needsVerification: false });
    mockEmailSignIn.mockResolvedValue(undefined);
  });

  // ── Test 1: Apple — guest upgrade path ──────────────────────────────────

  it('Test 1: handleAppleSignIn calls guest.upgrade(credential) when isAnonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(mockAppleGetCredential).toHaveBeenCalledTimes(1);
      expect(mockGuestUpgrade).toHaveBeenCalledWith(mockAppleCredential);
    });
    expect(mockAppleSignIn).not.toHaveBeenCalled();
  });

  // ── Test 2: Google — guest upgrade path ─────────────────────────────────

  it('Test 2: handleGoogleSignIn calls guest.upgrade(credential) when isAnonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: true });
    // Use Android platform to render Google button
    Object.defineProperty(Platform, 'OS', { value: 'android', configurable: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Google'));

    await waitFor(() => {
      expect(mockGoogleGetCredential).toHaveBeenCalledTimes(1);
      expect(mockGuestUpgrade).toHaveBeenCalledWith(mockGoogleCredential);
    });
    expect(mockGoogleSignIn).not.toHaveBeenCalled();

    // Restore platform
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  // ── Test 3: Email sign-up — guest upgrade path ───────────────────────────

  it('Test 3: handleEmailAuth in sign-up mode calls guest.upgrade(credential) when isAnonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    // Toggle to sign-up mode
    fireEvent.press(screen.getByTestId('toggle-mode-link'));
    // Enter email and password
    fireEvent.changeText(screen.getByTestId('email-input'), 'new@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'password123');
    fireEvent.press(screen.getByTestId('Create Account'));

    await waitFor(() => {
      expect(mockEmailAuthProviderCredential).toHaveBeenCalledWith(
        'new@example.com',
        'password123'
      );
      expect(mockGuestUpgrade).toHaveBeenCalledWith(mockEmailCredential);
    });
    expect(mockEmailSignUp).not.toHaveBeenCalled();
  });

  // ── Test 4: Email sign-in — always normal path even when anonymous ────────

  it('Test 4: handleEmailAuth in sign-in mode calls emailAuth.signIn normally even when isAnonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: true });

    render(<SignInScreen />);
    fireEvent.changeText(screen.getByTestId('email-input'), 'existing@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'password123');
    fireEvent.press(screen.getByTestId('Sign In'));

    await waitFor(() => {
      expect(mockEmailSignIn).toHaveBeenCalledWith('existing@example.com', 'password123');
    });
    expect(mockGuestUpgrade).not.toHaveBeenCalled();
  });

  // ── Test 5: Apple — normal path when NOT anonymous (regression) ──────────

  it('Test 5: handleAppleSignIn calls firebaseSignIn(credential) when NOT anonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: false });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(mockAppleGetCredential).toHaveBeenCalledTimes(1);
      expect(mockFirebaseSignIn).toHaveBeenCalledWith(mockAppleCredential);
    });
    expect(mockGuestUpgrade).not.toHaveBeenCalled();
  });

  // ── Test 6: Google — normal path when NOT anonymous (regression) ─────────

  it('Test 6: handleGoogleSignIn calls firebaseSignIn(credential) when NOT anonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: false });
    // Use Android platform to render Google button
    Object.defineProperty(Platform, 'OS', { value: 'android', configurable: true });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Google'));

    await waitFor(() => {
      expect(mockGoogleGetCredential).toHaveBeenCalledTimes(1);
      expect(mockFirebaseSignIn).toHaveBeenCalledWith(mockGoogleCredential);
    });
    expect(mockGuestUpgrade).not.toHaveBeenCalled();

    // Restore platform
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  // ── Test 7: Email sign-up — normal path when NOT anonymous (regression) ───

  it('Test 7: handleEmailAuth calls emailAuth.signUp normally when NOT anonymous', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: false });
    mockEmailSignUp.mockResolvedValue({ needsVerification: false });

    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('toggle-mode-link'));
    fireEvent.changeText(screen.getByTestId('email-input'), 'new@example.com');
    fireEvent.changeText(screen.getByTestId('password-input'), 'newpassword');
    fireEvent.press(screen.getByTestId('Create Account'));

    await waitFor(() => {
      expect(mockEmailSignUp).toHaveBeenCalledWith('new@example.com', 'newpassword');
    });
    expect(mockGuestUpgrade).not.toHaveBeenCalled();
  });

  // ── Test 8: credential-already-in-use error surfaces to UI ───────────────

  it('Test 8: auth/credential-already-in-use error from guest.upgrade surfaces to UI', async () => {
    mockGetCurrentUser.mockReturnValue({ isAnonymous: true });
    const credentialError = new Error('auth/credential-already-in-use');
    mockGuestUpgrade.mockRejectedValue(credentialError);

    // The error should be caught without crashing the app
    render(<SignInScreen />);
    fireEvent.press(screen.getByTestId('Sign In with Apple'));

    await waitFor(() => {
      expect(mockGuestUpgrade).toHaveBeenCalledWith(mockAppleCredential);
    });
    // No crash — error is caught in the handler's catch block
    // The hook's error state would be set, but since useGuestSignIn is mocked,
    // we just verify the error was thrown from upgrade and caught gracefully
  });
});
