'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { ExerciseCardV2 } from './exercise-card-v2';
import { PhaseBanner } from './phase-banner';
import type { Session } from '@/types/programV2';

interface WorkoutSessionViewProps {
  session: Session;
  phaseName: string;
  phaseGoal: string;
  phaseProgress: number;
  oneRepMax: number;
  onComplete: (data: { completed: boolean }) => void;
}

export function WorkoutSessionView({
  session,
  phaseName,
  phaseGoal,
  phaseProgress,
  oneRepMax,
  onComplete
}: WorkoutSessionViewProps) {
  const [completedSets, setCompletedSets] = useState<Set<string>>(new Set());

  const handleSetChange = (exerciseIndex: number, setNumber: number) => {
    const key = `${exerciseIndex}-${setNumber}`;
    setCompletedSets(previous => new Set(previous).add(key));
  };

  return (
    <div className="min-h-screen p-4 pb-20">
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
        {session.exercises.map((exercise, exerciseIndex) => (
          <ExerciseCardV2
            key={`${exercise.exercise}-${exerciseIndex}`}
            exercise={exercise}
            prescribedWeight={Math.round(oneRepMax * exercise.percent1RM)}
            onSetChange={(setNumber) => handleSetChange(exerciseIndex, setNumber)}
          />
        ))}
      </div>

      <Button
        className="mt-6 w-full"
        size="lg"
        onClick={() => onComplete({ completed: true })}
        disabled={completedSets.size === 0}
      >
        Complete Workout
      </Button>
    </div>
  );
}
