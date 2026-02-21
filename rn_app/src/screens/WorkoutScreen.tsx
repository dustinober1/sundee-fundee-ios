import React, { useEffect, useMemo, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import ArtDecoButton from '../components/ArtDecoButton';
import ArtDecoCard from '../components/ArtDecoCard';
import { getProgramById } from '../data/programs';
import {
  getActiveCycle,
  saveCompletedWorkout,
  startCycle,
  updateActiveCycleProgress,
  type LoggedSetInput,
} from '../lib/db';
import { normalizeProgram } from '../lib/programs';
import { roundToNearestFive } from '../lib/utils';
import { triggerSetLoggedHaptic } from '../native/haptics';
import { scheduleRestTimerNotification } from '../native/notifications';
import { artDecoTheme } from '../theme/tokens';

interface LoggedSetView extends LoggedSetInput {
  id: string;
}

export default function WorkoutScreen({
  programId,
  onWorkoutCompleted,
}: {
  programId: string;
  onWorkoutCompleted: () => void;
}) {
  const [activeWeek, setActiveWeek] = useState(1);
  const [activeCycleId, setActiveCycleId] = useState<string | null>(null);
  const [loggedSets, setLoggedSets] = useState<LoggedSetView[]>([]);
  const [isSaving, setIsSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [startedAt] = useState(() => Date.now());

  const normalizedProgram = useMemo(() => {
    const program = getProgramById(programId);
    return program ? normalizeProgram(program) : null;
  }, [programId]);

  const activeSession = useMemo(() => {
    if (!normalizedProgram) return null;
    const week = normalizedProgram.weeks.find(w => w.week === activeWeek) ?? normalizedProgram.weeks[0];
    return week.sessions[0] ?? null;
  }, [activeWeek, normalizedProgram]);

  useEffect(() => {
    if (!normalizedProgram) return;

    const loadCycle = async () => {
      try {
        const existingCycle = await getActiveCycle();
        if (existingCycle && existingCycle.programId === normalizedProgram.id) {
          setActiveCycleId(existingCycle.id);
          setActiveWeek(existingCycle.currentWeek);
          return;
        }

        const cycle = await startCycle({
          programId: normalizedProgram.id,
          cycleName: normalizedProgram.name,
          currentWeek: 1,
          currentSessionId: normalizedProgram.weeks[0]?.sessions[0]?.sessionId ?? null,
          currentPhase: null,
        });
        setActiveCycleId(cycle.id);
        setActiveWeek(cycle.currentWeek);
      } catch (error) {
        setErrorMessage(String(error));
      }
    };

    void loadCycle();
  }, [normalizedProgram]);

  if (!normalizedProgram || !activeSession) {
    return (
      <View style={styles.emptyState}>
        <Text style={styles.emptyText}>Unable to load workout session.</Text>
      </View>
    );
  }

  async function handleLogSet(exerciseId: string, prescribedReps: number, prescribedWeight: number) {
    const setNumber =
      loggedSets.filter(item => item.exerciseId === exerciseId).length + 1;
    const loggedSet: LoggedSetView = {
      id: `${exerciseId}-${setNumber}-${Date.now()}`,
      exerciseId,
      setNumber,
      prescribedWeight,
      actualWeight: prescribedWeight,
      prescribedReps,
      actualReps: prescribedReps,
    };

    setLoggedSets(previous => [...previous, loggedSet]);
    await triggerSetLoggedHaptic();
    await scheduleRestTimerNotification(90, exerciseId);
  }

  async function handleCompleteWorkout() {
    const currentProgram = normalizedProgram;
    const currentSession = activeSession;
    if (!currentProgram || !currentSession) {
      setErrorMessage('Program session is unavailable.');
      return;
    }

    if (loggedSets.length === 0) {
      setErrorMessage('Log at least one set before completing the workout.');
      return;
    }

    setIsSaving(true);
    setErrorMessage(null);
    try {
      const elapsedSeconds = Math.max(30, Math.round((Date.now() - startedAt) / 1000));
      await saveCompletedWorkout({
        activeCycleId,
        programId: currentProgram.id,
        week: activeWeek,
        sessionId: currentSession.sessionId,
        durationSeconds: elapsedSeconds,
        sets: loggedSets,
      });

      if (activeCycleId) {
        const nextWeek = Math.min(activeWeek + 1, currentProgram.durationWeeks);
        await updateActiveCycleProgress({
          cycleId: activeCycleId,
          currentWeek: nextWeek,
          currentSessionId: currentSession.sessionId,
          currentPhase: null,
        });
      }

      onWorkoutCompleted();
    } catch (error) {
      setErrorMessage(String(error));
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>{activeSession.sessionName}</Text>
        <Text style={styles.subtitle}>Week {activeWeek}</Text>
        {activeSession.exercises.map(exercise => {
          const prescribedWeight = roundToNearestFive(exercise.percent1RM * 100);
          return (
            <ArtDecoCard key={exercise.exercise} style={styles.exerciseCard}>
              <Text style={styles.exerciseName}>{exercise.exercise}</Text>
              <Text style={styles.exerciseMeta}>
                {exercise.sets} sets × {exercise.reps} reps @ {Math.round(exercise.percent1RM * 100)}%
              </Text>
              <Text style={styles.exerciseMeta}>Suggested weight: {prescribedWeight} lbs</Text>
              <ArtDecoButton
                title="Log set"
                variant="secondary"
                onPress={() =>
                  handleLogSet(exercise.exercise, exercise.reps, prescribedWeight).catch(error =>
                    setErrorMessage(String(error))
                  )
                }
              />
            </ArtDecoCard>
          );
        })}

        <ArtDecoCard>
          <Text style={styles.exerciseName}>Logged sets: {loggedSets.length}</Text>
          {loggedSets.map(set => (
            <Text key={set.id} style={styles.loggedSet}>
              • {set.exerciseId} set {set.setNumber} — {set.actualWeight} lbs × {set.actualReps}
            </Text>
          ))}
        </ArtDecoCard>

        {errorMessage ? <Text style={styles.error}>{errorMessage}</Text> : null}

        <ArtDecoButton
          title={isSaving ? 'Saving...' : 'Complete Workout'}
          onPress={() => {
            void handleCompleteWorkout();
          }}
          disabled={isSaving}
        />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
  },
  content: {
    padding: artDecoTheme.spacing.md,
    gap: artDecoTheme.spacing.sm,
  },
  title: {
    color: artDecoTheme.colors.accent,
    fontSize: artDecoTheme.typography.title,
    fontWeight: '800',
  },
  subtitle: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.body,
  },
  exerciseCard: {
    gap: artDecoTheme.spacing.xs,
  },
  exerciseName: {
    color: artDecoTheme.colors.textPrimary,
    fontWeight: '700',
    fontSize: artDecoTheme.typography.body,
  },
  exerciseMeta: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.caption,
  },
  loggedSet: {
    color: artDecoTheme.colors.textSecondary,
    fontSize: artDecoTheme.typography.caption,
    marginTop: artDecoTheme.spacing.xs,
  },
  error: {
    color: artDecoTheme.colors.danger,
    fontSize: artDecoTheme.typography.caption,
  },
  emptyState: {
    flex: 1,
    backgroundColor: artDecoTheme.colors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    color: artDecoTheme.colors.textPrimary,
    fontSize: artDecoTheme.typography.body,
  },
});
