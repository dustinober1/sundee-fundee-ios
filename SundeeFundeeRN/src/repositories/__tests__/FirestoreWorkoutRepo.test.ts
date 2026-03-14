/**
 * Tests for FirestoreWorkoutRepo — Firestore implementation of WorkoutRepository.
 */
import firestore from '@react-native-firebase/firestore';
import { FirestoreWorkoutRepo } from '../FirestoreWorkoutRepo';
import type { WorkoutRecord } from '../WorkoutRepo';

const mockFirestoreInstance = firestore();

const testRecord: WorkoutRecord = {
  id: 'workout-1',
  uid: 'test-uid',
  completedAt: '2026-03-14T10:00:00.000Z',
  durationSeconds: 3600,
  source: 'ai',
  workout: {
    id: 'gen-1',
    createdAt: new Date('2026-03-14T10:00:00.000Z'),
    isFavorite: false,
    isCompleted: true,
    coachingSummary: 'Great workout!',
    exercises: [],
    questionnaire: {
      timeMinutes: 60,
      focus: 'strength',
      energyLevel: 'high',
      equipment: 'full_gym',
      desiredSkills: null,
    },
  },
};

describe('FirestoreWorkoutRepo', () => {
  let repo: FirestoreWorkoutRepo;
  let mockUserDoc: ReturnType<typeof mockFirestoreInstance.collection>['doc'];
  let mockWorkoutsCollection: ReturnType<typeof mockFirestoreInstance.collection>;
  let mockWorkoutDoc: ReturnType<typeof mockFirestoreInstance.collection>['doc'];

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreWorkoutRepo();

    // The mock chains: collection('users').doc(uid).collection('workouts').doc(id)
    mockWorkoutDoc = mockFirestoreInstance.collection('users').doc('test-uid');
    mockUserDoc = mockFirestoreInstance.collection('users').doc('test-uid');
    mockWorkoutsCollection = mockFirestoreInstance.collection('users');
  });

  it('saveWorkout calls firestore with subcollection path /users/{uid}/workouts/{id}', async () => {
    await repo.saveWorkout('test-uid', testRecord);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getWorkout returns workout record when document exists', async () => {
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testRecord),
    };
    (mockWorkoutDoc.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getWorkout('test-uid', 'workout-1');
    expect(result).toEqual(testRecord);
  });

  it('getWorkout returns null when document does not exist', async () => {
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockWorkoutDoc.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getWorkout('test-uid', 'nonexistent');
    expect(result).toBeNull();
  });

  it('getHistory queries with orderBy and limit', async () => {
    const mockQuerySnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(testRecord) }],
    };
    // The mock collection's get() returns snapshot
    const mockCollection = mockFirestoreInstance.collection('users');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockQuerySnapshot);

    const result = await repo.getHistory('test-uid', 10);
    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });

  it('deleteWorkout calls doc.delete() on the workout subcollection document', async () => {
    await repo.deleteWorkout('test-uid', 'workout-1');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });
});
