/**
 * app/(app)/benchmarks/[id].tsx — Benchmark Detail, Recording, and History screen.
 *
 * Sections:
 * 1. Header: name, description, scoring type
 * 2. Record Result: scoring-aware input (time/reps/weight/distance/roundsAndReps)
 * 3. History: list of past results, newest first
 * 4. Improvement Chart: LineChart from react-native-gifted-charts (2+ results only)
 * 5. PR indicator: "New PR!" banner if latest result improves on previous best
 *
 * Respects CLAUDE.md convention: disable Save button for invalid input.
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useLocalSearchParams, useRouter } from 'expo-router';
import { format } from 'date-fns';
import { useSession } from '@/src/auth/AuthContext';
import {
  getBenchmarkRepo,
  type BenchmarkResultRecord,
} from '@/src/repositories/BenchmarkRepo';
import {
  BENCHMARK_CATALOG,
  encodeRoundsAndReps,
} from '@/src/domain/benchmarks/benchmark-catalog';
import { formatScore, isScoreImproved, parseTimeInput } from '@/src/components/benchmarks/scoring-input';
import { ProgressChart } from '@/src/components/charts/ProgressChart';
import type { ChartDataPoint } from '@/src/domain/progress/progress-data';
import type { BenchmarkScoringType } from '@/src/domain/types';
import * as colors from '@/src/theme/colors';

// ---------------------------------------------------------------------------
// Score input helpers (static for testability)
// ---------------------------------------------------------------------------

/** Build a BenchmarkResultRecord.score from the current form state. Returns NaN for invalid. */
export function buildScore(
  scoringType: BenchmarkScoringType,
  timeInput: string,
  repsInput: string,
  roundsInput: string,
  weightInput: string,
): number {
  switch (scoringType) {
    case 'time':
    case 'distance': {
      const secs = parseTimeInput(timeInput);
      return secs;
    }
    case 'reps': {
      const n = parseInt(repsInput, 10);
      return isNaN(n) ? NaN : n;
    }
    case 'roundsAndReps': {
      const rounds = parseInt(roundsInput, 10);
      const reps = parseInt(repsInput, 10);
      if (isNaN(rounds) || isNaN(reps)) return NaN;
      return encodeRoundsAndReps(rounds, reps);
    }
    case 'weight': {
      const w = parseFloat(weightInput);
      return isNaN(w) ? NaN : w;
    }
  }
}

/** Determine whether the current input is valid (non-NaN, positive). */
export function isInputValid(
  scoringType: BenchmarkScoringType,
  timeInput: string,
  repsInput: string,
  roundsInput: string,
  weightInput: string,
): boolean {
  const score = buildScore(scoringType, timeInput, repsInput, roundsInput, weightInput);
  return !isNaN(score) && score >= 0;
}

// ---------------------------------------------------------------------------
// Best score helper
// ---------------------------------------------------------------------------

