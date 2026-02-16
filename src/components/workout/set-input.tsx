'use client';

import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Check } from 'lucide-react';

interface SetInputProps {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: number;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
  onComplete: () => void;
  isCompleted: boolean;
}

export function SetInput({
  setNumber,
  prescribedWeight,
  prescribedReps,
  onWeightChange,
  onRepsChange,
  onComplete,
  isCompleted
}: SetInputProps) {
  return (
    <div className={`flex items-center gap-3 p-3 border rounded-lg ${isCompleted ? 'bg-green-50 border-green-300' : ''}`}>
      <div className="font-medium text-lg w-8">{setNumber}</div>

      <div className="flex-1">
        <Label htmlFor={`weight-${setNumber}`} className="text-xs">Weight (lbs)</Label>
        <Input
          id={`weight-${setNumber}`}
          type="number"
          defaultValue={prescribedWeight}
          onChange={(e) => onWeightChange(Number(e.target.value))}
          placeholder="Weight"
          disabled={isCompleted}
          className={isCompleted ? 'bg-gray-100' : ''}
        />
      </div>

      <div className="flex-1">
        <Label htmlFor={`reps-${setNumber}`} className="text-xs">Reps</Label>
        <Input
          id={`reps-${setNumber}`}
          type="number"
          defaultValue={prescribedReps}
          onChange={(e) => onRepsChange(Number(e.target.value))}
          placeholder="Reps"
          disabled={isCompleted}
          className={isCompleted ? 'bg-gray-100' : ''}
        />
      </div>

      <Button
        variant={isCompleted ? "secondary" : "default"}
        size="sm"
        onClick={onComplete}
        disabled={isCompleted}
        className="h-9 w-9 p-0 mt-4"
        aria-label={isCompleted ? "Set completed" : "Mark set as complete"}
      >
        <Check className="h-4 w-4" />
      </Button>
    </div>
  );
}
