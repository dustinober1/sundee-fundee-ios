'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { SetInput } from './set-input';
import type { Exercise } from '@/types';

interface ExerciseCardProps {
  exercise: Exercise;
  prescribedWeight: number;
}

export function ExerciseCard({ exercise, prescribedWeight }: ExerciseCardProps) {
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
          />
        ))}
      </CardContent>
    </Card>
  );
}
