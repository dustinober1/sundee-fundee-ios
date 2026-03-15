/**
 * Tests for LocalExerciseRepo — AsyncStorage implementation of ExerciseRepository.
 * Also tests factory function getExerciseRepo.
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
import { LocalExerciseRepo } from '../LocalExerciseRepo';
import { FirestoreExerciseRepo } from '../FirestoreExerciseRepo';
import { getExerciseRepo } from '../ExerciseRepo';
import type { Exercise } from '../../domain/exercises/exercise-types';

const EXERCISES_KEY = '@sundee/custom-exercises';

const makeExercise = (id: string, name: string): Exercise => ({
  id,
  name,
  muscleGroup: 'Chest',
  isCustom: true,
  equipmentType: 'barbell',
});

const exercise1 = makeExercise('ex1', 'Bench Press Custom');
const exercise2 = makeExercise('ex2', 'Incline DB Press');

describe('LocalExerciseRepo', () => {
  let repo: LocalExerciseRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalExerciseRepo();
  });

  it('getCustomExercises returns empty array when storage is empty', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getCustomExercises('guest-uid');

    expect(result).toEqual([]);
  });

  it('getCustomExercises returns stored exercises', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([exercise1, exercise2])
    );

    const result = await repo.getCustomExercises('guest-uid');

    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('ex1');
    expect(result[1].id).toBe('ex2');
  });

  it('saveCustomExercise appends to existing exercises', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([exercise1]));

    await repo.saveCustomExercise('guest-uid', exercise2);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as Exercise[];
    expect(savedData).toHaveLength(2);
    expect(savedData.some((e) => e.id === 'ex2')).toBe(true);
  });

  it('saveCustomExercise creates new array when storage is empty', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    await repo.saveCustomExercise('guest-uid', exercise1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as Exercise[];
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('ex1');
  });

  it('saveCustomExercise replaces exercise with same id', async () => {
    const updated: Exercise = { ...exercise1, name: 'Updated Name' };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([exercise1, exercise2]));

    await repo.saveCustomExercise('guest-uid', updated);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as Exercise[];
    expect(savedData).toHaveLength(2);
    const saved = savedData.find((e) => e.id === 'ex1');
    expect(saved?.name).toBe('Updated Name');
  });

  it('deleteCustomExercise removes the exercise by id', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([exercise1, exercise2])
    );

    await repo.deleteCustomExercise('guest-uid', 'ex1');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as Exercise[];
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('ex2');
  });

  it('deleteCustomExercise does nothing when id not found', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([exercise1]));

    await repo.deleteCustomExercise('guest-uid', 'nonexistent');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    ) as Exercise[];
    expect(savedData).toHaveLength(1);
  });

  it('uses the correct AsyncStorage key', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);
    await repo.getCustomExercises('guest-uid');
    expect(AsyncStorage.getItem).toHaveBeenCalledWith(EXERCISES_KEY);
  });
});

describe('getExerciseRepo factory', () => {
  it('returns LocalExerciseRepo when isGuest is true', () => {
    const repo = getExerciseRepo(true);
    expect(repo).toBeInstanceOf(LocalExerciseRepo);
  });

  it('returns FirestoreExerciseRepo when isGuest is false', () => {
    const repo = getExerciseRepo(false);
    expect(repo).toBeInstanceOf(FirestoreExerciseRepo);
  });
});
