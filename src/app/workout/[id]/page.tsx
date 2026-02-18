'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useExercise } from '@/contexts/exercise-context';
import { useUser } from '@/contexts/user-context';
import { SessionSelector } from '@/components/program/session-selector';
import { TestDayInterface } from '@/components/program/test-day-interface';
import { WorkoutSessionView } from '@/components/program/workout-session-view';
import {
  saveCompletedWorkout,
  saveCompletedSet,
  getActiveCycles,
  getLastCompletedSetsForExercise,
} from '@/lib/db';
import { generateId } from '@/lib/utils';
import { getNextRecommendedWeight, wasSessionSuccessful } from '@/lib/calculations';
import { detectPlateauForExercise, getDeloadWeight } from '@/lib/recommendations/plateau-detection';
import type { Session } from '@/types/programV2';
import type { CollectedSetData } from '@/components/program/workout-session-view';

interface RecommendationEntry {
  weight: number;
  source: string;
}

interface PlateauEntry {
  exerciseName: string;
  adjustedWeight: number;
}

function WorkoutContent() {
  const params = useParams();
  const router = useRouter();
  const { getProgram, getWeek, getPhaseForWeek, getPhaseProgress } = useExercise();
  const { user, oneRepMaxes } = useUser();
  const [selectedSession, setSelectedSession] = useState<Session | null>(null);
  const [recommendations, setRecommendations] = useState<Record<string, RecommendationEntry>>({});
  const [plateaus, setPlateaus] = useState<PlateauEntry[]>([]);
  const currentWeek = 1;

  const programId = params.id as string;
  const program = getProgram(programId);

  if (!program) {
    return (
      <div className="min-h-screen p-4 pb-20">
        <p>Program not found</p>
      </div>
    );
  }

  const weekData = getWeek(programId, currentWeek);
  const phase = getPhaseForWeek(programId, currentWeek);
  const phaseProgress = getPhaseProgress(programId, currentWeek, phase?.id || '');

  // Helper: get 1RM for a specific exercise
  function get1RMForExercise(exerciseId: string): number | undefined {
    const match = oneRepMaxes.find(orm => orm.exerciseId === exerciseId);
    return match?.weight;
  }

  // Load recommendations and plateau detection when a session is selected
  useEffect(() => {
    if (!selectedSession || !user) return;

    async function loadRecommendationsAndPlateaus() {
      const activeCycles = await getActiveCycles(user!.id);
      const activeCycleId = activeCycles[0]?.id;

      const newRecommendations: Record<string, RecommendationEntry> = {};
      const newPlateaus: PlateauEntry[] = [];

      for (const exercise of selectedSession!.exercises) {
        const exerciseId = exercise.exercise;
        const oneRepMax = get1RMForExercise(exerciseId);

        // Skip recommendation if no 1RM data for this exercise (fall back to prescribedWeight)
        if (oneRepMax === undefined || oneRepMax === 0) continue;

        const prescribedWeight = Math.round(oneRepMax * exercise.percent1RM);

        // Get last completed sets for this exercise (most recent session)
        let lastWeight = prescribedWeight;
        let result: 'first' | 'success' | 'failure' = 'first';
        let sourceText = `Starting weight: ${Math.round(oneRepMax * 0.7)} lbs (70% of 1RM)`;

        if (activeCycleId) {
          const lastSets = await getLastCompletedSetsForExercise(exerciseId, activeCycleId, 10);

          if (lastSets.length > 0) {
            // Determine the weight used in the most recent session
            lastWeight = lastSets[0].actualWeight;

            // Determine if that session was successful
            const sessionSuccess = wasSessionSuccessful(
              lastSets.map(s => ({
                actualReps: s.actualReps,
                prescribedReps: s.prescribedReps,
                actualWeight: s.actualWeight,
                prescribedWeight: s.prescribedWeight,
              }))
            );

            result = sessionSuccess ? 'success' : 'failure';
            const direction = result === 'success' ? '+5 lb progression' : '-5 lb adjustment';
            sourceText = `Based on last session: ${lastWeight} lbs (${direction})`;
          }
        }

        const recommendedWeight = getNextRecommendedWeight(lastWeight, result, oneRepMax);

        // Plateau detection (requires activeCycleId)
        if (activeCycleId) {
          const plateauWarning = await detectPlateauForExercise(exerciseId, activeCycleId);

          if (plateauWarning.hasPlateau) {
            const adjustedWeight = getDeloadWeight(recommendedWeight);
            newPlateaus.push({ exerciseName: exerciseId, adjustedWeight });

            // Override recommendation with deload weight
            newRecommendations[exerciseId] = {
              weight: adjustedWeight,
              source: `Deload: ${adjustedWeight} lbs (plateau detected — 10% reduction)`,
            };
            continue;
          }
        }

        newRecommendations[exerciseId] = {
          weight: recommendedWeight,
          source: sourceText,
        };
      }

      setRecommendations(newRecommendations);
      setPlateaus(newPlateaus);
    }

    loadRecommendationsAndPlateaus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedSession, user]);

  if (!weekData) {
    return (
      <div className="min-h-screen p-4 pb-20">
        <p>Week data not found.</p>
      </div>
    );
  }

  async function handleWorkoutComplete(data: { completed: boolean; sets: CollectedSetData[] }) {
    if (!data.completed || !user) return;

    // Resolve active cycle — use first active cycle, or a fallback ID if none exists yet
    const activeCycles = await getActiveCycles(user.id);
    const activeCycleId = activeCycles[0]?.id ?? generateId();

    const workoutId = generateId();
    const now = new Date();

    await saveCompletedWorkout({
      id: workoutId,
      userId: user.id,
      activeCycleId,
      programId,
      week: currentWeek,
      sessionId: selectedSession?.sessionId,
      completedAt: now
    });

    for (const set of data.sets) {
      await saveCompletedSet({
        id: generateId(),
        workoutId,
        exerciseId: set.exerciseId,
        setNumber: set.setNumber,
        prescribedWeight: set.prescribedWeight,
        actualWeight: set.actualWeight,
        prescribedReps: set.prescribedReps,
        actualReps: set.actualReps,
        overrideReason: set.overrideReason,
        createdAt: now
      });
    }

    router.back();
  }

  if (weekData.isTestWeek) {
    // Use the first available exercise's 1RM, fall back to back-squat, then 200
    const backSquat1RM = get1RMForExercise('back-squat') ?? 200;
    const testSession = weekData.sessions.find(session => session.sessionType === 'testing');
    if (testSession) {
      return (
        <div className="min-h-screen p-4 pb-20">
          <h1 className="mb-4 text-2xl font-bold">Test Day</h1>
          <TestDayInterface
            warmupExercises={testSession.exercises.slice(0, 4)}
            workingSets={testSession.exercises.slice(4)}
            oneRepMax={backSquat1RM}
            onComplete={() => {}}
          />
        </div>
      );
    }
  }

  if (!selectedSession) {
    return (
      <div className="min-h-screen p-4 pb-20">
        <h1 className="mb-2 text-2xl font-bold">Week {currentWeek}</h1>
        {phase && (
          <p className="text-muted-foreground mb-6">{phase.name}</p>
        )}

        <SessionSelector
          sessions={weekData.sessions}
          viewMode="session-cards"
          onSelect={sessionId => {
            const session = weekData.sessions.find(value => value.sessionId === sessionId);
            if (session) {
              setSelectedSession(session);
            }
          }}
        />
      </div>
    );
  }

  return (
    <WorkoutSessionView
      session={selectedSession}
      phaseName={phase?.name ?? ''}
      phaseGoal={phase?.goal ?? ''}
      phaseProgress={phaseProgress}
      oneRepMax={get1RMForExercise(selectedSession.exercises[0]?.exercise) ?? 200}
      recommendations={recommendations}
      plateaus={plateaus}
      onComplete={handleWorkoutComplete}
    />
  );
}

export default function WorkoutPage() {
  return <WorkoutContent />;
}
