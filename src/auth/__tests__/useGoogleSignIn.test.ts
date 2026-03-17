/**
 * Tests for useGoogleSignIn hook.
 */
import { renderHook, act } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () => ({
  clear: jest.fn().mockResolvedValue(undefined),
}));

import auth, { GoogleAuthProvider } from '@react-native-firebase/auth';
import { GoogleSignin } from '@react-native-google-signin/google-signin';
import { useGoogleSignIn } from '../useGoogleSignIn';

const mockAuthInstance = auth();

describe('useGoogleSignIn', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (GoogleSignin.hasPlayServices as jest.Mock).mockResolvedValue(true);
    (GoogleSignin.signIn as jest.Mock).mockResolvedValue({
      type: 'success',
      data: {
        idToken: 'mock-google-id-token',
        user: {
          id: 'google-user-id',
          email: 'test@gmail.com',
          name: 'Test User',
        },
      },
    });
    (mockAuthInstance.signInWithCredential as jest.Mock).mockResolvedValue({
      user: {
        uid: 'google-firebase-uid',
        email: 'test@gmail.com',
        isAnonymous: false,
      },
    });
  });

  it('signIn calls GoogleSignin.hasPlayServices', async () => {
    const { result } = renderHook(() => useGoogleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(GoogleSignin.hasPlayServices).toHaveBeenCalledWith({
      showPlayServicesUpdateDialog: true,
    });
  });

  it('signIn calls GoogleSignin.signIn and extracts idToken', async () => {
    const { result } = renderHook(() => useGoogleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(GoogleSignin.signIn).toHaveBeenCalledTimes(1);
    // idToken extraction is verified by the credential creation below
    expect(GoogleAuthProvider.credential).toHaveBeenCalledWith('mock-google-id-token');
  });

  it('signIn creates GoogleAuthProvider.credential with idToken', async () => {
    const { result } = renderHook(() => useGoogleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(GoogleAuthProvider.credential).toHaveBeenCalledWith('mock-google-id-token');
  });

  it('signIn calls auth().signInWithCredential with Google credential', async () => {
    const { result } = renderHook(() => useGoogleSignIn());

    await act(async () => {
      await result.current.signIn();
    });

    expect(mockAuthInstance.signInWithCredential).toHaveBeenCalledWith(
      expect.objectContaining({ providerId: 'google.com' })
    );
  });
});
