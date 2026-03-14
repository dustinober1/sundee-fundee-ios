/**
 * Tests for migrateGuestDataToFirestore — guest-to-auth data migration.
 */
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn().mockResolvedValue(null),
  setItem: jest.fn().mockResolvedValue(undefined),
  removeItem: jest.fn().mockResolvedValue(undefined),
  clear: jest.fn().mockResolvedValue(undefined),
  getAllKeys: jest.fn().mockResolvedValue([]),
  multiGet: jest.fn().mockResolvedValue([]),
  multiRemove: jest.fn().mockResolvedValue(undefined),
}));

import firestore from '@react-native-firebase/firestore';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { migrateGuestDataToFirestore } from '../migration';

const mockFirestoreInstance = firestore();

const testProfile = {
  name: 'Guest User',
  experienceLevel: 'beginner',
  primaryGoal: 'general',
  hasCompletedOnboarding: true,
};

const testSettings = {
  weightUnit: 'lb',
  notificationsEnabled: true,
};

const testWorkouts = [
  { id: 'w1', uid: 'old-guest-uid', completedAt: '2026-03-14T10:00:00.000Z' },
  { id: 'w2', uid: 'old-guest-uid', completedAt: '2026-03-13T10:00:00.000Z' },
];

const testReadiness = [
  { id: '2026-03-14', uid: 'old-guest-uid', date: '2026-03-14' },
];

describe('migrateGuestDataToFirestore', () => {
  let mockBatch: { set: jest.Mock; commit: jest.Mock };

  beforeEach(() => {
    jest.clearAllMocks();
    mockBatch = {
      set: jest.fn().mockReturnThis(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    (mockFirestoreInstance.batch as jest.Mock).mockReturnValue(mockBatch);
  });

  it('migrates onboarding profile into /users/{uid} with merge', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', JSON.stringify(testProfile)],
      ['@sundee/workouts', null],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', null],
    ]);

    await migrateGuestDataToFirestore('new-uid');

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      testProfile,
      { merge: true }
    );
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates settings into /users/{uid} with merge', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', null],
      ['@sundee/workouts', null],
      ['@sundee/settings', JSON.stringify(testSettings)],
      ['@sundee/readiness_surveys', null],
    ]);

    await migrateGuestDataToFirestore('new-uid');

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      testSettings,
      { merge: true }
    );
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates each workout into the subcollection', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', null],
      ['@sundee/workouts', JSON.stringify(testWorkouts)],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', null],
    ]);

    await migrateGuestDataToFirestore('new-uid');

    // One batch.set() call per workout
    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(2);
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates each readiness survey into the subcollection', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', null],
      ['@sundee/workouts', null],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', JSON.stringify(testReadiness)],
    ]);

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('skips null AsyncStorage values without crashing', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', null],
      ['@sundee/workouts', null],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', null],
    ]);

    await expect(migrateGuestDataToFirestore('new-uid')).resolves.not.toThrow();
    expect(mockBatch.set).not.toHaveBeenCalled();
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('clears all @sundee/* keys from AsyncStorage after successful commit', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', JSON.stringify(testProfile)],
      ['@sundee/workouts', null],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', null],
    ]);

    await migrateGuestDataToFirestore('new-uid');

    expect(AsyncStorage.multiRemove).toHaveBeenCalledWith([
      '@sundee/onboarding_profile',
      '@sundee/workouts',
      '@sundee/settings',
      '@sundee/readiness_surveys',
    ]);
  });

  it('does NOT clear AsyncStorage if batch.commit() rejects', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue([
      ['@sundee/onboarding_profile', JSON.stringify(testProfile)],
      ['@sundee/workouts', null],
      ['@sundee/settings', null],
      ['@sundee/readiness_surveys', null],
    ]);
    mockBatch.commit.mockRejectedValue(new Error('Firestore unavailable'));

    await expect(migrateGuestDataToFirestore('new-uid')).rejects.toThrow('Firestore unavailable');

    expect(AsyncStorage.multiRemove).not.toHaveBeenCalled();
  });
});
