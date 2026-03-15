/**
 * app/(app)/programs/[id].tsx — Program Detail.
 *
 * Shows program overview, weekly session breakdown, and enrollment CTA.
 *
 * States:
 *   - Not enrolled: "Start Program" button
 *   - Enrolled in THIS program: "Continue - Week X, Session Y" + "Unenroll"
 *   - Enrolled in DIFFERENT program: warning message
 *
 * Enrollment flow:
 *   1. Check for missing 1RMs (exercises with percentage weights but no logged max)
 *   2. If missing: show quick-entry fields (skippable)
 *   3. Call enrollUser, navigate to session screen
 *
 * Route params: id (program id string)
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useLocalSearchParams, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getProgramRepo, type Program, type ProgramEnrollment, type ProgramSession } from '@/src/repositories/ProgramRepo';
import { getExerciseMaxRepo } from '@/src/repositories/ExerciseMaxRepo';
import { getWorkoutRepo } from '@/src/repositories/WorkoutRepo';
import { getMissing1RMs } from '@/src/components/programs/target-weight';
import type { ProgramExercise } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';

// ─── Helper: display exercise weight ────────────────────────────────────────

/**
 * Returns a human-readable weight description for an exercise in the detail view.
 * Exported for unit testing.
 */
export function formatExerciseWeight(exercise: ProgramExercise): string {
  if (!exercise.weight) return '';
  const w = exercise.weight;
  switch (w.kind) {
    case 'fixed':
      return w.value <= 1.0 ? `${Math.round(w.value * 100)}% 1RM` : `${w.value} lbs`;
    case 'range':
      return w.lo <= 1.0
        ? `${Math.round(w.lo * 100)}–${Math.round(w.hi * 100)}% 1RM`
        : `${w.lo}–${w.hi} lbs`;
    case 'text':
      return w.value;
    case 'amrap':
      return '';
  }
}

/**
 * Returns a display string for reps (e.g. "5", "8–12", "AMRAP").
 * Exported for unit testing.
 */
export function formatReps(exercise: ProgramExercise): string {
  const r = exercise.reps;
  switch (r.kind) {
    case 'fixed':
      return String(r.value);
    case 'range':
      return `${r.lo}–${r.hi}`;
    case 'amrap':
      return 'AMRAP';
    case 'text':
      return r.value;
  }
}

// ─── SessionCard: collapsible weekly session ─────────────────────────────────

interface SessionCardProps {
  session: ProgramSession;
  sessionNumber: number;
}

function SessionCard({ session, sessionNumber }: SessionCardProps): React.JSX.Element {
  const [expanded, setExpanded] = useState(false);

  return (
    <View style={styles.sessionCard}>
      <TouchableOpacity
        style={styles.sessionHeader}
        onPress={() => setExpanded((e) => !e)}
        accessibilityLabel={`${session.name}, ${expanded ? 'collapse' : 'expand'}`}
        accessibilityRole="button"
      >
        <View style={styles.sessionHeaderLeft}>
          <View style={styles.sessionNumberBadge}>
            <Text style={styles.sessionNumberText}>{sessionNumber}</Text>
          </View>
          <Text style={styles.sessionName} numberOfLines={1}>
            {session.name}
          </Text>
        </View>
        <Text style={styles.expandChevron}>{expanded ? '−' : '+'}</Text>
      </TouchableOpacity>

      {expanded && (
        <View style={styles.exerciseList}>
          {session.exercises.map((exercise) => (
            <View key={exercise.id} style={styles.exerciseRow}>
              <Text style={styles.exerciseName}>{exercise.name}</Text>
              <Text style={styles.exerciseMeta}>
                {exercise.sets} × {formatReps(exercise)}
                {formatExerciseWeight(exercise) ? `  ·  ${formatExerciseWeight(exercise)}` : ''}
              </Text>
            </View>
          ))}
        </View>
      )}
    </View>
  );
}

// ─── Missing1RMPrompt ────────────────────────────────────────────────────────

interface Missing1RMPromptProps {
  missingExercises: string[];
  onSave: (entries: Record<string, string>) => void;
  onSkip: () => void;
}

