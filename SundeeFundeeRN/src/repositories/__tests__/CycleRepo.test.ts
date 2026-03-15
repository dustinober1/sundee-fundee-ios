/**
 * Tests for CycleRepository — interface, factory, Firestore, and Local implementations.
 */

// ─── LocalCycleRepo tests ────────────────────────────────────────────────────

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
import { LocalCycleRepo } from '../LocalCycleRepo';
import { FirestoreCycleRepo } from '../FirestoreCycleRepo';
import { getCycleRepo, periodLogToRecord, recordToPeriodLog } from '../CycleRepo';
import type { PeriodLogRecord } from '../CycleRepo';
import type { CycleSettings, PeriodLog } from '../../domain/types/index';

const PERIOD_LOGS_KEY = '@sundee/period_logs';
const CYCLE_SETTINGS_KEY = '@sundee/cycle_settings';

const testSettings: CycleSettings = {
  averageCycleLengthDays: 28,
  averagePeriodLengthDays: 5,
  lutealPhaseLengthDays: 14,
};

const log1: PeriodLogRecord = {
  id: 'log-001',
  uid: 'guest-uid',
  startDate: '2026-03-01T00:00:00.000Z',
  endDate: '2026-03-05T00:00:00.000Z',
};

const log2: PeriodLogRecord = {
  id: 'log-002',
  uid: 'guest-uid',
  startDate: '2026-02-01T00:00:00.000Z',
};

// ─── LocalCycleRepo ──────────────────────────────────────────────────────────

describe('LocalCycleRepo', () => {
  let repo: LocalCycleRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalCycleRepo();
  });

  it('savePeriodLog appends new log to AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([log2]));

    await repo.savePeriodLog('guest-uid', log1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('savePeriodLog replaces existing log with same id', async () => {
    const oldLog = { ...log1, startDate: '2025-01-01T00:00:00.000Z' };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([oldLog]));

    await repo.savePeriodLog('guest-uid', log1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].startDate).toBe('2026-03-01T00:00:00.000Z');
  });

  it('getPeriodLogs returns logs sorted by startDate descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([log2, log1]) // stored out of order
    );

    const result = await repo.getPeriodLogs('guest-uid');

    expect(result[0].id).toBe('log-001'); // newer first (2026-03)
    expect(result[1].id).toBe('log-002'); // older (2026-02)
  });

  it('getPeriodLogs returns empty array when nothing stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getPeriodLogs('guest-uid');

    expect(result).toEqual([]);
  });

  it('deletePeriodLog removes log by id', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([log1, log2]));

    await repo.deletePeriodLog('guest-uid', 'log-001');

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].id).toBe('log-002');
  });

  it('saveCycleSettings writes settings to AsyncStorage', async () => {
    await repo.saveCycleSettings('guest-uid', testSettings);

    expect(AsyncStorage.setItem).toHaveBeenCalledWith(
      CYCLE_SETTINGS_KEY,
      JSON.stringify(testSettings)
    );
  });

  it('getCycleSettings returns parsed settings', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify(testSettings));

    const result = await repo.getCycleSettings('guest-uid');

    expect(result).toEqual(testSettings);
  });

  it('getCycleSettings returns null when no settings stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getCycleSettings('guest-uid');

    expect(result).toBeNull();
  });
});

// ─── FirestoreCycleRepo ──────────────────────────────────────────────────────

describe('FirestoreCycleRepo', () => {
  const mockFirestoreInstance = firestore();
  let repo: FirestoreCycleRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreCycleRepo();
  });

  it('savePeriodLog calls firestore collection users', async () => {
    await repo.savePeriodLog('test-uid', log1);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getPeriodLogs returns empty array when snapshot is empty', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = { empty: true, docs: [] };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getPeriodLogs('test-uid');

    expect(result).toEqual([]);
  });

  it('getPeriodLogs returns records from Firestore docs', async () => {
    const mockCollection = mockFirestoreInstance.collection('users');
    const mockSnapshot = {
      empty: false,
      docs: [{ data: jest.fn().mockReturnValue(log1) }],
    };
    (mockCollection.get as jest.Mock).mockResolvedValue(mockSnapshot);

    const result = await repo.getPeriodLogs('test-uid');

    expect(result).toBeDefined();
    expect(Array.isArray(result)).toBe(true);
  });

  it('deletePeriodLog calls Firestore delete', async () => {
    await repo.deletePeriodLog('test-uid', 'log-001');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
  });

  it('getCycleSettings returns null when document does not exist', async () => {
    const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');
    const mockDocSnapshot = { exists: false, data: jest.fn().mockReturnValue(undefined) };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getCycleSettings('test-uid');

    expect(result).toBeNull();
  });

  it('getCycleSettings returns settings when document exists', async () => {
    const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');
    const mockDocSnapshot = { exists: true, data: jest.fn().mockReturnValue(testSettings) };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getCycleSettings('test-uid');

    expect(result).toEqual(testSettings);
  });
});

// ─── Factory function ────────────────────────────────────────────────────────

describe('getCycleRepo', () => {
  it('returns LocalCycleRepo when isGuest is true', () => {
    const repo = getCycleRepo(true);
    expect(repo).toBeInstanceOf(LocalCycleRepo);
  });

  it('returns FirestoreCycleRepo when isGuest is false', () => {
    const repo = getCycleRepo(false);
    expect(repo).toBeInstanceOf(FirestoreCycleRepo);
  });
});

// ─── Conversion helpers ──────────────────────────────────────────────────────

describe('periodLogToRecord / recordToPeriodLog', () => {
  it('round-trips a PeriodLog with endDate', () => {
    const log: PeriodLog = {
      startDate: new Date('2026-03-01T00:00:00.000Z'),
      endDate: new Date('2026-03-05T00:00:00.000Z'),
    };

    const record = periodLogToRecord('uid-123', 'log-abc', log);
    expect(record.id).toBe('log-abc');
    expect(record.uid).toBe('uid-123');
    expect(record.startDate).toBe(log.startDate.toISOString());
    expect(record.endDate).toBe(log.endDate!.toISOString());

    const restored = recordToPeriodLog(record);
    expect(restored.startDate.toISOString()).toBe(log.startDate.toISOString());
    expect(restored.endDate?.toISOString()).toBe(log.endDate!.toISOString());
  });

  it('round-trips a PeriodLog without endDate', () => {
    const log: PeriodLog = {
      startDate: new Date('2026-03-01T00:00:00.000Z'),
    };

    const record = periodLogToRecord('uid-123', 'log-abc', log);
    expect(record.endDate).toBeUndefined();

    const restored = recordToPeriodLog(record);
    expect(restored.endDate).toBeUndefined();
  });
});
