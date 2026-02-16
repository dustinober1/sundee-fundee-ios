'use client';

import { useEffect, useMemo, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { calculateTargetWeight } from '@/lib/calculations';
import type { ExerciseV2 } from '@/types/programV2';

interface TestDayInterfaceProps {
  warmupExercises: ExerciseV2[];
  workingSets: ExerciseV2[];
  oneRepMax: number;
  onComplete: (results: { successful: boolean; new1RM?: number }) => void;
}

export function TestDayInterface({
  warmupExercises,
  workingSets,
  oneRepMax,
  onComplete
}: TestDayInterfaceProps) {
  const [warmupChecks, setWarmupChecks] = useState<boolean[]>(() => warmupExercises.map(() => false));
  const [workingChecks, setWorkingChecks] = useState<boolean[]>(() => workingSets.map(() => false));

  const warmupWeights = useMemo(
    () => warmupExercises.map(exercise => calculateTargetWeight(oneRepMax, exercise.percent1RM)),
    [oneRepMax, warmupExercises]
  );
  const workingWeights = useMemo(
    () => workingSets.map(exercise => calculateTargetWeight(oneRepMax, exercise.percent1RM)),
    [oneRepMax, workingSets]
  );

  useEffect(() => {
    if (warmupChecks.every(Boolean) && workingChecks.every(Boolean) && workingChecks.length > 0) {
      onComplete({
        successful: true,
        new1RM: workingWeights[workingWeights.length - 1]
      });
    }
  }, [onComplete, warmupChecks, workingChecks, workingWeights]);

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Warm-up</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {warmupExercises.map((exercise, index) => (
            <div key={`warmup-${index}`} className="flex items-center gap-3 rounded-lg border p-3">
              <Checkbox
                id={`warmup-${index}`}
                checked={warmupChecks[index]}
                onCheckedChange={checked => {
                  setWarmupChecks(prev => prev.map((value, i) => (i === index ? checked : value)));
                }}
              />
              <Label htmlFor={`warmup-${index}`} className="flex-1 cursor-pointer">
                {warmupWeights[index]} lbs ({Math.round(exercise.percent1RM * 100)}%)
              </Label>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Working Sets</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {workingSets.map((exercise, index) => (
            <div key={`working-${index}`} className="flex items-center gap-3 rounded-lg border p-3">
              <Checkbox
                id={`working-${index}`}
                checked={workingChecks[index]}
                onCheckedChange={checked => {
                  setWorkingChecks(prev => prev.map((value, i) => (i === index ? checked : value)));
                }}
              />
              <Label htmlFor={`working-${index}`} className="flex-1 cursor-pointer">
                {workingWeights[index]} lbs ({Math.round(exercise.percent1RM * 100)}%)
              </Label>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
