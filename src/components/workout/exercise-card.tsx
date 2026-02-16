'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { SetInput } from './set-input';
import type { Exercise } from '@/types';

interface ExerciseCardProps {
  exercise: Exercise;
  prescribedWeight: number;
  onSetComplete?: (exercise: Exercise) => void;
}

export function ExerciseCard({ exercise, prescribedWeight, onSetComplete }: ExerciseCardProps) {
  // Track which sets are completed
  const [completedSets, setCompletedSets] = useState<Set<number>>(new Set());

  const handleSetComplete = (setIndex: number) => {
    // Don't trigger if already completed
    if (completedSets.has(setIndex)) return;

    // Mark set as completed
    setCompletedSets(prev => new Set(prev).add(setIndex));

    // Notify parent component to start rest timer
    onSetComplete?.(exercise);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="capitalize">{exercise.exercise.replace(/-/g, ' ')}</CardTitle>
        <p className="text-sm text-muted-foreground">
          {exercise.sets} sets × {exercise.reps} reps @ {Math.round(exercise.percent1RM * 100)}% 1RM ({prescribedWeight} lbs)
        </p>
      </CardHeader>
      <CardContent className="space-y-2">
        {Array.from({ length: exercise.sets }).map((_, i) => (
          <SetInput
            key={i}
            setNumber={i + 1}
            prescribedWeight={prescribedWeight}
            prescribedReps={exercise.reps}
            onWeightChange={() => {}}
            onRepsChange={() => {}}
            onComplete={() => handleSetComplete(i)}
            isCompleted={completedSets.has(i)}
          />
        ))}
      </CardContent>
    </Card>
  );
}
