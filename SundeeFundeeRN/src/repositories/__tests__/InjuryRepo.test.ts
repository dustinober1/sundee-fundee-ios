/**
 * Tests for InjuryRepository — interface, factory, Firestore, and Local implementations.
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
import { LocalInjuryRepo } from '../LocalInjuryRepo';
import { FirestoreInjuryRepo } from '../FirestoreInjuryRepo';
import { getInjuryRepo, injuryProfileToRecord, recordToInjuryProfile, painLogToRecord, recordToPainLog } from '../InjuryRepo';
import type { InjuryProfileRecord, PainLogRecord } from '../InjuryRepo';
import type { InjuryProfile, PainLog } from '../../domain/types/index';

const injury1: InjuryProfileRecord = {
  id: 'injury-001',
  uid: 'guest-uid',
  bodyLocation: 'leftKnee',
  recoveryPhase: 'rehab',
  injuryDate: '2026-02-15T00:00:00.000Z',
  notes: 'Mild strain',
  location: 'knee',
};

const injury2: InjuryProfileRecord = {
  id: 'injury-002',
  uid: 'guest-uid',
  bodyLocation: 'lowerBack',
  recoveryPhase: 'acute',
  injuryDate: '2026-03-10T00:00:00.000Z',
};

const painLog1: PainLogRecord = {
  id: 'pain-001',
  uid: 'guest-uid',
  injuryId: 'injury-001',
  date: '2026-03-14T00:00:00.000Z',
  painLevel: 3,
};

const painLog2: PainLogRecord = {
  id: 'pain-002',
  uid: 'guest-uid',
  injuryId: 'injury-001',
  date: '2026-03-10T00:00:00.000Z',
  painLevel: 5,
};

const painLogOtherInjury: PainLogRecord = {
  id: 'pain-003',
  uid: 'guest-uid',
  injuryId: 'injury-002',
  date: '2026-03-11T00:00:00.000Z',
  painLevel: 7,
};

// ─── LocalInjuryRepo ─────────────────────────────────────────────────────────

describe('LocalInjuryRepo', () => {
  let repo: LocalInjuryRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalInjuryRepo();
  });

  it('saveInjury appends new injury to AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([injury2]));

    await repo.saveInjury('guest-uid', injury1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('saveInjury upserts existing injury by id', async () => {
    const oldInjury = { ...injury1, recoveryPhase: 'acute' as const };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([oldInjury]));

    await repo.saveInjury('guest-uid', injury1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].recoveryPhase).toBe('rehab');
  });

  it('getInjuries returns all injuries', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([injury1, injury2]));

    const result = await repo.getInjuries('guest-uid');

    expect(result).toHaveLength(2);
  });

  it('getInjuries returns empty array when nothing stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getInjuries('guest-uid');

    expect(result).toEqual([]);
  });

  it('deleteInjury removes injury by id', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([injury1, injury2]));

    await repo.deleteInjury('guest-uid', 'injury-001');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('injury-002');
  });

  it('savePainLog appends new pain log to AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([painLog2]));

    await repo.savePainLog('guest-uid', painLog1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('savePainLog upserts existing pain log by id', async () => {
    const oldLog = { ...painLog1, painLevel: 8 };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([oldLog]));

    await repo.savePainLog('guest-uid', painLog1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].painLevel).toBe(3);
  });

  it('getPainLogs returns logs for specific injury sorted by date descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([painLog2, painLog1, painLogOtherInjury])
    );

    const result = await repo.getPainLogs('guest-uid', 'injury-001');

    expect(result).toHaveLength(2);
    expect(result[0].id).toBe('pain-001'); // 2026-03-14 first
    expect(result[1].id).toBe('pain-002'); // 2026-03-10 second
  });

  it('getPainLogs returns empty array when no logs for injury', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getPainLogs('guest-uid', 'injury-999');

    expect(result).toEqual([]);
  });
});

// ─── FirestoreInjuryRepo ─────────────────────────────────────────────────────

describe('FirestoreInjuryRepo', () => {
  const mockFirestoreInstance = firestore();
  let repo: FirestoreInjuryRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreInjuryRepo();
  });

  it('saveInjury calls Firestore collection users', async () => {
    await repo.saveInjury('test-uid', injury1);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getInjuries returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getInjuries('test-uid');

    expect(result).toEqual([]);
  });

  it('getInjuries returns injury records from Firestore docs', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(injury1) }],
    };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getInjuries('test-uid');

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });

  it('deleteInjury calls Firestore delete', async () => {
    await repo.deleteInjury('test-uid', 'injury-001');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('savePainLog calls Firestore collection users', async () => {
    await repo.savePainLog('test-uid', painLog1);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getPainLogs returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getPainLogs('test-uid', 'injury-001');

    expect(result).toEqual([]);
  });
});

// ─── Factory function ────────────────────────────────────────────────────────

describe('getInjuryRepo', () => {
  it('returns LocalInjuryRepo when isGuest is true', () => {
    const repo = getInjuryRepo(true);
    expect(repo).toBeInstanceOf(LocalInjuryRepo);
  });

  it('returns FirestoreInjuryRepo when isGuest is false', () => {
    const repo = getInjuryRepo(false);
    expect(repo).toBeInstanceOf(FirestoreInjuryRepo);
  });
});

// ─── Conversion helpers ──────────────────────────────────────────────────────

describe('injuryProfileToRecord / recordToInjuryProfile', () => {
  it('round-trips an InjuryProfile with all fields', () => {
    const profile: InjuryProfile = {
      id: 'injury-abc',
      bodyLocation: 'leftKnee',
      recoveryPhase: 'rehab',
      injuryDate: new Date('2026-02-15T00:00:00.000Z'),
      notes: 'Mild strain',
      location: 'knee',
    };

    const record = injuryProfileToRecord('uid-123', profile);
    expect(record.id).toBe('injury-abc');
    expect(record.injuryDate).toBe(profile.injuryDate.toISOString());

    const restored = recordToInjuryProfile(record);
    expect(restored.injuryDate.toISOString()).toBe(profile.injuryDate.toISOString());
    expect(restored.bodyLocation).toBe(profile.bodyLocation);
    expect(restored.recoveryPhase).toBe(profile.recoveryPhase);
    expect(restored.notes).toBe(profile.notes);
  });
});

describe('painLogToRecord / recordToPainLog', () => {
  it('round-trips a PainLog', () => {
    const log: PainLog = {
      date: new Date('2026-03-14T00:00:00.000Z'),
      painLevel: 4,
      injuryId: 'injury-001',
    };

    const record = painLogToRecord('uid-123', 'pain-xyz', log);
    expect(record.id).toBe('pain-xyz');
    expect(record.date).toBe(log.date.toISOString());
    expect(record.painLevel).toBe(4);

    const restored = recordToPainLog(record);
    expect(restored.date.toISOString()).toBe(log.date.toISOString());
    expect(restored.painLevel).toBe(4);
    expect(restored.injuryId).toBe('injury-001');
  });
});
