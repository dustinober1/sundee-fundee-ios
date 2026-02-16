'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { getExerciseByName } from '@/data/exercises';
import type { ExerciseV2 } from '@/types/programV2';
import { SetInputV2 } from './set-input-v2';

interface ExerciseCardV2Props {
  exercise: ExerciseV2;
  prescribedWeight: number;
  onSetChange: (setNumber: number, data: { weight: number; reps: number }) => void;
}

function formatSetCount(sets: ExerciseV2['sets']): string {
  return sets === 'AMRAP' ? 'AMRAP sets' : `${sets} sets`;
}

function formatRepCount(reps: ExerciseV2['reps']): string {
  if (reps === 'AMRAP') {
    return 'AMRAP reps';
  }
  if (Array.isArray(reps)) {
    return `${reps[0]}-${reps[1]} reps`;
  }
  return `${reps} reps`;
}

function toSetNumber(value: ExerciseV2['sets']): number {
  return value === 'AMRAP' ? 3 : value;
}

export function ExerciseCardV2({ exercise, prescribedWeight, onSetChange }: ExerciseCardV2Props) {
  const exerciseMetadata = getExerciseByName(exercise.exercise);
  const displayName = exercise.variant
    ? `${exerciseMetadata?.name ?? exercise.exercise} (${exercise.variant})`
    : (exerciseMetadata?.name ?? exercise.exercise);
  const isTimeBased = exercise.exercise === 'front-rack-hold';

  return (
    <Card>
      <CardHeader>
        <CardTitle className="capitalize">{displayName}</CardTitle>
        <p className="text-muted-foreground text-sm">
          <span>{formatSetCount(exercise.sets)}</span> × <span>{formatRepCount(exercise.reps)}</span>
        </p>
        <p className="text-muted-foreground text-sm">
          @ {Math.round(exercise.percent1RM * 100)}% 1RM ({prescribedWeight} lbs)
        </p>
        {exercise.notes && (
          <Badge variant="secondary">{exercise.notes}</Badge>
        )}
      </CardHeader>
      <CardContent className="space-y-2">
        {Array.from({ length: toSetNumber(exercise.sets) }).map((_, index) => (
          <SetInputV2
            key={`${exercise.exercise}-${index}`}
            setNumber={index + 1}
            prescribedWeight={prescribedWeight}
            prescribedReps={exercise.reps}
            isTimeBased={isTimeBased}
            onWeightChange={weight => onSetChange(index + 1, { weight, reps: 0 })}
            onRepsChange={reps => onSetChange(index + 1, { weight: 0, reps })}
            onTimeChange={seconds => onSetChange(index + 1, { weight: 0, reps: seconds })}
          />
        ))}
      </CardContent>
    </Card>
  );
}
