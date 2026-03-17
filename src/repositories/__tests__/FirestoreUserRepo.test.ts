/**
 * Tests for FirestoreUserRepo — Firestore implementation of UserRepository.
 */
import firestore from '@react-native-firebase/firestore';
import { FirestoreUserRepo } from '../FirestoreUserRepo';
import type { UserProfile } from '../UserRepository';

const mockFirestoreInstance = firestore();
const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');

const testProfile: UserProfile = {
  uid: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
  isAnonymous: false,
  createdAt: '2026-03-14T00:00:00.000Z',
  lastSignInAt: '2026-03-14T00:00:00.000Z',
  authProvider: 'email',
};

describe('FirestoreUserRepo', () => {
  let repo: FirestoreUserRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreUserRepo();
  });

  it('createOrUpdateUser calls firestore doc.set() with user profile data and { merge: true }', async () => {
    await repo.createOrUpdateUser(testProfile);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.set).toHaveBeenCalledWith(testProfile, { merge: true });
  });

  it('getUser calls firestore doc.get() and returns UserProfile', async () => {
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testProfile),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getUser('test-uid');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.get).toHaveBeenCalledTimes(1);
    expect(result).toEqual(testProfile);
  });

  it('getUser returns null when document does not exist', async () => {
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getUser('nonexistent-uid');

    expect(result).toBeNull();
  });

  it('deleteUser calls firestore doc.delete()', async () => {
    await repo.deleteUser('test-uid');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.delete).toHaveBeenCalledTimes(1);
  });
});
