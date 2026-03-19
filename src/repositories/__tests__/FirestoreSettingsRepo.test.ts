/**
 * Tests for FirestoreSettingsRepo — Firestore implementation of SettingsRepository.
 */
import firestore from '@react-native-firebase/firestore';
import { FirestoreSettingsRepo } from '../FirestoreSettingsRepo';
import type { AppSettings } from '../SettingsRepo';

const mockFirestoreInstance = firestore();
const mockDocRef = mockFirestoreInstance.collection('users').doc('test-uid');

const testSettings: AppSettings = {
  weightUnit: 'kg',
  defaultRestDuration: 90,
  restTimerAlertsEnabled: true,
  workoutRemindersEnabled: false,
  wodAlertsEnabled: true,
  subscriptionAlertsEnabled: true,
  reminderHour: 7,
  reminderMinute: 0,
};

describe('FirestoreSettingsRepo', () => {
  let repo: FirestoreSettingsRepo;

  beforeEach(() => {
    jest.clearAllMocks();
    repo = new FirestoreSettingsRepo();
  });

  it('saveSettings calls firestore doc.set() with settings and { merge: true }', async () => {
    await repo.saveSettings('test-uid', testSettings);

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.set).toHaveBeenCalledWith(testSettings, { merge: true });
  });

  it('getSettings calls firestore doc.get() and returns AppSettings', async () => {
    const mockDocSnapshot = {
      exists: true,
      data: jest.fn().mockReturnValue(testSettings),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getSettings('test-uid');

    expect(mockFirestoreInstance.collection).toHaveBeenCalledWith('users');
    expect(mockDocRef.get).toHaveBeenCalledTimes(1);
    expect(result).toEqual(testSettings);
  });

  it('getSettings returns null when document does not exist', async () => {
    const mockDocSnapshot = {
      exists: false,
      data: jest.fn().mockReturnValue(undefined),
    };
    (mockDocRef.get as jest.Mock).mockResolvedValue(mockDocSnapshot);

    const result = await repo.getSettings('test-uid');

    expect(result).toBeNull();
  });
});
