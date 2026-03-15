/**
 * Tests for exportData orchestration functions.
 * Mocks all repositories, file system, and sharing APIs.
 */

// ---------------------------------------------------------------------------
// Module mocks — must come before imports
// ---------------------------------------------------------------------------

jest.mock('expo-file-system/legacy', () => ({
  cacheDirectory: 'file:///cache/',
  writeAsStringAsync: jest.fn().mockResolvedValue(undefined),
  makeDirectoryAsync: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('expo-sharing', () => ({
  shareAsync: jest.fn().mockResolvedValue(undefined),
  isAvailableAsync: jest.fn().mockResolvedValue(true),
}));

jest.mock('react-native-zip-archive', () => ({
  zip: jest.fn().mockResolvedValue('file:///cache/export.zip'),
}));

// Platform is mocked via Object.defineProperty per test (see STATE.md decision:
// "Platform.OS test mocking: Object.defineProperty(Platform, 'OS', {value, configurable:true})")
jest.mock('react-native', () => ({
  Platform: { OS: 'ios' },
}));

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { zip } from 'react-native-zip-archive';
import { Platform } from 'react-native';
import {
  collectAllUserData,
  buildCsvFiles,
  exportUserData,
  type RepoBundle,
} from '../exportData';
import type { WorkoutRecord } from '../../repositories/WorkoutRepo';
import type { ExerciseMax } from '../../domain/pr-detection/pr-types';
import type { BenchmarkResultRecord } from '../../repositories/BenchmarkRepo';
import type { PeriodLogRecord } from '../../repositories/CycleRepo';
import type { PainLogRecord, InjuryProfileRecord } from '../../repositories/InjuryRepo';
import type { ReadinessSurveyRecord } from '../../repositories/ReadinessRepo';

// ---------------------------------------------------------------------------
// Mock data fixtures
// ---------------------------------------------------------------------------

const sampleWorkout: WorkoutRecord = {
  id: 'w1',
  uid: 'u1',
  completedAt: '2024-06-15T10:00:00Z',
  durationSeconds: 3600,
  source: 'custom',
  workoutName: 'Test Workout',
  exercises: [],
};

const sampleMax: ExerciseMax = {
  exerciseId: 'e1',
  exerciseName: 'Squat',
  repRange: 5,
  weight: 220,
  estimated1RM: 247,
  achievedAt: '2024-06-01',
};

const sampleBenchmark: BenchmarkResultRecord = {
  id: 'b1',
  uid: 'u1',
  benchmarkId: 'fran',
  benchmarkName: 'Fran',
  scoringType: 'time',
  score: 182,
  date: '2024-05-20',
};

const samplePeriodLog: PeriodLogRecord = {
  id: 'p1',
  uid: 'u1',
  startDate: '2024-06-01T00:00:00Z',
  endDate: '2024-06-05T00:00:00Z',
};

const samplePainLog: PainLogRecord = {
  id: 'pl1',
  uid: 'u1',
  injuryId: 'inj1',
  date: '2024-06-10T00:00:00Z',
  painLevel: 3,
};

const sampleInjury: InjuryProfileRecord = {
  id: 'inj1',
  uid: 'u1',
  bodyLocation: 'leftKnee',
  recoveryPhase: 'rehab',
  injuryDate: '2024-05-15T00:00:00Z',
};

const sampleReadiness: ReadinessSurveyRecord = {
  id: '2024-06-10',
  uid: 'u1',
  date: '2024-06-10',
  sleepQuality: 7,
  energyLevel: 6,
  stressLevel: 4,
  sorenessLevel: 5,
  result: { score: 0.6, recommendation: 'Train normally' } as any,
};

// ---------------------------------------------------------------------------
// Mock repo bundle
// ---------------------------------------------------------------------------

function makeRepos(): RepoBundle {
  return {
    workoutRepo: {
      getHistory: jest.fn().mockResolvedValue([sampleWorkout]),
      saveWorkout: jest.fn(),
      getWorkout: jest.fn(),
      deleteWorkout: jest.fn(),
    },
    maxRepo: {
      getAllMaxes: jest.fn().mockResolvedValue([sampleMax]),
      getMaxes: jest.fn(),
      saveMax: jest.fn(),
      deleteMaxesForExercise: jest.fn(),
      getMax1RMHistory: jest.fn(),
    },
    benchmarkRepo: {
      getAllResults: jest.fn().mockResolvedValue([sampleBenchmark]),
      saveResult: jest.fn(),
      getResults: jest.fn(),
      saveCustomBenchmark: jest.fn(),
      getCustomBenchmarks: jest.fn().mockResolvedValue([]),
      deleteCustomBenchmark: jest.fn(),
    },
    cycleRepo: {
      getPeriodLogs: jest.fn().mockResolvedValue([samplePeriodLog]),
      savePeriodLog: jest.fn(),
      deletePeriodLog: jest.fn(),
      saveCycleSettings: jest.fn(),
      getCycleSettings: jest.fn(),
    },
    injuryRepo: {
      getInjuries: jest.fn().mockResolvedValue([sampleInjury]),
      getPainLogs: jest.fn().mockResolvedValue([samplePainLog]),
      saveInjury: jest.fn(),
      deleteInjury: jest.fn(),
      savePainLog: jest.fn(),
    },
    readinessRepo: {
      getRecentSurveys: jest.fn().mockResolvedValue([sampleReadiness]),
      saveSurvey: jest.fn(),
      getSurveyForDate: jest.fn(),
    },
  };
}

// ---------------------------------------------------------------------------
// collectAllUserData
// ---------------------------------------------------------------------------

describe('collectAllUserData', () => {
  it('calls all repositories with the uid', async () => {
    const repos = makeRepos();
    const data = await collectAllUserData('u1', repos);

    expect(repos.workoutRepo.getHistory).toHaveBeenCalledWith('u1');
    expect(repos.maxRepo.getAllMaxes).toHaveBeenCalledWith('u1');
    expect(repos.benchmarkRepo.getAllResults).toHaveBeenCalledWith('u1');
    expect(repos.cycleRepo.getPeriodLogs).toHaveBeenCalledWith('u1');
    expect(repos.injuryRepo.getInjuries).toHaveBeenCalledWith('u1');
    expect(repos.injuryRepo.getPainLogs).toHaveBeenCalledWith('u1', expect.any(String));
    expect(repos.readinessRepo.getRecentSurveys).toHaveBeenCalledWith('u1', 1000);
  });

  it('returns structured data with all fields', async () => {
    const repos = makeRepos();
    const data = await collectAllUserData('u1', repos);

    expect(data.workouts).toHaveLength(1);
    expect(data.maxes).toHaveLength(1);
    expect(data.benchmarks).toHaveLength(1);
    expect(data.periodLogs).toHaveLength(1);
    expect(data.injuries).toHaveLength(1);
    expect(data.readiness).toHaveLength(1);
  });
});

// ---------------------------------------------------------------------------
// buildCsvFiles
// ---------------------------------------------------------------------------

describe('buildCsvFiles', () => {
  const sampleData = {
    workouts: [sampleWorkout],
    maxes: [sampleMax],
    benchmarks: [sampleBenchmark],
    periodLogs: [samplePeriodLog],
    painLogs: [samplePainLog],
    injuries: [sampleInjury],
    readiness: [sampleReadiness],
  };

  it('returns 7 CSV files', () => {
    const files = buildCsvFiles(sampleData, 'lb');
    expect(files).toHaveLength(7);
  });

  it('all files have name and content', () => {
    const files = buildCsvFiles(sampleData, 'lb');
    for (const file of files) {
      expect(file.name).toBeTruthy();
      expect(file.content).toBeTruthy();
    }
  });

  it('file names end with .csv', () => {
    const files = buildCsvFiles(sampleData, 'lb');
    for (const file of files) {
      expect(file.name).toMatch(/\.csv$/);
    }
  });

  it('workout file name is workouts.csv', () => {
    const files = buildCsvFiles(sampleData, 'lb');
    const workoutFile = files.find(f => f.name === 'workouts.csv');
    expect(workoutFile).toBeDefined();
  });

  it('passes weightUnit to formatters', () => {
    const filesLb = buildCsvFiles(sampleData, 'lb');
    const filesKg = buildCsvFiles(sampleData, 'kg');
    const workoutLb = filesLb.find(f => f.name === 'workouts.csv')!;
    const workoutKg = filesKg.find(f => f.name === 'workouts.csv')!;
    expect(workoutLb.content).toContain('Weight (lbs)');
    expect(workoutKg.content).toContain('Weight (kg)');
  });
});

// ---------------------------------------------------------------------------
// exportUserData — JSON format
// ---------------------------------------------------------------------------

describe('exportUserData (json)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  it('writes a single JSON file to cache directory', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'json', 'lb', repos);

    expect(FileSystem.writeAsStringAsync).toHaveBeenCalledTimes(1);
    const [uri, content] = (FileSystem.writeAsStringAsync as jest.Mock).mock.calls[0];
    expect(uri).toContain('sundee-fundee-export-');
    expect(uri).toMatch(/\.json$/);
    // Content should be valid JSON
    expect(() => JSON.parse(content)).not.toThrow();
  });

  it('shares the JSON file via expo-sharing', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'json', 'lb', repos);
    expect(Sharing.shareAsync).toHaveBeenCalledTimes(1);
  });
});

