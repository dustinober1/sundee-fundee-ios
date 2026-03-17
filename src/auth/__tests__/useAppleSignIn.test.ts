/**
 * Tests for useAppleSignIn hook.
 */
import { renderHook, act } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () => ({
  clear: jest.fn().mockResolvedValue(undefined),
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('expo-secure-store', () => ({
  setItemAsync: jest.fn().mockResolvedValue(undefined),
  getItemAsync: jest.fn().mockResolvedValue(null),
  deleteItemAsync: jest.fn().mockResolvedValue(undefined),
}));

import auth, { AppleAuthProvider } from '@react-native-firebase/auth';
import {
  signInAsync as appleSignInAsync,
  AppleAuthenticationScope,
} from 'expo-apple-authentication';
import * as SecureStore from 'expo-secure-store';
import { useAppleSignIn } from '../useAppleSignIn';

const mockAuthInstance = auth();

describe('useAppleSignIn', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (appleSignInAsync as jest.Mock).mockResolvedValue({
      user: 'apple-user-id',
      email: 'test@privaterelay.appleid.com',
      fullName: {
        givenName: 'Jane',
        familyName: 'Doe',
      },
      identityToken: 'mock-identity-token',
      authorizationCode: 'mock-auth-code',
      nonce: 'mock-nonce',
    });
    (mockAuthInstance.signInWithCredential as jest.Mock).mockResolvedValue({
      user: {
        uid: 'apple-firebase-uid',
        email: 'test@privaterelay.appleid.com',
        displayName: 'Jane Doe',
        isAnonymous: false,
      },
    });
  });

  it('signIn calls signInAsync with correct scopes', async () => {
    const { result } = renderHook(() => useAppleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(appleSignInAsync).toHaveBeenCalledWith({
      requestedScopes: [
        AppleAuthenticationScope.FULL_NAME,
        AppleAuthenticationScope.EMAIL,
      ],
    });
  });

  it('signIn creates AppleAuthProvider.credential with identityToken', async () => {
    const { result } = renderHook(() => useAppleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(AppleAuthProvider.credential).toHaveBeenCalledWith(
      'mock-identity-token',
      undefined
    );
  });

  it('signIn calls auth().signInWithCredential with Apple credential', async () => {
    const { result } = renderHook(() => useAppleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(mockAuthInstance.signInWithCredential).toHaveBeenCalledWith(
      expect.objectContaining({ providerId: 'apple.com' })
    );
  });

  it('signIn stores display name to SecureStore on sign-in with fullName', async () => {
    const { result } = renderHook(() => useAppleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(SecureStore.setItemAsync).toHaveBeenCalledWith(
      'apple_display_name',
      expect.stringContaining('Jane')
    );
  });
});
