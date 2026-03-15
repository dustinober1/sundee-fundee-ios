/**
 * Tests for LocalExerciseMaxRepo — AsyncStorage implementation of ExerciseMaxRepository.
 * Also tests factory function getExerciseMaxRepo.
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
import { LocalExerciseMaxRepo } from '../LocalExerciseMaxRepo';
import { FirestoreExerciseMaxRepo } from '../FirestoreExerciseMaxRepo';
import { getExerciseMaxRepo } from '../ExerciseMaxRepo';
import type { ExerciseMax } from '../../domain/pr-detection/pr-types';

const MAXES_KEY = '@sundee/exercise-maxes';

const makeMax = (
  exerciseId: string,
  repRange: ExerciseMax['repRange'],
  weight: number,
  achievedAt: string
): ExerciseMax => ({
  exerciseId,
  exerciseName: `Exercise ${exerciseId}`,
  repRange,
  weight,
  estimated1RM: weight * 1.1,
  achievedAt,
});

const max1_5rep = makeMax('ex1', 5, 100, '2026-01-01T10:00:00.000Z');
const max1_5rep_heavier = makeMax('ex1', 5, 120, '2026-02-01T10:00:00.000Z');
const max1_5rep_lighter = makeMax('ex1', 5, 90, '2026-03-01T10:00:00.000Z');
const max1_1rep = makeMax('ex1', 1, 140, '2026-01-15T10:00:00.000Z');
const max2_5rep = makeMax('ex2', 5, 80, '2026-01-10T10:00:00.000Z');

describe('LocalExerciseMaxRepo', () => {
  let repo: LocalExerciseMaxRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalExerciseMaxRepo();
  });

  it('getMaxes returns empty array when storage is empty', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getMaxes('uid1', 'ex1');

    expect(result).toEqual([]);
  });

  it('getMaxes returns only maxes for the specified exerciseId', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([max1_5rep, max1_1rep, max2_5rep])
    );

    const result = await repo.getMaxes('uid1', 'ex1');

    expect(result).toHaveLength(2);
    expect(result.every((m) => m.exerciseId === 'ex1')).toBe(true);
  });

  it('getAllMaxes returns all maxes regardless of exercise', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([max1_5rep, max1_1rep, max2_5rep])
    );

    const result = await repo.getAllMaxes('uid1');

    expect(result).toHaveLength(3);
  });

  it('getAllMaxes returns empty array when storage is empty', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getAllMaxes('uid1');

    expect(result).toEqual([]);
  });

  it('saveMax adds a new max when no existing max for exerciseId+repRange', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await repo.saveMax('uid1', max1_5rep);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as ExerciseMax[];
    expect(savedData).toHaveLength(1);
    expect(savedData[0].weight).toBe(100);
  });

  it('saveMax replaces existing max when new weight is higher', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([max1_5rep]));

    await repo.saveMax('uid1', max1_5rep_heavier);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as ExerciseMax[];
    expect(savedData).toHaveLength(1);
    expect(savedData[0].weight).toBe(120);
  });

  it('saveMax does NOT replace existing max when new weight is lower', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([max1_5rep]));

    await repo.saveMax('uid1', max1_5rep_lighter);

    expect(AsyncStorage.setItem).not.toHaveBeenCalled();
  });

  it('saveMax does NOT replace existing max when new weight is equal', async () => {
    const equal = makeMax('ex1', 5, 100, '2026-04-01T10:00:00.000Z');
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([max1_5rep]));

    await repo.saveMax('uid1', equal);

    expect(AsyncStorage.setItem).not.toHaveBeenCalled();
  });

  it('saveMax does not affect maxes for other rep ranges of same exercise', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([max1_5rep, max1_1rep])
    );

    await repo.saveMax('uid1', max1_5rep_heavier);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as ExerciseMax[];
    expect(savedData).toHaveLength(2);
    const oneRepMax = savedData.find((m) => m.repRange === 1);
    expect(oneRepMax?.weight).toBe(140);
  });

  it('deleteMaxesForExercise removes all maxes for an exercise', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([max1_5rep, max1_1rep, max2_5rep])
    );

    await repo.deleteMaxesForExercise('uid1', 'ex1');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as ExerciseMax[];
    expect(savedData).toHaveLength(1);
    expect(savedData[0].exerciseId).toBe('ex2');
  });

  it('deleteMaxesForExercise does nothing when no maxes exist for exercise', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([max2_5rep]));

    await repo.deleteMaxesForExercise('uid1', 'ex1');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as ExerciseMax[];
    expect(savedData).toHaveLength(1);
  });

  it('getMax1RMHistory returns time-ordered estimated1RM values for an exercise', async () => {
    const earlyMax = makeMax('ex1', 5, 80, '2026-01-01T10:00:00.000Z');
    const laterMax = makeMax('ex1', 5, 100, '2026-02-01T10:00:00.000Z');
    const latestMax = makeMax('ex1', 1, 150, '2026-03-01T10:00:00.000Z');
    // ex2 max should not appear
    const otherExercise = makeMax('ex2', 5, 200, '2026-01-15T10:00:00.000Z');

    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([laterMax, earlyMax, latestMax, otherExercise])
    );

    const result = await repo.getMax1RMHistory('uid1', 'ex1');

    expect(result).toHaveLength(3);
    expect(result[0].date).toBe('2026-01-01T10:00:00.000Z');
    expect(result[1].date).toBe('2026-02-01T10:00:00.000Z');
    expect(result[2].date).toBe('2026-03-01T10:00:00.000Z');
    expect(typeof result[0].estimated1RM).toBe('number');
  });

  it('getMax1RMHistory returns empty array when no maxes for exercise', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getMax1RMHistory('uid1', 'ex1');

    expect(result).toEqual([]);
  });

  it('uses the correct AsyncStorage key', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);
    await repo.getAllMaxes('uid1');
    expect(AsyncStorage.getItem).toHaveBeenCalledWith(MAXES_KEY);
  });
});

describe('getExerciseMaxRepo factory', () => {
  it('returns LocalExerciseMaxRepo when isGuest is true', () => {
    const repo = getExerciseMaxRepo(true);
    expect(repo).toBeInstanceOf(LocalExerciseMaxRepo);
  });

  it('returns FirestoreExerciseMaxRepo when isGuest is false', () => {
    const repo = getExerciseMaxRepo(false);
    expect(repo).toBeInstanceOf(FirestoreExerciseMaxRepo);
  });
});
