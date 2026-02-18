'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { ExerciseCardV2 } from './exercise-card-v2';
import { PhaseBanner } from './phase-banner';
import { PRCelebration } from './pr-celebration';
import { PlateauModal } from './plateau-modal';
import { usePRDetection } from '@/hooks/use-pr-detection';
import { savePersonalRecord } from '@/lib/db';
import { generateId } from '@/lib/utils';
import { useUser } from '@/contexts/user-context';
import type { Session } from '@/types/programV2';
import type { WeightOverrideReason } from '@/types/workout';

export interface CollectedSetData {
  exerciseId: string;
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: number;
  actualWeight: number;
  actualReps: number;
  overrideReason?: WeightOverrideReason;
}

interface RecommendationEntry {
  weight: number;
  source: string;
}

interface PlateauEntry {
  exerciseName: string;
  adjustedWeight: number;
}

interface WorkoutSessionViewProps {
  session: Session;
  phaseName: string;
  phaseGoal: string;
  phaseProgress: number;
  oneRepMax: number;
  onComplete: (data: { completed: boolean; sets: CollectedSetData[] }) => void;
  /** Map of exerciseId to recommendation — weight pre-fills all sets, source shows in tooltip */
  recommendations?: Record<string, RecommendationEntry>;
  /** Plateaued exercises shown in pre-workout modal; modal shows on mount if non-empty */
  plateaus?: PlateauEntry[];
}

export function WorkoutSessionView({
  session,
  phaseName,
  phaseGoal,
  phaseProgress,
  oneRepMax,
  onComplete,
  recommendations,
  plateaus,
}: WorkoutSessionViewProps) {
  const { user } = useUser();
  const { checkWeightPR, checkVolumePR } = usePRDetection();

  const [completedSets, setCompletedSets] = useState<Set<string>>(new Set());
  const [setDataMap, setSetDataMap] = useState<Record<string, CollectedSetData>>({});
  const [prCelebration, setPrCelebration] = useState<{
    isVisible: boolean;
    prType: 'weight' | 'volume' | null;
  }>({ isVisible: false, prType: null });
  const [showPlateauModal, setShowPlateauModal] = useState<boolean>(
    (plateaus?.length ?? 0) > 0
  );

  // Stable workout ID for this session (used as temporary key until workout is saved)
  const [sessionWorkoutId] = useState(() => generateId());

  const handleSetChange = async (
    exerciseIndex: number,
    exerciseId: string,
    setNumber: number,
    data: { weight: number; reps: number; prescribedWeight: number; prescribedReps: number }
  ) => {
    const key = `${exerciseIndex}-${setNumber}`;

    // Save set data first, then check for PRs
    const updatedSetData: CollectedSetData = {
      exerciseId,
      setNumber,
      prescribedWeight: data.prescribedWeight,
      prescribedReps: data.prescribedReps,
      actualWeight: data.weight,
      actualReps: data.reps,
    };

    setCompletedSets(previous => new Set(previous).add(key));
    setSetDataMap(previous => ({
      ...previous,
      [key]: updatedSetData
    }));

    // PR detection — only fires when weight > 0 (meaningful lift)
    if (data.weight > 0) {
      // 1. Weight PR check (synchronous)
      const isWeightPR = checkWeightPR(exerciseId, data.weight);

      if (isWeightPR) {
        setPrCelebration({ isVisible: true, prType: 'weight' });

        // Save PR to DB if user is available
        if (user) {
          await savePersonalRecord({
            id: generateId(),
            userId: user.id,
            exerciseId,
            type: 'weight',
            value: data.weight,
            workoutId: sessionWorkoutId,
            date: new Date(),
          });
        }
        return; // Weight PR takes priority — skip volume check
      }

      // 2. Volume PR check (async — compares against historical sessions)
      const currentExerciseSets = Object.values({
        ...setDataMap,
        [key]: updatedSetData
      })
        .filter(s => s.exerciseId === exerciseId)
        .map(s => ({ actualWeight: s.actualWeight, actualReps: s.actualReps }));

      const isVolumePR = await checkVolumePR(
        sessionWorkoutId,
        exerciseId,
        currentExerciseSets
      );

      if (isVolumePR) {
        setPrCelebration({ isVisible: true, prType: 'volume' });

        if (user) {
          const sessionVolume = currentExerciseSets.reduce(
            (sum, s) => sum + s.actualWeight * s.actualReps,
            0
          );
          await savePersonalRecord({
            id: generateId(),
            userId: user.id,
            exerciseId,
            type: 'volume',
            value: sessionVolume,
            workoutId: sessionWorkoutId,
            date: new Date(),
          });
        }
      }
    }
  };

  const handleOverrideReason = (
    exerciseIndex: number,
    exerciseId: string,
    setNumber: number,
    reason: WeightOverrideReason
  ) => {
    const key = `${exerciseIndex}-${setNumber}`;
    setSetDataMap(previous => ({
      ...previous,
      [key]: {
        ...(previous[key] ?? {
          exerciseId,
          setNumber,
          prescribedWeight: 0,
          prescribedReps: 0,
          actualWeight: 0,
          actualReps: 0,
        }),
        overrideReason: reason,
      }
    }));
  };

  const handleComplete = () => {
    const sets = Object.values(setDataMap);
    onComplete({ completed: true, sets });
  };

  return (
    <div className="min-h-screen p-4 pb-20">
      {/* Pre-workout plateau warning modal */}
      {plateaus && plateaus.length > 0 && (
        <PlateauModal
          isOpen={showPlateauModal}
          plateaus={plateaus}
          onAcknowledge={() => setShowPlateauModal(false)}
        />
      )}

      {/* Full-screen PR celebration overlay */}
      <PRCelebration
        isVisible={prCelebration.isVisible}
        prType={prCelebration.prType}
        onDismiss={() => setPrCelebration({ isVisible: false, prType: null })}
      />

      <PhaseBanner
        phaseName={phaseName}
        phaseGoal={phaseGoal}
        progress={phaseProgress}
      />

      <div className="mb-6">
        <h1 className="text-2xl font-bold">{session.sessionName}</h1>
        <p className="text-muted-foreground">{session.focus}</p>
      </div>

      <div className="space-y-4">
        {session.exercises.map((exercise, exerciseIndex) => {
          const recommendation = recommendations?.[exercise.exercise];
          // Same recommended weight for all sets of this exercise
          const setCount =
            exercise.sets === 'AMRAP' ? 3 : exercise.sets;
          const recommendedWeights: Record<number, number> | undefined =
            recommendation
              ? Object.fromEntries(
                  Array.from({ length: setCount }, (_, i) => [i + 1, recommendation.weight])
                )
              : undefined;

          return (
            <ExerciseCardV2
              key={`${exercise.exercise}-${exerciseIndex}`}
              exercise={exercise}
              exerciseId={exercise.exercise}
              prescribedWeight={Math.round(oneRepMax * exercise.percent1RM)}
              recommendedWeights={recommendedWeights}
              recommendationSource={recommendation?.source}
              onOverrideReason={(setNumber, reason) =>
                handleOverrideReason(exerciseIndex, exercise.exercise, setNumber, reason)
              }
              onSetChange={(setNumber, data) =>
                handleSetChange(exerciseIndex, exercise.exercise, setNumber, data)
              }
            />
          );
        })}
      </div>

      <Button
        className="mt-6 w-full"
        size="lg"
        onClick={handleComplete}
        disabled={completedSets.size === 0}
      >
        Complete Workout
      </Button>
    </div>
  );
}
