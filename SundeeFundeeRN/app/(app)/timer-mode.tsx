/**
 * app/(app)/timer-mode.tsx — Full-screen timed workout execution screen.
 *
 * Accepts route params:
 * - mode: 'forTime' | 'amrap' | 'emom'
 * - durationSeconds: number (total time; for forTime, used as optional time cap)
 * - exerciseList: JSON-encoded string of exercise name strings
 *
 * Features:
 * - CountdownOverlay with 3-2-1-Go before timer starts
 * - Large TimerDisplay (ForTime counts up, AMRAP counts down with urgency,
 *   EMOM shows minute counter)
 * - EMOMClock for EMOM mode
 * - Scrollable exercise list with current minute reference
 * - AMRAP round counter + "Complete Round" button
 * - Pause/Resume and Stop controls
 * - Screen stays awake during timer (expo-keep-awake)
 * - Completion state with results summary
 */

import React, { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { activateKeepAwakeAsync, deactivateKeepAwake } from 'expo-keep-awake';
import { useWorkoutTimer } from '@/src/hooks/useWorkoutTimer';
import { TimerDisplay } from '@/src/components/timer/TimerDisplay';
import { CountdownOverlay } from '@/src/components/timer/CountdownOverlay';
import { EMOMClock } from '@/src/components/timer/EMOMClock';
import { getRemainingMs } from '@/src/domain/timers/timer-state';
import {
  CREAM,
  CREAM_LIGHT,
  GREY,
  GREY_LIGHT,
  NAVY,
  NAVY_DARK,
  ORANGE,
  ORANGE_DARK,
  RED,
} from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

type TimerModeParam = 'forTime' | 'amrap' | 'emom';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function parseExerciseList(raw: string | undefined): string[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function isValidMode(mode: string | undefined): mode is TimerModeParam {
  return mode === 'forTime' || mode === 'amrap' || mode === 'emom';
}

function formatMs(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export default function TimerModeScreen(): React.JSX.Element {
  const router = useRouter();
  const params = useLocalSearchParams<{
    mode: string;
    durationSeconds: string;
    exerciseList: string;
  }>();

  const mode = isValidMode(params.mode) ? params.mode : 'forTime';
  const durationSeconds = params.durationSeconds ? parseInt(params.durationSeconds, 10) : 600;
  const exercises = parseExerciseList(params.exerciseList);
  const totalMinutes = Math.round(durationSeconds / 60);

  const timer = useWorkoutTimer();
  const [started, setStarted] = useState(false);

  // ── Screen wake lock ────────────────────────────────────────────────────

  useEffect(() => {
    void activateKeepAwakeAsync();
    return () => {
      deactivateKeepAwake();
    };
  }, []);

  // ── Auto-start on mount ─────────────────────────────────────────────────

  useEffect(() => {
    if (started) return;
    setStarted(true);

    if (mode === 'forTime') {
      timer.startForTime(durationSeconds > 0 ? durationSeconds : undefined);
    } else if (mode === 'amrap') {
      timer.startAMRAP(durationSeconds);
    } else if (mode === 'emom') {
      timer.startEMOM(totalMinutes);
    }
  // Only run once on mount
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Derived display values ───────────────────────────────────────────────

  const remainingInMinuteMs =
    timer.timerState !== null && mode === 'emom'
      ? Math.max(
          0,
          60_000 - (getRemainingMs(timer.timerState) % 60_000 || 60_000),
        )
      : 0;

  // Urgency: AMRAP with < 30 seconds remaining
  const isUrgent =
    mode === 'amrap' &&
    timer.timerState !== null &&
    getRemainingMs(timer.timerState) < 30_000 &&
    !timer.isComplete;

  // ── Controls ────────────────────────────────────────────────────────────

  const handlePauseResume = useCallback(() => {
    if (timer.isPaused) {
      timer.resume();
    } else {
      timer.pause();
    }
  }, [timer]);

  const handleStop = useCallback(() => {
    const confirmTitle = 'End Workout?';
    const confirmMessage = 'Your current progress will be saved and the timer stopped.';

    if (Platform.OS === 'web') {
      if (window.confirm(`${confirmTitle}\n${confirmMessage}`)) {
        timer.stop();
        router.back();
      }
    } else {
      Alert.alert(
        confirmTitle,
        confirmMessage,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'End Workout',
            style: 'destructive',
            onPress: () => {
              timer.stop();
              router.back();
            },
          },
        ],
        { cancelable: true },
      );
    }
  }, [timer, router]);

  const handleDone = useCallback(() => {
    timer.stop();
    router.back();
  }, [timer, router]);

  // ── Completion screen ────────────────────────────────────────────────────

  if (timer.isComplete) {
    return (
      <SafeAreaView style={styles.completionContainer}>
        <View style={styles.completionContent}>
          <Text style={styles.completionTitle}>WORKOUT COMPLETE</Text>
          <Text style={styles.completionMode}>{mode.toUpperCase()}</Text>

          {mode === 'amrap' && (
            <View style={styles.resultRow}>
              <Text style={styles.resultLabel}>ROUNDS</Text>
              <Text style={styles.resultValue}>{timer.roundsCompleted}</Text>
            </View>
          )}

          {mode === 'forTime' && (
            <View style={styles.resultRow}>
              <Text style={styles.resultLabel}>FINAL TIME</Text>
              <Text style={styles.resultValue}>{timer.displayTime}</Text>
            </View>
          )}

          <TouchableOpacity
            style={styles.doneButton}
            onPress={handleDone}
            activeOpacity={0.8}
            testID="done-button"
          >
            <Text style={styles.doneButtonText}>DONE</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  // ── Active timer screen ──────────────────────────────────────────────────

  return (
    <SafeAreaView style={styles.container}>
      {/* 3-2-1-Go overlay */}
      <CountdownOverlay
        visible={timer.isCountingDown}
        countdownValue={timer.countdownValue}
      />

      {/* Pause overlay */}
      {timer.isPaused && (
        <View style={styles.pauseOverlay} pointerEvents="none">
          <Text style={styles.pauseLabel}>PAUSED</Text>
        </View>
      )}

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        scrollEnabled={!timer.isCountingDown}
      >
        {/* Timer display */}
        <View style={styles.timerSection}>
          {mode === 'emom' ? (
            <EMOMClock
              currentMinute={timer.currentMinute}
              totalMinutes={totalMinutes}
              remainingInMinuteMs={remainingInMinuteMs}
            />
          ) : (
            <TimerDisplay
              mode={mode}
              displayTime={timer.displayTime}
              isUrgent={isUrgent}
            />
          )}
        </View>

        {/* AMRAP round counter */}
        {mode === 'amrap' && (
          <View style={styles.amrapSection}>
            <View style={styles.roundCounter}>
              <Text style={styles.roundCounterLabel}>ROUNDS</Text>
              <Text style={styles.roundCounterValue}>{timer.roundsCompleted}</Text>
            </View>
            <TouchableOpacity
              style={styles.completeRoundButton}
              onPress={timer.incrementRound}
              activeOpacity={0.8}
              testID="complete-round-button"
            >
              <Text style={styles.completeRoundText}>+ COMPLETE ROUND</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* EMOM per-minute display */}
        {mode === 'emom' && (
          <View style={styles.emomTimeRow}>
            <TimerDisplay
              mode="emom"
              displayTime={timer.displayTime}
              currentMinute={timer.currentMinute}
              totalMinutes={totalMinutes}
              remainingInMinute={formatMs(remainingInMinuteMs)}
            />
          </View>
        )}

        {/* Exercise list */}
        {exercises.length > 0 && (
          <View style={styles.exerciseSection}>
            <Text style={styles.exerciseSectionTitle}>EXERCISES</Text>
            {exercises.map((exercise, index) => (
              <View key={index} style={styles.exerciseRow}>
                <Text style={styles.exerciseIndex}>{index + 1}</Text>
                <Text style={styles.exerciseName}>{exercise}</Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>

      {/* Control bar */}
      <View style={styles.controlBar}>
        <TouchableOpacity
          style={[styles.controlButton, styles.pauseButton]}
          onPress={handlePauseResume}
          activeOpacity={0.8}
          testID="pause-resume-button"
        >
          <Text style={styles.pauseButtonText}>
            {timer.isPaused ? 'RESUME' : 'PAUSE'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.controlButton, styles.stopButton]}
          onPress={handleStop}
          activeOpacity={0.8}
          testID="stop-button"
        >
          <Text style={styles.stopButtonText}>STOP</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: NAVY,
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 120,
  },
  timerSection: {
    alignItems: 'center',
    marginBottom: 24,
  },
  // AMRAP round counter
  amrapSection: {
    alignItems: 'center',
    marginBottom: 24,
  },
  roundCounter: {
    alignItems: 'center',
    marginBottom: 16,
  },
  roundCounterLabel: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 4,
    color: GREY,
    marginBottom: 4,
  },
  roundCounterValue: {
    fontSize: 64,
    fontWeight: '700',
    color: CREAM,
    fontVariant: ['tabular-nums'],
  },
  completeRoundButton: {
    backgroundColor: ORANGE,
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 32,
  },
  completeRoundText: {
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 2,
    color: NAVY_DARK,
  },
  // EMOM time row
  emomTimeRow: {
    marginBottom: 24,
  },
  // Exercise list
  exerciseSection: {
    backgroundColor: NAVY_DARK,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: GREY,
    opacity: 0.9,
  },
  exerciseSectionTitle: {
    fontSize: 11,
    fontWeight: '700',
    letterSpacing: 4,
    color: ORANGE,
    marginBottom: 12,
  },
  exerciseRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: GREY,
  },
  exerciseIndex: {
    fontSize: 13,
    fontWeight: '700',
    color: ORANGE,
    width: 24,
  },
  exerciseName: {
    fontSize: 15,
    color: CREAM,
    flex: 1,
  },
  // Control bar
  controlBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    flexDirection: 'row',
    paddingHorizontal: 20,
    paddingBottom: 32,
    paddingTop: 12,
    backgroundColor: NAVY_DARK,
    borderTopWidth: 1,
    borderTopColor: GREY,
    gap: 12,
  },
  controlButton: {
    flex: 1,
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pauseButton: {
    backgroundColor: ORANGE,
    flex: 2,
  },
  pauseButtonText: {
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 2,
    color: NAVY_DARK,
  },
  stopButton: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: RED,
    flex: 1,
  },
  stopButtonText: {
    fontSize: 15,
    fontWeight: '700',
    letterSpacing: 2,
    color: RED,
  },
  // Pause overlay
  pauseOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
  },
  pauseLabel: {
    fontSize: 32,
    fontWeight: '900',
    letterSpacing: 8,
    color: CREAM,
  },
  // Completion screen
  completionContainer: {
    flex: 1,
    backgroundColor: NAVY,
  },
  completionContent: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  completionTitle: {
    fontSize: 22,
    fontWeight: '900',
    letterSpacing: 4,
    color: ORANGE,
    marginBottom: 8,
    textAlign: 'center',
  },
  completionMode: {
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 4,
    color: GREY,
    marginBottom: 40,
  },
  resultRow: {
    alignItems: 'center',
    marginBottom: 40,
  },
  resultLabel: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 4,
    color: GREY,
    marginBottom: 8,
  },
  resultValue: {
    fontSize: 64,
    fontWeight: '700',
    color: CREAM,
    fontVariant: ['tabular-nums'],
  },
  doneButton: {
    backgroundColor: ORANGE,
    borderRadius: 12,
    paddingVertical: 18,
    paddingHorizontal: 48,
    marginTop: 16,
  },
  doneButtonText: {
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 3,
    color: NAVY_DARK,
  },
});
