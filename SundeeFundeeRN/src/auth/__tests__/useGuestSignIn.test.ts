/**
 * Tests for useGuestSignIn hook.
 */
import { renderHook, act } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () => ({
  clear: jest.fn().mockResolvedValue(undefined),
}));

import auth from '@react-native-firebase/auth';
import { useGuestSignIn } from '../useGuestSignIn';

const mockAuthInstance = auth();

const mockAnonymousUser = {
  uid: 'mock-anonymous-uid',
  email: null,
  emailVerified: false,
  isAnonymous: true,
  displayName: null,
};

describe('useGuestSignIn', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (mockAuthInstance.signInAnonymously as jest.Mock).mockResolvedValue({
      user: mockAnonymousUser,
    });
    // Set currentUser to the anonymous user for linkWithCredential
    Object.defineProperty(mockAuthInstance, 'currentUser', {
      get: jest.fn().mockReturnValue({
        ...mockAnonymousUser,
        linkWithCredential: jest.fn().mockResolvedValue({
          user: { uid: 'upgraded-uid', isAnonymous: false },
        }),
      }),
      configurable: true,
    });
  });

  it('signIn calls auth().signInAnonymously', async () => {
    const { result } = renderHook(() => useGuestSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(mockAuthInstance.signInAnonymously).toHaveBeenCalledTimes(1);
  });

  it('signIn returns the anonymous user', async () => {
    const { result } = renderHook(() => useGuestSignIn());

    let signInResult: unknown;
    await act(async () => {
      signInResult = await result.current.signIn();
    });

    expect(signInResult).toEqual(mockAnonymousUser);
  });

  it('upgrade calls currentUser.linkWithCredential with provided credential', async () => {
    const mockCredential = { providerId: 'apple.com', token: 'mock-token' };

    const { result } = renderHook(() => useGuestSignIn());

    await act(async () => {
      await result.current.upgrade(mockCredential as never);
    });

    expect(mockAuthInstance.currentUser?.linkWithCredential).toHaveBeenCalledWith(
      mockCredential
    );
  });
});
