/**
 * Tests for LocalWorkoutRepo — AsyncStorage implementation of WorkoutRepository.
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

import AsyncStorage from '@react-native-async-storage/async-storage';
import { LocalWorkoutRepo } from '../LocalWorkoutRepo';
import type { WorkoutRecord } from '../WorkoutRepo';

const WORKOUTS_KEY = '@sundee/workouts';

const makeRecord = (id: string, completedAt: string): WorkoutRecord => ({
  id,
  uid: 'guest-uid',
  completedAt,
  durationSeconds: 1800,
  source: 'custom',
  workout: {
    id: `gen-${id}`,
    createdAt: new Date(completedAt),
    isFavorite: false,
    isCompleted: true,
    coachingSummary: 'Done!',
    exercises: [],
    questionnaire: {
      timeMinutes: 30,
      focus: 'full_body',
      energyLevel: 'medium',
      equipment: 'bodyweight_only',
      desiredSkills: null,
    },
  },
});

const record1 = makeRecord('w1', '2026-03-14T10:00:00.000Z');
const record2 = makeRecord('w2', '2026-03-13T10:00:00.000Z');

describe('LocalWorkoutRepo', () => {
  let repo: LocalWorkoutRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalWorkoutRepo();
  });

  it('saveWorkout appends to existing workouts in AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record2]));

    await repo.saveWorkout('guest-uid', record1);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      WORKOUTS_KEY,
      expect.any(String)
    );
    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
    expect(savedData.some((r: WorkoutRecord) => r.id === 'w1')).toBe(true);
  });

  it('saveWorkout creates new array when no workouts stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await repo.saveWorkout('guest-uid', record1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
  });

  it('getWorkout returns the matching record', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record1, record2]));

    const result = await repo.getWorkout('guest-uid', 'w1');

    // Date objects serialize to ISO strings in JSON — compare against JSON round-trip result
    const expected = JSON.parse(JSON.stringify(record1)) as WorkoutRecord;
    expect(result).toEqual(expected);
  });

  it('getWorkout returns null when id not found', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record1]));

    const result = await repo.getWorkout('guest-uid', 'nonexistent');

    expect(result).toBeNull();
  });

  it('getHistory returns records sorted by completedAt descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([record2, record1]) // stored out of order
    );

    const result = await repo.getHistory('guest-uid');

    expect(result[0].id).toBe('w1'); // w1 is newer
    expect(result[1].id).toBe('w2');
  });

  it('getHistory applies limit', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([record1, record2])
    );

    const result = await repo.getHistory('guest-uid', 1);

    expect(result).toHaveLength(1);
  });

  it('getHistory returns empty array when no workouts stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getHistory('guest-uid');

    expect(result).toEqual([]);
  });

  it('deleteWorkout removes the matching record from storage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record1, record2]));

    await repo.deleteWorkout('guest-uid', 'w1');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('w2');
  });
});