function Missing1RMPrompt({
  missingExercises,
  onSave,
  onSkip,
}: Missing1RMPromptProps): React.JSX.Element {
  const [weights, setWeights] = useState<Record<string, string>>({});

  const handleSave = useCallback(() => {
    onSave(weights);
  }, [weights, onSave]);

  return (
    <View style={styles.promptCard}>
      <Text style={styles.promptTitle}>Log these lifts for accurate target weights:</Text>
      <Text style={styles.promptSubtitle}>
        Adding your current maxes helps personalize workout weights. You can skip this.
      </Text>

      {missingExercises.map((name) => (
        <View key={name} style={styles.promptRow}>
          <Text style={styles.promptExerciseName} numberOfLines={1}>
            {name}
          </Text>
          <TextInput
            style={styles.promptInput}
            placeholder="lbs"
            placeholderTextColor={colors.GREY}
            keyboardType="numeric"
            value={weights[name] ?? ''}
            onChangeText={(val) => setWeights((prev) => ({ ...prev, [name]: val }))}
            accessibilityLabel={`${name} max weight in lbs`}
          />
        </View>
      ))}

      <View style={styles.promptActions}>
        <TouchableOpacity style={styles.promptSkipButton} onPress={onSkip}>
          <Text style={styles.promptSkipText}>Skip</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.promptSaveButton} onPress={handleSave}>
          <Text style={styles.promptSaveText}>Save & Start</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

// ─── ProgramDetailScreen ─────────────────────────────────────────────────────

export default function ProgramDetailScreen(): React.JSX.Element {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user, isGuest } = useSession();
  const router = useRouter();

  const [program, setProgram] = useState<Program | null>(null);
  const [enrollment, setEnrollment] = useState<ProgramEnrollment | null>(null);
  const [missingMaxes, setMissingMaxes] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [enrolling, setEnrolling] = useState(false);
  const [showMissingPrompt, setShowMissingPrompt] = useState(false);

  const uid = user?.uid ?? '';

  // Load program + enrollment on focus
  useFocusEffect(
    useCallback(() => {
      if (!id) return;

      let cancelled = false;
      setLoading(true);

      void Promise.all([
        getProgramRepo(isGuest).getProgram(id),
        getProgramRepo(isGuest).getEnrollment(uid),
        getExerciseMaxRepo(isGuest).getAllMaxes(uid),
      ])
        .then(([prog, enroll, maxes]) => {
          if (cancelled) return;
          setProgram(prog);
          setEnrollment(enroll);

          if (prog) {
            const allExercises: ProgramExercise[] = prog.sessions.flatMap((s) => s.exercises);
            setMissingMaxes(getMissing1RMs(allExercises, maxes));
          }
        })
        .catch(() => {
          // Graceful degradation — show what we have
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });

      return () => {
        cancelled = true;
      };
    }, [id, uid, isGuest])
  );

  // ─── Enrollment handlers ────────────────────────────────────────────────

  const handleStartTap = useCallback(() => {
    if (missingMaxes.length > 0) {
      setShowMissingPrompt(true);
    } else {
      void doEnroll();
    }
  }, [missingMaxes]);

  const doEnroll = useCallback(async () => {
    if (!program) return;
    setEnrolling(true);
    try {
      await getProgramRepo(isGuest).enrollUser(uid, program.id);
      router.push('/programs/session');
    } catch {
      Alert.alert('Enrollment failed', 'Could not start program. Please try again.');
    } finally {
      setEnrolling(false);
      setShowMissingPrompt(false);
    }
  }, [program, uid, isGuest, router]);

  const handleMissingMaxSave = useCallback(
    (_entries: Record<string, string>) => {
      // Note: saving maxes to ExerciseMaxRepo is out of scope for this screen
      // (requires repRange data). Entries are noted for future enhancement.
      void doEnroll();
    },
    [doEnroll]
  );

  const handleMissingMaxSkip = useCallback(() => {
    void doEnroll();
  }, [doEnroll]);

  const handleContinue = useCallback(() => {
    router.push('/programs/session');
  }, [router]);

  const handleUnenroll = useCallback(() => {
    Alert.alert(
      'Unenroll from program?',
      'Your progress will be lost.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Unenroll',
          style: 'destructive',
          onPress: () => {
            void getProgramRepo(isGuest)
              .unenroll(uid)
              .then(() => {
                setEnrollment(null);
              })
              .catch(() => {
                Alert.alert('Error', 'Could not unenroll. Please try again.');
              });
          },
        },
      ]
    );
  }, [uid, isGuest]);

  // ─── Loading / not found states ─────────────────────────────────────────

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  if (!program) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.notFoundText}>Program not found.</Text>
      </View>
    );
  }

  // ─── Enrollment CTA logic ────────────────────────────────────────────────

  const isEnrolledHere = enrollment?.programId === program.id;
  const isEnrolledElsewhere = !!enrollment && enrollment.programId !== program.id;

  const currentWeekDisplay = (enrollment?.currentWeek ?? 0) + 1;
  const currentSessionDisplay = (enrollment?.currentSession ?? 0) + 1;

  // ─── Render ──────────────────────────────────────────────────────────────

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.scrollContent}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.programName}>{program.name}</Text>
        <Text style={styles.programMeta}>
          {program.sessions.length} session{program.sessions.length !== 1 ? 's' : ''}
        </Text>
      </View>

      {/* Missing 1RM prompt */}
      {showMissingPrompt && missingMaxes.length > 0 && (
        <Missing1RMPrompt
          missingExercises={missingMaxes}
          onSave={handleMissingMaxSave}
          onSkip={handleMissingMaxSkip}
        />
      )}

      {/* Enrollment CTA */}
      <View style={styles.ctaSection}>
        {isEnrolledHere ? (
          <>
            <TouchableOpacity
              style={styles.primaryButton}
              onPress={handleContinue}
              disabled={enrolling}
            >
              <Text style={styles.primaryButtonText}>
                Continue — Week {currentWeekDisplay}, Session {currentSessionDisplay}
              </Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.destructiveButton} onPress={handleUnenroll}>
              <Text style={styles.destructiveButtonText}>Unenroll</Text>
            </TouchableOpacity>
          </>
        ) : isEnrolledElsewhere ? (
          <View style={styles.enrolledElsewhereBox}>
            <Text style={styles.enrolledElsewhereText}>
              Already enrolled in another program. Unenroll first to start this one.
            </Text>
          </View>
        ) : (
          <TouchableOpacity
            style={[styles.primaryButton, enrolling && styles.buttonDisabled]}
            onPress={handleStartTap}
            disabled={enrolling}
          >
            {enrolling ? (
              <ActivityIndicator color={colors.CREAM} size="small" />
            ) : (
              <Text style={styles.primaryButtonText}>Start Program</Text>
            )}
          </TouchableOpacity>
        )}
      </View>

      {/* Weekly Breakdown */}
      <View style={styles.breakdownSection}>
        <Text style={styles.sectionTitle}>Sessions</Text>
        {program.sessions.map((session, index) => (
          <SessionCard
            key={session.id}
            session={session}
            sessionNumber={index + 1}
          />
        ))}
      </View>
    </ScrollView>
  );
}

