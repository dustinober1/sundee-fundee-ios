/**
 * Tests for useGuestSignIn hook.
 */
import { renderHook, act } from '@testing-library/react-native';

jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
  getAllKeys: jest.fn().mockResolvedValue([]),
  multiGet: jest.fn().mockResolvedValue([]),
  multiRemove: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../repositories/migration', () => ({
  migrateGuestDataToFirestore: jest.fn().mockResolvedValue(undefined),
}));

import auth from '@react-native-firebase/auth';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { migrateGuestDataToFirestore } from '../../repositories/migration';
import { useGuestSignIn } from '../useGuestSignIn';

const mockMigrateGuestDataToFirestore = migrateGuestDataToFirestore as jest.Mock;
const mockAuthInstance = auth();

const mockAnonymousUser = {
  uid: 'mock-anonymous-uid',
  email: null,
  emailVerified: false,
  isAnonymous: true,
  displayName: null,
};

const mockUpgradedUser = {
  uid: 'upgraded-uid',
  isAnonymous: false,
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
          user: mockUpgradedUser,
        }),
      }),
      configurable: true,
    });
    // Reset migration mock to default (success)
    mockMigrateGuestDataToFirestore.mockResolvedValue(undefined);
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

  it('upgrade sets @sundee/migration_pending before calling migrateGuestDataToFirestore', async () => {
    const mockCredential = { providerId: 'apple.com', token: 'mock-token' };
    const callOrder: string[] = [];

    (AsyncStorage.setItem as jest.Mock).mockImplementation(async (key: string) => {
      callOrder.push(`setItem:${key}`);
    });
    mockMigrateGuestDataToFirestore.mockImplementation(async () => {
      callOrder.push('migrate');
    });

    const { result } = renderHook(() => useGuestSignIn());

    await act(async () => {
      await result.current.upgrade(mockCredential as never);
    });

    const pendingIdx = callOrder.indexOf('setItem:@sundee/migration_pending');
    const migrateIdx = callOrder.indexOf('migrate');
    expect(pendingIdx).toBeGreaterThanOrEqual(0);
    expect(migrateIdx).toBeGreaterThanOrEqual(0);
    expect(pendingIdx).toBeLessThan(migrateIdx);
  });

  it('upgrade calls migrateGuestDataToFirestore with the user uid after linkWithCredential', async () => {
    const mockCredential = { providerId: 'apple.com', token: 'mock-token' };

    const { result } = renderHook(() => useGuestSignIn());

    await act(async () => {
      await result.current.upgrade(mockCredential as never);
    });

    expect(mockMigrateGuestDataToFirestore).toHaveBeenCalledWith('mock-anonymous-uid');
  });

  it('upgrade returns successfully even when migrateGuestDataToFirestore throws', async () => {
    const mockCredential = { providerId: 'apple.com', token: 'mock-token' };
    mockMigrateGuestDataToFirestore.mockRejectedValueOnce(new Error('Migration failed'));

    const { result } = renderHook(() => useGuestSignIn());

    await act(async () => {
      // Should NOT throw
      await expect(result.current.upgrade(mockCredential as never)).resolves.toBeDefined();
    });
  });

  it('upgrade does not re-throw migration errors', async () => {
    const mockCredential = { providerId: 'apple.com', token: 'mock-token' };
    mockMigrateGuestDataToFirestore.mockRejectedValueOnce(new Error('Migration failed'));

    const { result } = renderHook(() => useGuestSignIn());

    let didThrow = false;
    await act(async () => {
      try {
        await result.current.upgrade(mockCredential as never);
      } catch {
        didThrow = true;
      }
    });

    expect(didThrow).toBe(false);
  });
});
