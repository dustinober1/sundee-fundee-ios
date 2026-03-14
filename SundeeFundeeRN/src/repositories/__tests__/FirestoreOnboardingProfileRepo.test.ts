/**
 * Tests for FirestoreOnboardingProfileRepo — Firestore implementation of OnboardingProfileRepository.
 */
import firestore from '@react-native-firebase/firestore';
import { FirestoreOnboardingProfileRepo } from '../FirestoreOnboardingProfileRepo';
import type { OnboardingProfile } from '../OnboardingProfileRepo';

const mockFirestoreInstance = firestore();
const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');

const testProfile: OnboardingProfile = {
  name: 'Test User',
  experienceLevel: 'intermediate',
  primaryGoal: 'strength',
  gender: 'female',
  cycleOptIn: true,
  hasCompletedOnboarding: true,
};

describe('FirestoreOnboardingProfileRepo', () => {
  let repo: FirestoreOnboardingProfileRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreOnboardingProfileRepo();
  });

  it('saveProfile calls firestore doc.set() with profile data and { merge: true }', async () => {
    await repo.saveProfile('test-uid', testProfile);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.set).toHaveBeenCalledWith(testProfile, { merge: true });
  });

  it('getProfile calls firestore doc.get() and returns OnboardingProfile', async () => {
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testProfile),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getProfile('test-uid');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.get).toHaveBeenCalledTimes(1);
    expect(result).toEqual(testProfile);
  });

  it('getProfile returns null when document does not exist', async () => {
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getProfile('nonexistent-uid');

    expect(result).toBeNull();
  });
});