/** Find the best (PR) score from a list of results. Returns null if empty. */
export function findBestScore(
  scoringType: BenchmarkScoringType,
  results: BenchmarkResultRecord[],
): number | null {
  if (results.length === 0) return null;
  return results.reduce<number>((best, r) => {
    if (isScoreImproved(scoringType, r.score, best)) return r.score;
    return best;
  }, results[0]!.score);
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function BenchmarkDetailScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isGuest } = useSession();
  const params = useLocalSearchParams<{
    id: string;
    name?: string;
    category?: string;
    description?: string;
    scoringType?: string;
    isPredefined?: string;
  }>();

  const benchmarkId = params.id;

  // Look up from catalog or use passed params
  const catalogEntry = BENCHMARK_CATALOG.find((b) => b.id === benchmarkId);
  const benchmarkName = catalogEntry?.name ?? params.name ?? 'Benchmark';
  const benchmarkDescription = catalogEntry?.workoutDescription ?? params.description ?? '';
  const scoringType: BenchmarkScoringType =
    (catalogEntry?.scoringType ?? params.scoringType ?? 'reps') as BenchmarkScoringType;

  // Form state
  const [timeInput, setTimeInput] = useState('');
  const [repsInput, setRepsInput] = useState('');
  const [roundsInput, setRoundsInput] = useState('');
  const [weightInput, setWeightInput] = useState('');
  const [notesInput, setNotesInput] = useState('');
  const [saving, setSaving] = useState(false);

  // Results state
  const [results, setResults] = useState<BenchmarkResultRecord[]>([]);
  const [loadingResults, setLoadingResults] = useState(true);
  const [prMessage, setPrMessage] = useState<string | null>(null);

  const loadResults = useCallback(async (): Promise<void> => {
    setLoadingResults(true);
    try {
      const uid = user?.uid ?? '';
      const loaded = await getBenchmarkRepo(isGuest).getResults(uid, benchmarkId);
      // Sort newest first
      const sorted = [...loaded].sort((a, b) => b.date.localeCompare(a.date));
      setResults(sorted);
    } catch {
      setResults([]);
    } finally {
      setLoadingResults(false);
    }
  }, [user, isGuest, benchmarkId]);

  useFocusEffect(
    useCallback(() => {
      void loadResults();
      setPrMessage(null);
    }, [loadResults]),
  );

  const inputValid = isInputValid(scoringType, timeInput, repsInput, roundsInput, weightInput);

  async function handleSave(): Promise<void> {
    if (!inputValid || saving) return;
    setSaving(true);
    try {
      const score = buildScore(scoringType, timeInput, repsInput, roundsInput, weightInput);
      const uid = user?.uid ?? '';
      const today = format(new Date(), 'yyyy-MM-dd');

      const record: BenchmarkResultRecord = {
        id: `${uid}-${benchmarkId}-${Date.now()}`,
        uid,
        benchmarkId,
        benchmarkName,
        scoringType,
        score,
        date: today,
        notes: notesInput.trim() || undefined,
      };

      await getBenchmarkRepo(isGuest).saveResult(uid, record);

      // Check for PR
      const best = findBestScore(scoringType, results);
      if (best === null || isScoreImproved(scoringType, score, best)) {
        setPrMessage('New PR!');
      } else {
        setPrMessage(null);
      }

      // Reset inputs
      setTimeInput('');
      setRepsInput('');
      setRoundsInput('');
      setWeightInput('');
      setNotesInput('');

      // Reload
      await loadResults();
    } catch {
      Alert.alert('Error', 'Failed to save result. Please try again.');
    } finally {
      setSaving(false);
    }
  }

  // Build chart data (oldest first for line chart)
  const chartData: ChartDataPoint[] = results
    .slice()
    .reverse()
    .map((r) => ({
      date: r.date,
      // For time/distance, invert for chart display so visual "up" = better
      value: scoringType === 'time' || scoringType === 'distance' ? -r.score : r.score,
    }));

  const showChart = results.length >= 2;

  function renderScoreInput(): React.JSX.Element {
    switch (scoringType) {
      case 'time':
      case 'distance':
        return (
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Time (MM:SS)</Text>
            <TextInput
              style={styles.input}
              value={timeInput}
              onChangeText={setTimeInput}
              placeholder="5:30"
              placeholderTextColor={colors.GREY}
              keyboardType="numbers-and-punctuation"
              testID="time-input"
            />
          </View>
        );

      case 'reps':
        return (
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Reps</Text>
            <TextInput
              style={styles.input}
              value={repsInput}
              onChangeText={setRepsInput}
              placeholder="21"
              placeholderTextColor={colors.GREY}
              keyboardType="number-pad"
              testID="reps-input"
            />
          </View>
        );

      case 'roundsAndReps':
        return (
          <View style={styles.inputRowGroup}>
            <View style={[styles.inputRow, styles.inputRowHalf]}>
              <Text style={styles.inputLabel}>Rounds</Text>
              <TextInput
                style={styles.input}
                value={roundsInput}
                onChangeText={setRoundsInput}
                placeholder="5"
                placeholderTextColor={colors.GREY}
                keyboardType="number-pad"
                testID="rounds-input"
              />
            </View>
            <View style={[styles.inputRow, styles.inputRowHalf]}>
              <Text style={styles.inputLabel}>+ Reps</Text>
              <TextInput
                style={styles.input}
                value={repsInput}
                onChangeText={setRepsInput}
                placeholder="3"
                placeholderTextColor={colors.GREY}
                keyboardType="number-pad"
                testID="reps-input"
              />
            </View>
          </View>
        );

      case 'weight':
        return (
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Weight (lbs)</Text>
            <TextInput
              style={styles.input}
              value={weightInput}
              onChangeText={setWeightInput}
              placeholder="315"
              placeholderTextColor={colors.GREY}
              keyboardType="decimal-pad"
              testID="weight-input"
            />
          </View>
        );
    }
  }

  const SCORING_LABEL: Record<string, string> = {
    time: 'For Time',
    reps: 'Max Reps',
    roundsAndReps: 'AMRAP',
    weight: 'Max Load',
    distance: 'Distance/Time',
  };

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.container}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.headerSection}>
          <Text style={styles.benchmarkName}>{benchmarkName}</Text>
          <View style={styles.scoringBadge}>
            <Text style={styles.scoringBadgeText}>
              {SCORING_LABEL[scoringType] ?? scoringType}
            </Text>
          </View>
          {benchmarkDescription.length > 0 && (
            <Text style={styles.description}>{benchmarkDescription}</Text>
          )}
        </View>

        {/* PR Banner */}
        {prMessage != null && (
          <View style={styles.prBanner}>
            <Text style={styles.prBannerText}>{prMessage}</Text>
          </View>
        )}

        {/* Record Result */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Record Result</Text>
          {renderScoreInput()}

          {/* Notes */}
          <View style={styles.inputRow}>
            <Text style={styles.inputLabel}>Notes (optional)</Text>
            <TextInput
              style={[styles.input, styles.notesInput]}
              value={notesInput}
              onChangeText={setNotesInput}
              placeholder="How did it feel?"
              placeholderTextColor={colors.GREY}
              multiline
              numberOfLines={2}
              testID="notes-input"
            />
          </View>

          <TouchableOpacity
            style={[styles.saveButton, !inputValid && styles.saveButtonDisabled]}
            onPress={() => void handleSave()}
            disabled={!inputValid || saving}
            activeOpacity={0.8}
            testID="save-result-button"
          >
            <Text style={styles.saveButtonText}>
              {saving ? 'Saving...' : 'Save Result'}
            </Text>
          </TouchableOpacity>
        </View>

        {/* History */}
        {loadingResults ? (
          <ActivityIndicator color={colors.ORANGE} style={{ marginVertical: 24 }} />
        ) : results.length > 0 ? (
          <View style={styles.card}>
            <Text style={styles.cardTitle}>History</Text>
            {results.map((r) => (
              <View key={r.id} style={styles.historyRow}>
                <View style={styles.historyMeta}>
                  <Text style={styles.historyDate}>{r.date}</Text>
                  {r.notes != null && r.notes.length > 0 && (
                    <Text style={styles.historyNotes} numberOfLines={1}>
                      {r.notes}
                    </Text>
                  )}
                </View>
                <Text style={styles.historyScore}>{formatScore(scoringType, r.score)}</Text>
              </View>
            ))}
          </View>
        ) : null}

        {/* Improvement Chart */}
        {showChart && (
          <View style={styles.card}>
            <ProgressChart
              data={chartData}
              title="Score Progression"
              yLabel={scoringType === 'weight' ? 'lbs' : scoringType === 'reps' ? 'reps' : ''}
            />
          </View>
        )}
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  scrollView: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  container: {
    paddingHorizontal: 16,
    paddingTop: 24,
    paddingBottom: 40,
    gap: 16,
  },
  headerSection: {
    gap: 8,
  },
  benchmarkName: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.5,
  },
  scoringBadge: {
    alignSelf: 'flex-start',
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 6,
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: colors.ORANGE,
  },
  scoringBadgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.5,
  },
  description: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },
  prBanner: {
    backgroundColor: colors.ORANGE,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  prBannerText: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 1,
  },
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    padding: 16,
    gap: 12,
  },
  cardTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 4,
  },
  inputRow: {
    gap: 6,
  },
  inputRowGroup: {
    flexDirection: 'row',
    gap: 12,
  },
  inputRowHalf: {
    flex: 1,
  },
  inputLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.NAVY_MEDIUM,
  },
  input: {
    backgroundColor: colors.CREAM,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 12,
    fontSize: 16,
    color: colors.NAVY,
  },
  notesInput: {
    minHeight: 56,
    textAlignVertical: 'top',
  },
  saveButton: {
    backgroundColor: colors.ORANGE,
    borderRadius: 10,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 4,
  },
  saveButtonDisabled: {
    backgroundColor: colors.GREY,
  },
  saveButtonText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  historyMeta: {
    flex: 1,
    gap: 2,
  },
  historyDate: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.NAVY_MEDIUM,
  },
  historyNotes: {
    fontSize: 11,
    color: colors.GREY,
  },
  historyScore: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
});
