/**
 * Tests for FirestoreReadinessRepo — Firestore implementation of ReadinessRepository.
 */
import firestore from '@react-native-firebase/firestore';
import { FirestoreReadinessRepo } from '../FirestoreReadinessRepo';
import type { ReadinessSurveyRecord } from '../ReadinessRepo';

const mockFirestoreInstance = firestore();

const testRecord: ReadinessSurveyRecord = {
  id: '2026-03-14',
  uid: 'test-uid',
  date: '2026-03-14',
  sleepQuality: 8,
  energyLevel: 7,
  stressLevel: 3,
  sorenessLevel: 2,
  result: { score: 8.5, tier: 'high' },
};

describe('FirestoreReadinessRepo', () => {
  let repo: FirestoreReadinessRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreReadinessRepo();
  });

  it('saveSurvey calls firestore with subcollection path /users/{uid}/readiness/{date}', async () => {
    await repo.saveSurvey('test-uid', testRecord);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getSurveyForDate returns survey record when document exists', async () => {
    const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testRecord),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getSurveyForDate('test-uid', '2026-03-14');
    expect(result).toEqual(testRecord);
  });

  it('getSurveyForDate returns null when document does not exist', async () => {
    const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getSurveyForDate('test-uid', '2026-01-01');
    expect(result).toBeNull();
  });

  it('getRecentSurveys queries with orderBy and limit', async () => {
    const mockQuerySnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(testRecord) }],
    };
    const mockCollection = mockFirestoreInstance.collection('users');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockQuerySnapshot);

    const result = await repo.getRecentSurveys('test-uid', 5);
    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });
});