// ---------------------------------------------------------------------------
// exportUserData — CSV format
// ---------------------------------------------------------------------------

describe('exportUserData (csv)', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
  });

  it('writes multiple CSV files to cache directory', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'csv', 'lb', repos);

    // Should have written 7 CSV files
    expect(FileSystem.writeAsStringAsync).toHaveBeenCalledTimes(7);
  });

  it('zips the CSV files', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'csv', 'lb', repos);
    expect(zip).toHaveBeenCalledTimes(1);
  });

  it('shares the zip file via expo-sharing', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'csv', 'lb', repos);
    expect(Sharing.shareAsync).toHaveBeenCalledTimes(1);
    const [sharedPath] = (Sharing.shareAsync as jest.Mock).mock.calls[0];
    expect(sharedPath).toMatch(/\.zip$/);
  });
});

// ---------------------------------------------------------------------------
// exportUserData — web platform
// ---------------------------------------------------------------------------

describe('exportUserData (web platform)', () => {
  const mockClickFn = jest.fn();
  const mockCreateObjectURL = jest.fn().mockReturnValue('blob:fake');
  const mockRevokeObjectURL = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    mockClickFn.mockClear();
    mockCreateObjectURL.mockClear();
    Object.defineProperty(Platform, 'OS', { value: 'web', configurable: true });

    // Stub DOM APIs on globalThis (jest-expo test env has no jsdom)
    const mockLink = {
      href: '',
      download: '',
      click: mockClickFn,
      style: {},
    };
    (global as any).document = {
      createElement: jest.fn().mockReturnValue(mockLink),
      body: {
        appendChild: jest.fn(),
        removeChild: jest.fn(),
      },
    };
    (global as any).URL = {
      createObjectURL: mockCreateObjectURL,
      revokeObjectURL: mockRevokeObjectURL,
    };
    (global as any).Blob = class {
      constructor(public content: string[], public options: { type: string }) {}
    };
  });

  afterEach(() => {
    Object.defineProperty(Platform, 'OS', { value: 'ios', configurable: true });
    delete (global as any).document;
  });

  it('does not call expo-sharing on web', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'json', 'lb', repos);
    expect(Sharing.shareAsync).not.toHaveBeenCalled();
  });

  it('uses URL.createObjectURL for web JSON export', async () => {
    const repos = makeRepos();
    await exportUserData('u1', 'json', 'lb', repos);
    expect(mockCreateObjectURL).toHaveBeenCalled();
  });
});
