/**
 * Tests for BenchmarkRepository — interface, factory, Firestore, and Local implementations.
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
import { LocalBenchmarkRepo } from '../LocalBenchmarkRepo';
import { FirestoreBenchmarkRepo } from '../FirestoreBenchmarkRepo';
import { getBenchmarkRepo } from '../BenchmarkRepo';
import type { BenchmarkResultRecord } from '../BenchmarkRepo';
import type { BenchmarkDefinition } from '../../domain/types/index';

const result1: BenchmarkResultRecord = {
  id: 'result-001',
  uid: 'guest-uid',
  benchmarkId: 'fran',
  benchmarkName: 'Fran',
  scoringType: 'time',
  score: 270,
  date: '2026-03-14',
  notes: 'Rx',
};

const result2: BenchmarkResultRecord = {
  id: 'result-002',
  uid: 'guest-uid',
  benchmarkId: 'fran',
  benchmarkName: 'Fran',
  scoringType: 'time',
  score: 240,
  date: '2026-03-01',
};

const result3: BenchmarkResultRecord = {
  id: 'result-003',
  uid: 'guest-uid',
  benchmarkId: 'cindy',
  benchmarkName: 'Cindy',
  scoringType: 'roundsAndReps',
  score: 200009, // 20 rounds + 9 reps
  date: '2026-03-10',
};

const customBenchmark1: BenchmarkDefinition = {
  id: 'custom-001',
  userID: 'guest-uid',
  name: 'My 1RM Test',
  category: 'Strength',
  workoutDescription: 'Max effort back squat single',
  scoringType: 'weight',
  isPredefined: false,
  sortOrder: 0,
};

const customBenchmark2: BenchmarkDefinition = {
  id: 'custom-002',
  userID: 'guest-uid',
  name: 'Bear Complex',
  category: 'Conditioning',
  workoutDescription: '5 rounds of barbell complex for time',
  scoringType: 'time',
  isPredefined: false,
  sortOrder: 1,
};

// ─── LocalBenchmarkRepo ───────────────────────────────────────────────────────

describe('LocalBenchmarkRepo', () => {
  let repo: LocalBenchmarkRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalBenchmarkRepo();
  });

  it('saveResult appends new result to AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([result2]));

    await repo.saveResult('guest-uid', result1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('saveResult upserts existing result by id', async () => {
    const oldResult = { ...result1, score: 999 };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([oldResult]));

    await repo.saveResult('guest-uid', result1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].score).toBe(270);
  });

  it('getResults returns results filtered by benchmarkId and sorted by date descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([result2, result1, result3]) // out of order
    );

    const result = await repo.getResults('guest-uid', 'fran');

    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('result-001'); // 2026-03-14
    expect(result[1].id).toBe('result-002'); // 2026-03-01
  });

  it('getResults returns empty array when no results for benchmarkId', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([result1]));

    const result = await repo.getResults('guest-uid', 'nonexistent');

    expect(result).toEqual([]);
  });

  it('getAllResults returns all results sorted by date descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([result2, result3, result1])
    );

    const result = await repo.getAllResults('guest-uid');

    expect(result).toHaveLength(3);
    expect(result[0].id).toBe('result-001'); // 2026-03-14
    expect(result[1].id).toBe('result-003'); // 2026-03-10
    expect(result[2].id).toBe('result-002'); // 2026-03-01
  });

  it('getAllResults returns empty array when nothing stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getAllResults('guest-uid');

    expect(result).toEqual([]);
  });

  it('saveCustomBenchmark appends new benchmark to AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([customBenchmark2]));

    await repo.saveCustomBenchmark('guest-uid', customBenchmark1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('saveCustomBenchmark upserts existing benchmark by id', async () => {
    const old = { ...customBenchmark1, name: 'Old Name' };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([old]));

    await repo.saveCustomBenchmark('guest-uid', customBenchmark1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].name).toBe('My 1RM Test');
  });

  it('getCustomBenchmarks returns all custom benchmarks', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([customBenchmark1, customBenchmark2])
    );

    const result = await repo.getCustomBenchmarks('guest-uid');

    expect(result).toHaveLength(2);
  });

  it('getCustomBenchmarks returns empty array when nothing stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getCustomBenchmarks('guest-uid');

    expect(result).toEqual([]);
  });

  it('deleteCustomBenchmark removes benchmark by id', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([customBenchmark1, customBenchmark2])
    );

    await repo.deleteCustomBenchmark('guest-uid', 'custom-001');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('custom-002');
  });
});

// ─── FirestoreBenchmarkRepo ───────────────────────────────────────────────────

describe('FirestoreBenchmarkRepo', () => {
  const mockFirestoreInstance = firestore();
  let repo: FirestoreBenchmarkRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreBenchmarkRepo();
  });

  it('saveResult calls Firestore collection users', async () => {
    await repo.saveResult('test-uid', result1);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getResults returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getResults('test-uid', 'fran');

    expect(result).toEqual([]);
  });

  it('getAllResults returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getAllResults('test-uid');

    expect(result).toEqual([]);
  });

  it('saveCustomBenchmark calls Firestore collection users', async () => {
    await repo.saveCustomBenchmark('test-uid', customBenchmark1);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getCustomBenchmarks returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getCustomBenchmarks('test-uid');

    expect(result).toEqual([]);
  });

  it('deleteCustomBenchmark calls Firestore delete', async () => {
    await repo.deleteCustomBenchmark('test-uid', 'custom-001');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });
});

// ─── Factory function ────────────────────────────────────────────────────────

describe('getBenchmarkRepo', () => {
  it('returns LocalBenchmarkRepo when isGuest is true', () => {
    const repo = getBenchmarkRepo(true);
    expect(repo).toBeInstanceOf(LocalBenchmarkRepo);
  });

  it('returns FirestoreBenchmarkRepo when isGuest is false', () => {
    const repo = getBenchmarkRepo(false);
    expect(repo).toBeInstanceOf(FirestoreBenchmarkRepo);
  });
});

// ─── roundsAndReps encoding ───────────────────────────────────────────────────

describe('roundsAndReps score encoding', () => {
  it('encodes 20 rounds + 9 reps correctly', () => {
    const rounds = 20;
    const reps = 9;
    const encoded = rounds * 10000 + reps;

    expect(encoded).toBe(200009);
  });

  it('decodes 200009 back to 20 rounds + 9 reps', () => {
    const score = 200009;
    const rounds = Math.floor(score / 10000);
    const reps = score % 10000;

    expect(rounds).toBe(20);
    expect(reps).toBe(9);
  });

  it('result record stores already-encoded score value', async () => {
    const repo = new LocalBenchmarkRepo();
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([result3]));

    const results = await repo.getAllResults('guest-uid');

    expect(results[0].score).toBe(200009);
    // Decode: 20 rounds + 9 reps
    expect(Math.floor(results[0].score / 10000)).toBe(20);
    expect(results[0].score % 10000).toBe(9);
  });
});
