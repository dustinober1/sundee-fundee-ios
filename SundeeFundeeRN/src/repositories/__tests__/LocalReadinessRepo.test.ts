/**
 * Tests for LocalReadinessRepo — AsyncStorage implementation of ReadinessRepository.
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
import { LocalReadinessRepo } from '../LocalReadinessRepo';
import type { ReadinessSurveyRecord } from '../ReadinessRepo';

const READINESS_KEY = '@sundee/readiness_surveys';

const record1: ReadinessSurveyRecord = {
  id: '2026-03-14',
  uid: 'guest-uid',
  date: '2026-03-14',
  sleepQuality: 8,
  energyLevel: 7,
  stressLevel: 2,
  sorenessLevel: 3,
  result: { score: 8.2, tier: 'high' },
};

const record2: ReadinessSurveyRecord = {
  id: '2026-03-13',
  uid: 'guest-uid',
  date: '2026-03-13',
  sleepQuality: 5,
  energyLevel: 5,
  stressLevel: 6,
  sorenessLevel: 4,
  result: { score: 5.2, tier: 'neutral' },
};

describe('LocalReadinessRepo', () => {
  let repo: LocalReadinessRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new LocalReadinessRepo();
  });

  it('saveSurvey appends to existing surveys in AsyncStorage', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record2]));

    await repo.saveSurvey('guest-uid', record1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(2);
  });

  it('saveSurvey replaces existing record with same date', async () => {
    const oldRecord = { ...record1, sleepQuality: 5 };
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([oldRecord]));

    await repo.saveSurvey('guest-uid', record1);

    const savedData = JSON.parse(
      (AsyncStorage.setItem as jest.Mock).mock.calls[0][1]
    );
    expect(savedData).toHaveLength(1);
    expect(savedData[0].sleepQuality).toBe(8);
  });

  it('getSurveyForDate returns matching record', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record1, record2]));

    const result = await repo.getSurveyForDate('guest-uid', '2026-03-14');

    expect(result).toEqual(record1);
  });

  it('getSurveyForDate returns null when date not found', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(JSON.stringify([record1]));

    const result = await repo.getSurveyForDate('guest-uid', '2026-01-01');

    expect(result).toBeNull();
  });

  it('getRecentSurveys returns records sorted by date descending', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([record2, record1]) // stored out of order
    );

    const result = await repo.getRecentSurveys('guest-uid');

    expect(result[0].date).toBe('2026-03-14'); // newer first
    expect(result[1].date).toBe('2026-03-13');
  });

  it('getRecentSurveys applies limit', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(
      JSON.stringify([record1, record2])
    );

    const result = await repo.getRecentSurveys('guest-uid', 1);

    expect(result).toHaveLength(1);
  });

  it('getRecentSurveys returns empty array when no surveys stored', async () => {
    (AsyncStorage.getItem as jest.Mock).mockResolvedValue(null);

    const result = await repo.getRecentSurveys('guest-uid');

    expect(result).toEqual([]);
  });
});
