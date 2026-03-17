/**
 * Tests for WODRepository — interface, factory, and Firestore implementation.
 * WODs are public read-only data — no local implementation needed.
 */

import firestore from '@react-native-firebase/firestore';
import { FirestoreWODRepo } from '../FirestoreWODRepo';
import { getWODRepo } from '../WODRepo';
import type { WODRecord } from '../WODRepo';

const mockFirestoreInstance = firestore();

const testWOD: WODRecord = {
  id: '2026-03-15',
  date: '2026-03-15',
  name: 'Fran',
  description: '21-15-9 of Thrusters and Pull-ups',
  exercises: ['Thrusters (95/65 lb)', 'Pull-ups'],
  scoringType: 'time',
};

// ─── FirestoreWODRepo ─────────────────────────────────────────────────────────

describe('FirestoreWODRepo', () => {
  let repo: FirestoreWODRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreWODRepo();
  });

  it('getWODForDate queries /wods/{date} collection', async () => {
    await repo.getWODForDate('2026-03-15');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('wods');
  });

  it('getWODForDate returns WODRecord when document exists', async () => {
    const mockDocRef = mockFirestoreInstance.collection('wods').doc('2026-03-15');
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testWOD),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getWODForDate('2026-03-15');

    expect(result).toEqual(testWOD);
  });

  it('getWODForDate returns null when document does not exist', async () => {
    const mockDocRef = mockFirestoreInstance.collection('wods').doc('2026-03-15');
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getWODForDate('2026-01-01');

    expect(result).toBeNull();
  });

  it('getRecentWODs queries with orderBy and limit', async () => {
    const mockQuerySnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(testWOD) }],
    };
    const mockCollection = mockFirestoreInstance.collection('wods');
    (mockCollection.get as jest.Mock).mockResolvedValue(mockQuerySnapshot);

    const result = await repo.getRecentWODs(5);

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });

  it('getRecentWODs returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('wods');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getRecentWODs();

    expect(result).toEqual([]);
  });
});

// ─── Factory function ────────────────────────────────────────────────────────

describe('getWODRepo', () => {
  it('always returns FirestoreWODRepo (public data, no guest distinction)', () => {
    const repo = getWODRepo();
    expect(repo).toBeInstanceOf(FirestoreWODRepo);
  });
});
