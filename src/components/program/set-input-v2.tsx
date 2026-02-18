'use client';

import { useState } from 'react';
import { Info } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { ExerciseV2 } from '@/types/programV2';
import type { WeightOverrideReason } from '@/types/workout';

interface SetInputV2Props {
  setNumber: number;
  prescribedWeight: number;
  prescribedReps: ExerciseV2['reps'];
  isTimeBased: boolean;
  onWeightChange: (weight: number) => void;
  onRepsChange: (reps: number) => void;
  onTimeChange?: (seconds: number) => void;
  /** Pre-filled recommendation weight — overrides prescribedWeight as initial value */
  recommendedWeight?: number;
  /** Explanation text shown in tooltip (e.g. "Based on last session: 200 lbs + 5 lb progression") */
  recommendationSource?: string;
  /** Called when user provides an override reason after changing the recommended weight */
  onOverrideReason?: (reason: WeightOverrideReason) => void;
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
  onTimeChange,
  recommendedWeight,
  recommendationSource,
  onOverrideReason,
}: SetInputV2Props) {
  const initialWeight = recommendedWeight ?? prescribedWeight;
  const [weight, setWeight] = useState(initialWeight);
  const [reps, setReps] = useState(getDefaultReps(prescribedReps));
  const [showOverrideSelect, setShowOverrideSelect] = useState(false);
  const [hasOverridden, setHasOverridden] = useState(false);

  // On blur: if weight differs from recommendation and not yet overridden, prompt for reason
  function handleWeightBlur() {
    if (
      recommendedWeight !== undefined &&
      weight !== recommendedWeight &&
      !hasOverridden
    ) {
      setShowOverrideSelect(true);
    }
  }

  function handleOverrideReasonChange(value: string) {
    const reason = value as WeightOverrideReason;
    setHasOverridden(true);
    setShowOverrideSelect(false);
    onOverrideReason?.(reason);
  }

  const hasRecommendation = recommendedWeight !== undefined;

  return (
    <div className="flex flex-col gap-2 rounded-lg border p-3">
      <div className="flex items-end gap-3">
        <div className="w-8 text-lg font-medium">{setNumber}</div>

        {!isTimeBased && (
          <>
            <div className="flex-1">
              <div className="mb-1 flex items-center gap-1">
                <Label htmlFor={`weight-${setNumber}`} className="text-xs">
                  Weight (lbs)
                </Label>
                {hasRecommendation && recommendationSource && (
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <button
                          type="button"
                          aria-label="Recommendation info"
                          className="text-muted-foreground hover:text-foreground transition-colors"
                        >
                          <Info className="size-3.5" />
                        </button>
                      </TooltipTrigger>
                      <TooltipContent side="top" className="max-w-[200px] text-center">
                        {recommendationSource}
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                )}
              </div>
              <Input
                id={`weight-${setNumber}`}
                type="number"
                value={weight}
                onChange={event => {
                  const nextWeight = Number(event.target.value);
                  setWeight(nextWeight);
                  onWeightChange(nextWeight);
                }}
                onBlur={handleWeightBlur}
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

      {showOverrideSelect && (
        <div className="px-1">
          <p className="text-muted-foreground mb-1 text-xs">Why are you changing the recommended weight?</p>
          <Select onValueChange={handleOverrideReasonChange}>
            <SelectTrigger className="w-full" size="sm">
              <SelectValue placeholder="Select a reason…" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="injured">Injured</SelectItem>
              <SelectItem value="fatigued">Fatigued</SelectItem>
              <SelectItem value="just_because">Just because</SelectItem>
              <SelectItem value="other">Other</SelectItem>
            </SelectContent>
          </Select>
        </div>
      )}
    </div>
  );
}
