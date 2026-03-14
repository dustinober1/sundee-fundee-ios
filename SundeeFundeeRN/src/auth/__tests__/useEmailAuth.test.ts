/**
 * Tests for useEmailAuth hook.
 */
import { renderHook, act } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () => ({
  clear: jest.fn().mockResolvedValue(undefined),
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
}));

import auth from '@react-native-firebase/auth';
import { useEmailAuth } from '../useEmailAuth';

const mockAuthInstance = auth();

describe('useEmailAuth', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: verified user
    (mockAuthInstance.signInWithEmailAndPassword as jest.Mock).mockResolvedValue({
      user: {
        uid: 'test-uid',
        email: 'test@example.com',
        emailVerified: true,
        isAnonymous: false,
        sendEmailVerification: jest.fn().mockResolvedValue(undefined),
      },
    });
    (mockAuthInstance.createUserWithEmailAndPassword as jest.Mock).mockResolvedValue({
      user: {
        uid: 'new-uid',
        email: 'new@example.com',
        emailVerified: false,
        sendEmailVerification: jest.fn().mockResolvedValue(undefined),
      },
    });
  });

  it('signUp calls createUserWithEmailAndPassword and sendEmailVerification', async () => {
    const mockUser = {
      uid: 'new-uid',
      email: 'new@example.com',
      emailVerified: false,
      sendEmailVerification: jest.fn().mockResolvedValue(undefined),
    };
    (mockAuthInstance.createUserWithEmailAndPassword as jest.Mock).mockResolvedValue({
      user: mockUser,
    });

    const { result } = renderHook(() => useEmailAuth());

    let signUpResult: { needsVerification: boolean } | undefined;
    await act(async () => {
      signUpResult = await result.current.signUp('new@example.com', 'password123');
    });

    expect(mockAuthInstance.createUserWithEmailAndPassword).toHaveBeenCalledWith(
      'new@example.com',
      'password123'
    );
    expect(mockUser.sendEmailVerification).toHaveBeenCalledTimes(1);
    expect(signUpResult).toEqual({ needsVerification: true });
  });

  it('signUp returns error state on failure (email already in use)', async () => {
    (mockAuthInstance.createUserWithEmailAndPassword as jest.Mock).mockRejectedValue({
      code: 'auth/email-already-in-use',
    });

    const { result } = renderHook(() => useEmailAuth());

    await act(async () => {
      try {
        await result.current.signUp('existing@example.com', 'password123');
      } catch {
        // Expected to throw
      }
    });

    expect(result.current.error).toBe('An account with this email already exists');
  });

  it('signIn calls signInWithEmailAndPassword', async () => {
    const { result } = renderHook(() => useEmailAuth());

    await act(async () => {
      await result.current.signIn('test@example.com', 'password123');
    });

    expect(mockAuthInstance.signInWithEmailAndPassword).toHaveBeenCalledWith(
      'test@example.com',
      'password123'
    );
  });

  it('signIn rejects unverified email (emailVerified=false, signs out and throws)', async () => {
    const unverifiedUser = {
      uid: 'unverified-uid',
      email: 'unverified@example.com',
      emailVerified: false,
    };
    (mockAuthInstance.signInWithEmailAndPassword as jest.Mock).mockResolvedValue({
      user: unverifiedUser,
    });

    const { result } = renderHook(() => useEmailAuth());

    await act(async () => {
      try {
        await result.current.signIn('unverified@example.com', 'password123');
      } catch {
        // Expected to throw
      }
    });

    expect(mockAuthInstance.signOut).toHaveBeenCalledTimes(1);
    expect(result.current.error).toBe('Please verify your email before signing in.');
  });

  it('signIn succeeds for verified email (emailVerified=true)', async () => {
    const verifiedUser = {
      uid: 'verified-uid',
      email: 'verified@example.com',
      emailVerified: true,
    };
    (mockAuthInstance.signInWithEmailAndPassword as jest.Mock).mockResolvedValue({
      user: verifiedUser,
    });

    const { result } = renderHook(() => useEmailAuth());

    let signInResult: unknown;
    await act(async () => {
      signInResult = await result.current.signIn('verified@example.com', 'password123');
    });

    expect(signInResult).toEqual(verifiedUser);
    expect(result.current.error).toBeNull();
  });
});
