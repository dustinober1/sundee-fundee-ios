'use client';

import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

interface SetInputProps {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: number;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
}

export function SetInput({ setNumber, prescribedWeight, prescribedReps, onWeightChange, onRepsChange }: SetInputProps) {
  return (
    <div className="flex items-center gap-3 p-3 border rounded-lg">
      <div className="font-medium text-lg w-8">{setNumber}</div>

      <div className="flex-1">
        <Label htmlFor={`weight-${setNumber}`} className="text-xs">Weight (lbs)</Label>
        <Input
          id={`weight-${setNumber}`}
          type="number"
          defaultValue={prescribedWeight}
          onChange={(e) => onWeightChange(Number(e.target.value))}
          placeholder="Weight"
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
        />
      </div>
    </div>
  );
}
