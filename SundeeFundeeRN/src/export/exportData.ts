/**
 * Export Data Orchestrator
 *
 * Collects all user data from repositories, formats as CSV or JSON,
 * writes to disk, and triggers platform-appropriate sharing/download.
 *
 * - Mobile (iOS/Android): expo-file-system + expo-sharing
 * - Web: Blob + URL.createObjectURL + synthetic <a download> click
 */

import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { zip } from 'react-native-zip-archive';
import { Platform } from 'react-native';

import type { WorkoutRepository, WorkoutRecord } from '../repositories/WorkoutRepo';
import type { ExerciseMaxRepository } from '../repositories/ExerciseMaxRepo';
import type { BenchmarkRepository, BenchmarkResultRecord } from '../repositories/BenchmarkRepo';
import type { CycleRepository, PeriodLogRecord } from '../repositories/CycleRepo';
import type { InjuryRepository, InjuryProfileRecord, PainLogRecord } from '../repositories/InjuryRepo';
import type { ReadinessRepository, ReadinessSurveyRecord } from '../repositories/ReadinessRepo';
import type { ExerciseMax } from '../domain/pr-detection/pr-types';

import {
  workoutsToCsv,
  maxesToCsv,
  benchmarksToCsv,
  cycleToCsv,
  injuriesToCsv,
  painLogsToCsv,
  readinessToCsv,
} from './csvFormatters';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** All repositories required for a full user data export. */
export interface RepoBundle {
  workoutRepo: WorkoutRepository;
  maxRepo: ExerciseMaxRepository;
  benchmarkRepo: BenchmarkRepository;
  cycleRepo: CycleRepository;
  injuryRepo: InjuryRepository;
  readinessRepo: ReadinessRepository;
}

/** Structured collection of all exportable user data. */
export interface AllUserData {
  workouts: WorkoutRecord[];
  maxes: ExerciseMax[];
  benchmarks: BenchmarkResultRecord[];
  periodLogs: PeriodLogRecord[];
  painLogs: PainLogRecord[];
  injuries: InjuryProfileRecord[];
  readiness: ReadinessSurveyRecord[];
}

// ---------------------------------------------------------------------------
// Data collection
// ---------------------------------------------------------------------------

/**
 * Collect all user data from every repository.
 * Pain logs are fetched for all injuries found.
 *
 * @param uid   Firebase user ID
 * @param repos Bundle of all repository instances (testable via dependency injection)
 */
export async function collectAllUserData(
  uid: string,
  repos: RepoBundle
): Promise<AllUserData> {
  const [workouts, maxes, benchmarks, periodLogs, injuries, readiness] =
    await Promise.all([
      repos.workoutRepo.getHistory(uid),
      repos.maxRepo.getAllMaxes(uid),
      repos.benchmarkRepo.getAllResults(uid),
      repos.cycleRepo.getPeriodLogs(uid),
      repos.injuryRepo.getInjuries(uid),
      repos.readinessRepo.getRecentSurveys(uid, 1000),
    ]);

  // Fetch pain logs for each injury
  const painLogArrays = await Promise.all(
    injuries.map(injury => repos.injuryRepo.getPainLogs(uid, injury.id))
  );
  const painLogs = painLogArrays.flat();

  return {
    workouts,
    maxes,
    benchmarks,
    periodLogs,
    painLogs,
    injuries,
    readiness,
  };
}

// ---------------------------------------------------------------------------
// CSV file building
// ---------------------------------------------------------------------------

/** A named CSV file with its string content. */
export interface CsvFile {
  name: string;
  content: string;
}

/**
 * Build an array of named CSV files from collected user data.
 *
 * @param data       All collected user data
 * @param weightUnit User's preferred weight unit for column headers and values
 */
export function buildCsvFiles(
  data: AllUserData,
  weightUnit: 'lb' | 'kg'
): CsvFile[] {
  return [
    { name: 'workouts.csv', content: workoutsToCsv(data.workouts, weightUnit) },
    { name: 'exercise-maxes.csv', content: maxesToCsv(data.maxes, weightUnit) },
    { name: 'benchmarks.csv', content: benchmarksToCsv(data.benchmarks) },
    { name: 'period-logs.csv', content: cycleToCsv(data.periodLogs) },
    { name: 'pain-logs.csv', content: painLogsToCsv(data.painLogs) },
    { name: 'injuries.csv', content: injuriesToCsv(data.injuries) },
    { name: 'readiness.csv', content: readinessToCsv(data.readiness) },
  ];
}

// ---------------------------------------------------------------------------
// Date helper
// ---------------------------------------------------------------------------

function todayDateString(): string {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

// ---------------------------------------------------------------------------
// Web download helper
// ---------------------------------------------------------------------------

function triggerWebDownload(content: string, filename: string, mimeType: string): void {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

// ---------------------------------------------------------------------------
// Export orchestration
// ---------------------------------------------------------------------------

/**
 * Export all user data as a zip of CSVs or a single JSON file.
 * Triggers native share sheet on mobile or browser download on web.
 *
 * @param uid        Firebase user ID
 * @param format     'csv' → zip of 7 CSV files; 'json' → single JSON file
 * @param weightUnit User's preferred weight unit (affects CSV column headers and values)
 * @param repos      Repository bundle (injected for testability)
 */
export async function exportUserData(
  uid: string,
  format: 'csv' | 'json',
  weightUnit: 'lb' | 'kg',
  repos: RepoBundle
): Promise<void> {
  const data = await collectAllUserData(uid, repos);
  const dateStr = todayDateString();
  const isWeb = Platform.OS === 'web';

  if (format === 'json') {
    const filename = `sundee-fundee-export-${dateStr}.json`;
    const content = JSON.stringify(data, null, 2);

    if (isWeb) {
      triggerWebDownload(content, filename, 'application/json');
      return;
    }

    const fileUri = `${FileSystem.cacheDirectory}${filename}`;
    await FileSystem.writeAsStringAsync(fileUri, content);
    await Sharing.shareAsync(fileUri);
    return;
  }

  // CSV format: write individual files then zip
  const csvFiles = buildCsvFiles(data, weightUnit);
  const exportDirName = `sundee-export-${dateStr}`;
  const exportDir = `${FileSystem.cacheDirectory}${exportDirName}/`;

  if (isWeb) {
    // On web, download each CSV individually (no zip support in browser without library)
    for (const file of csvFiles) {
      triggerWebDownload(file.content, file.name, 'text/csv');
    }
    return;
  }

  // Write each CSV to a temp directory
  await FileSystem.makeDirectoryAsync(exportDir, { intermediates: true });
  for (const file of csvFiles) {
    await FileSystem.writeAsStringAsync(`${exportDir}${file.name}`, file.content);
  }

  // Zip the directory
  const zipPath = `${FileSystem.cacheDirectory}sundee-fundee-export-${dateStr}.zip`;
  await zip(exportDir, zipPath);

  // Share the zip
  await Sharing.shareAsync(zipPath);
}
