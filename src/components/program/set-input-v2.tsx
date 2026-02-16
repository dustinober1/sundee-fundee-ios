'use client';

import { useState } from 'react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { ExerciseV2 } from '@/types/programV2';

interface SetInputV2Props {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: ExerciseV2['reps'];
  isTimeBased: boolean;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
  onTimeChange?: (seconds: number) => void;
}

function getDefaultReps(reps: ExerciseV2['reps']): number {
  if (Array.isArray(reps)) {
    return reps[0];
  }
  if (reps === 'AMRAP') {
    return 0;
  }
  return reps;
}

export function SetInputV2({
  setNumber,
  prescribedWeight,
  prescribedReps,
  isTimeBased,
  onWeightChange,
  onRepsChange,
  onTimeChange
}: SetInputV2Props) {
  const [weight, setWeight] = useState(prescribedWeight);
  const [reps, setReps] = useState(getDefaultReps(prescribedReps));

  return (
    <div className="flex items-end gap-3 rounded-lg border p-3">
      <div className="w-8 text-lg font-medium">{setNumber}</div>

      {!isTimeBased && (
        <>
          <div className="flex-1">
            <Label htmlFor={`weight-${setNumber}`} className="text-xs">Weight (lbs)</Label>
            <Input
              id={`weight-${setNumber}`}
              type="number"
              value={weight}
              onChange={event => {
                const nextWeight = Number(event.target.value);
                setWeight(nextWeight);
                onWeightChange(nextWeight);
              }}
            />
          </div>
          <div className="flex-1">
            <Label htmlFor={`reps-${setNumber}`} className="text-xs">Reps</Label>
            <Input
              id={`reps-${setNumber}`}
              type="number"
              value={reps}
              onChange={event => {
                const nextReps = Number(event.target.value);
                setReps(nextReps);
                onRepsChange(nextReps);
              }}
            />
          </div>
        </>
      )}

      {isTimeBased && (
        <div className="flex-1">
          <Label htmlFor={`seconds-${setNumber}`} className="text-xs">Seconds</Label>
          <Input
            id={`seconds-${setNumber}`}
            type="number"
            value={reps}
            onChange={event => {
              const nextSeconds = Number(event.target.value);
              setReps(nextSeconds);
              onTimeChange?.(nextSeconds);
            }}
          />
        </div>
      )}
    </div>
  );
}
