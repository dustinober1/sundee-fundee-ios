/**
 * Tests for migrateGuestDataToFirestore — guest-to-auth data migration.
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
import { migrateGuestDataToFirestore } from '../migration';

const mockFirestoreInstance = firestore();

const testProfile = {
  name: 'Guest User',
  experienceLevel: 'beginner',
  primaryGoal: 'general',
  hasCompletedOnboarding: true,
};

const testSettings = {
  weightUnit: 'lb',
  notificationsEnabled: true,
};

const testWorkouts = [
  { id: 'w1', uid: 'old-guest-uid', completedAt: '2026-03-14T10:00:00.000Z' },
  { id: 'w2', uid: 'old-guest-uid', completedAt: '2026-03-13T10:00:00.000Z' },
];

const testReadiness = [
  { id: '2026-03-14', uid: 'old-guest-uid', date: '2026-03-14' },
];

const testExerciseMaxes = [
  { exerciseId: 'squat', repRange: '1RM', weightLb: 315 },
  { exerciseId: 'bench', repRange: '5RM', weightLb: 225 },
];

const testInjuries = [
  { id: 'inj1', name: 'Left knee', phase: 'acute' },
  { id: 'inj2', name: 'Right shoulder', phase: 'rehab' },
];

const testPainLogs = [
  { id: 'pl1', injuryId: 'inj1', level: 3, date: '2026-03-14' },
  { id: 'pl2', injuryId: 'inj2', level: 5, date: '2026-03-13' },
];

const testPeriodLogs = [
  { id: 'period1', startDate: '2026-03-01', endDate: '2026-03-05' },
];

const testCycleSettings = {
  cycleTrackingEnabled: true,
  averageCycleLength: 28,
};

const testBenchmarkResults = [
  { id: 'br1', benchmarkId: 'fran', score: 240 },
];

const testCustomBenchmarks = [
  { id: 'cb1', name: 'My Benchmark', scoringType: 'time' },
];

const testProgramEnrollment = {
  programId: 'prog1',
  currentWeek: 2,
  startDate: '2026-02-01',
};

const testCustomExercises = [
  { id: 'ce1', name: 'Bulgarian Split Squat', category: 'legs' },
];

/**
 * Build a multiGet result with all 13 keys present, defaulting each to null.
 * Pass overrides as { key: value } pairs.
 */
function buildMultiGet(
  overrides: Record<string, unknown> = {}
): [string, string | null][] {
  const keys = [
    '@sundee/onboarding_profile',
    '@sundee/settings',
    '@sundee/workouts',
    '@sundee/readiness_surveys',
    '@sundee/exercise-maxes',
    '@sundee/injuries',
    '@sundee/pain_logs',
    '@sundee/period_logs',
    '@sundee/cycle_settings',
    '@sundee/benchmark_results',
    '@sundee/custom_benchmarks',
    '@sundee/program_enrollment',
    '@sundee/custom-exercises',
  ];
  return keys.map((k) => [
    k,
    k in overrides ? JSON.stringify(overrides[k]) : null,
  ]);
}

