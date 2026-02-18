'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useExercise } from '@/contexts/exercise-context';
import { useUser } from '@/contexts/user-context';
import { SessionSelector } from '@/components/program/session-selector';
import { TestDayInterface } from '@/components/program/test-day-interface';
import { WorkoutSessionView } from '@/components/program/workout-session-view';
import { saveCompletedWorkout, saveCompletedSet, getActiveCycles } from '@/lib/db';
import { generateId } from '@/lib/utils';
import type { Session } from '@/types/programV2';
import type { CollectedSetData } from '@/components/program/workout-session-view';

function WorkoutContent() {
  const params = useParams();
  const router = useRouter();
  const { getProgram, getWeek, getPhaseForWeek, getPhaseProgress } = useExercise();
  const { user, oneRepMaxes } = useUser();
  const [selectedSession, setSelectedSession] = useState<Session | null>(null);
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
  const backSquat1RM = oneRepMaxes.find(oneRepMax => oneRepMax.exerciseId === 'back-squat')?.weight ?? 200;

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
        createdAt: now
      });
    }

    router.back();
  }

  if (weekData.isTestWeek) {
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
      oneRepMax={backSquat1RM}
      onComplete={handleWorkoutComplete}
    />
  );
}

export default function WorkoutPage() {
  return <WorkoutContent />;
}