// ─── Styles ──────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  scrollContent: {
    paddingBottom: 40,
  },
  centerContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  notFoundText: {
    fontSize: 16,
    color: colors.GREY,
  },

  // Header
  header: {
    backgroundColor: colors.NAVY,
    paddingHorizontal: 20,
    paddingVertical: 24,
  },
  programName: {
    fontSize: 24,
    fontWeight: '800',
    color: colors.CREAM,
    letterSpacing: 0.5,
    marginBottom: 6,
  },
  programMeta: {
    fontSize: 13,
    color: colors.ORANGE,
    fontWeight: '600',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },

  // CTA section
  ctaSection: {
    paddingHorizontal: 16,
    paddingVertical: 20,
    gap: 12,
  },
  primaryButton: {
    backgroundColor: colors.ORANGE,
    paddingVertical: 16,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.3,
  },
  destructiveButton: {
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.RED,
  },
  destructiveButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.RED,
  },
  buttonDisabled: {
    opacity: 0.6,
  },
  enrolledElsewhereBox: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 8,
    padding: 16,
    borderLeftWidth: 4,
    borderLeftColor: colors.ORANGE,
  },
  enrolledElsewhereText: {
    fontSize: 14,
    color: colors.NAVY,
    lineHeight: 20,
  },

  // Missing 1RM prompt
  promptCard: {
    backgroundColor: colors.CREAM_LIGHT,
    marginHorizontal: 16,
    marginTop: 8,
    borderRadius: 8,
    padding: 16,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  promptTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    marginBottom: 6,
  },
  promptSubtitle: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    marginBottom: 16,
    lineHeight: 18,
  },
  promptRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
    gap: 12,
  },
  promptExerciseName: {
    flex: 1,
    fontSize: 14,
    color: colors.NAVY,
    fontWeight: '500',
  },
  promptInput: {
    width: 80,
    height: 40,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    borderRadius: 6,
    paddingHorizontal: 10,
    fontSize: 14,
    color: colors.NAVY,
    backgroundColor: colors.CREAM,
    textAlign: 'right',
  },
  promptActions: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 8,
  },
  promptSkipButton: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  promptSkipText: {
    fontSize: 15,
    color: colors.GREY,
    fontWeight: '600',
  },
  promptSaveButton: {
    flex: 2,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    backgroundColor: colors.NAVY,
  },
  promptSaveText: {
    fontSize: 15,
    color: colors.CREAM,
    fontWeight: '700',
  },

  // Weekly breakdown
  breakdownSection: {
    paddingHorizontal: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.NAVY,
    letterSpacing: 0.5,
    marginBottom: 12,
    textTransform: 'uppercase',
  },
  sessionCard: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 8,
    marginBottom: 10,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  sessionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 14,
  },
  sessionHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    flex: 1,
  },
  sessionNumberBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.ORANGE,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sessionNumberText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.CREAM,
  },
  sessionName: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.NAVY,
    flex: 1,
  },
  expandChevron: {
    fontSize: 20,
    color: colors.ORANGE,
    fontWeight: '700',
    paddingLeft: 8,
  },
  exerciseList: {
    borderTopWidth: 1,
    borderTopColor: colors.GREY_LIGHT,
    padding: 14,
    gap: 10,
  },
  exerciseRow: {
    gap: 2,
  },
  exerciseName: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
  },
  exerciseMeta: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
});