describe('migrateGuestDataToFirestore', () => {
  let mockBatch: { set: jest.Mock; commit: jest.Mock };

  beforeEach(() => {
    jest.clearAllMocks();
    mockBatch = {
      set: jest.fn().mockReturnThis(),
      commit: jest.fn().mockResolvedValue(undefined),
    };
    (mockFirestoreInstance.batch as jest.Mock).mockReturnValue(mockBatch);
  });

  // ─── Existing key migrations ─────────────────────────────────────────────

  it('migrates onboarding profile into /users/{uid} with merge', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/onboarding_profile': testProfile })
    );

    await migrateGuestDataToFirestore('new-uid');

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      testProfile,
      { merge: true }
    );
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates settings into /users/{uid} with merge', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/settings': testSettings })
    );

    await migrateGuestDataToFirestore('new-uid');

    expect(mockBatch.set).toHaveBeenCalledWith(
      expect.anything(),
      testSettings,
      { merge: true }
    );
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates each workout into the subcollection', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/workouts': testWorkouts })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(2);
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  it('migrates each readiness survey into the subcollection', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/readiness_surveys': testReadiness })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    expect(mockBatch.commit).toHaveBeenCalledTimes(1);
  });

  // ─── New key migrations ──────────────────────────────────────────────────

  it('migrates exercise-maxes using compositeId (exerciseId_repRange) as doc ID', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/exercise-maxes': testExerciseMaxes })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(2);
    // Verify doc refs use compositeId — access via the mock firestore chain
    const docMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('exerciseMaxes');
    expect(docMock.doc).toHaveBeenCalledWith('squat_1RM');
    expect(docMock.doc).toHaveBeenCalledWith('bench_5RM');
  });

  it('migrates injuries to /users/{uid}/injuries/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/injuries': testInjuries })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(2);
    const injuriesMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('injuries');
    expect(injuriesMock.doc).toHaveBeenCalledWith('inj1');
    expect(injuriesMock.doc).toHaveBeenCalledWith('inj2');
  });

  it('migrates pain_logs to NESTED path /users/{uid}/injuries/{injuryId}/painLogs/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/pain_logs': testPainLogs })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(2);
    // Each log is nested under its injuryId
    const injuriesMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('injuries');
    expect(injuriesMock.doc).toHaveBeenCalledWith('inj1');
    expect(injuriesMock.doc).toHaveBeenCalledWith('inj2');
  });

  it('migrates period_logs to /users/{uid}/periodLogs/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/period_logs': testPeriodLogs })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const periodLogsMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('periodLogs');
    expect(periodLogsMock.doc).toHaveBeenCalledWith('period1');
  });

  it('migrates cycle_settings as single doc to /users/{uid}/cycleSettings/settings', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/cycle_settings': testCycleSettings })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const cycleSettingsMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('cycleSettings');
    expect(cycleSettingsMock.doc).toHaveBeenCalledWith('settings');
  });

  it('migrates benchmark_results to /users/{uid}/benchmarkResults/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/benchmark_results': testBenchmarkResults })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const benchmarkResultsMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('benchmarkResults');
    expect(benchmarkResultsMock.doc).toHaveBeenCalledWith('br1');
  });

  it('migrates custom_benchmarks to /users/{uid}/customBenchmarks/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/custom_benchmarks': testCustomBenchmarks })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const customBenchmarksMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('customBenchmarks');
    expect(customBenchmarksMock.doc).toHaveBeenCalledWith('cb1');
  });

  it('migrates program_enrollment as single doc to /users/{uid}/enrollment/active', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/program_enrollment': testProgramEnrollment })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const enrollmentMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('enrollment');
    expect(enrollmentMock.doc).toHaveBeenCalledWith('active');
  });

  it('migrates custom-exercises to /users/{uid}/customExercises/{id}', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/custom-exercises': testCustomExercises })
    );

    await migrateGuestDataToFirestore('new-uid');

    const setCalls = (mockBatch.set as jest.Mock).mock.calls;
    expect(setCalls.length).toBe(1);
    const customExercisesMock = mockFirestoreInstance.collection('users').doc('new-uid')
      .collection('customExercises');
    expect(customExercisesMock.doc).toHaveBeenCalledWith('ce1');
  });

  // ─── Multi-batch chunking ─────────────────────────────────────────────────

  it('reads all 13 keys in one multiGet call', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet()
    );

    await migrateGuestDataToFirestore('new-uid');

    expect(AsyncStorage.multiGet).toHaveBeenCalledTimes(1);
    const [calledKeys] = (AsyncStorage.multiGet as jest.Mock).mock.calls[0] as [string[]];
    expect(calledKeys).toHaveLength(13);
  });

  it('splits operations into multiple batches when total exceeds 499', async () => {
    // Generate 500 workouts → forces 2 batches (499 + 1)
    const manyWorkouts = Array.from({ length: 500 }, (_, i) => ({
      id: `w${i}`,
      uid: 'guest',
      completedAt: '2026-03-14T10:00:00.000Z',
    }));

    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/workouts': manyWorkouts })
    );

    await migrateGuestDataToFirestore('new-uid');

    // Should create 2 batches (each committed separately)
    expect(mockBatch.commit).toHaveBeenCalledTimes(2);
    expect(mockFirestoreInstance.batch).toHaveBeenCalledTimes(2);
  });

  // ─── Clear-only-on-success invariant ─────────────────────────────────────

  it('clears all 13 keys plus migration_pending after successful commit', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/onboarding_profile': testProfile })
    );

    await migrateGuestDataToFirestore('new-uid');

    const [removedKeys] = (AsyncStorage.multiRemove as jest.Mock).mock.calls[0] as [string[]];
    expect(removedKeys).toHaveLength(14); // 13 keys + migration_pending
    expect(removedKeys).toContain('@sundee/migration_pending');
    expect(removedKeys).toContain('@sundee/onboarding_profile');
    expect(removedKeys).toContain('@sundee/settings');
    expect(removedKeys).toContain('@sundee/workouts');
    expect(removedKeys).toContain('@sundee/readiness_surveys');
    expect(removedKeys).toContain('@sundee/exercise-maxes');
    expect(removedKeys).toContain('@sundee/injuries');
    expect(removedKeys).toContain('@sundee/pain_logs');
    expect(removedKeys).toContain('@sundee/period_logs');
    expect(removedKeys).toContain('@sundee/cycle_settings');
    expect(removedKeys).toContain('@sundee/benchmark_results');
    expect(removedKeys).toContain('@sundee/custom_benchmarks');
    expect(removedKeys).toContain('@sundee/program_enrollment');
    expect(removedKeys).toContain('@sundee/custom-exercises');
  });

  it('does NOT clear AsyncStorage if any batch commit throws', async () => {
    const manyWorkouts = Array.from({ length: 500 }, (_, i) => ({
      id: `w${i}`,
      uid: 'guest',
      completedAt: '2026-03-14T10:00:00.000Z',
    }));

    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/workouts': manyWorkouts })
    );

    // Second batch commit fails
    mockBatch.commit
      .mockResolvedValueOnce(undefined)
      .mockRejectedValueOnce(new Error('Firestore unavailable'));

    await expect(migrateGuestDataToFirestore('new-uid')).rejects.toThrow(
      'Firestore unavailable'
    );

    expect(AsyncStorage.multiRemove).not.toHaveBeenCalled();
  });

  it('does NOT clear AsyncStorage if batch.commit() rejects (single batch)', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet({ '@sundee/onboarding_profile': testProfile })
    );
    mockBatch.commit.mockRejectedValue(new Error('Firestore unavailable'));

    await expect(migrateGuestDataToFirestore('new-uid')).rejects.toThrow('Firestore unavailable');

    expect(AsyncStorage.multiRemove).not.toHaveBeenCalled();
  });

  it('skips null AsyncStorage values without crashing', async () => {
    (AsyncStorage.multiGet as jest.Mock).mockResolvedValue(
      buildMultiGet()
    );

    await expect(migrateGuestDataToFirestore('new-uid')).resolves.not.toThrow();
    expect(mockBatch.set).not.toHaveBeenCalled();
  });
});
