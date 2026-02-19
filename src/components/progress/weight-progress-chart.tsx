'use client';

import { useState } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { use1RMProgress, useTrackedExercises } from '@/hooks/use-1rm-progress';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';

export function WeightProgressChart() {
  const { exercises, loading: exercisesLoading } = useTrackedExercises();
  const [selectedExerciseId, setSelectedExerciseId] = useState<string>('');

  // Derive the effective exercise ID: use selected or fall back to first available
  const effectiveExerciseId = selectedExerciseId || exercises[0]?.id || '';

  const { data, loading: dataLoading } = use1RMProgress(effectiveExerciseId);

  if (exercisesLoading) {
    return (
      <div className="space-y-3">
        <Skeleton className="h-9 w-full" />
        <Skeleton className="h-[250px] w-full" />
      </div>
    );
  }

  if (exercises.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-muted-foreground font-medium">No workout data yet</p>
        <p className="text-muted-foreground text-sm mt-1">
          Complete some workouts to see your strength progress.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <Select value={effectiveExerciseId} onValueChange={setSelectedExerciseId}>
        <SelectTrigger className="w-full">
          <SelectValue placeholder="Select an exercise" />
        </SelectTrigger>
        <SelectContent>
          {exercises.map(exercise => (
            <SelectItem key={exercise.id} value={exercise.id}>
              {exercise.name}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>

      {dataLoading ? (
        <Skeleton className="h-[250px] w-full" />
      ) : data.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-muted-foreground text-sm">
            No data for this exercise yet.
          </p>
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={250}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
            <YAxis
              tick={{ fontSize: 11 }}
              tickFormatter={(value: number) => `${value} lbs`}
            />
            <Tooltip
              formatter={(value: number | undefined) => [`${value ?? 0} lbs`, 'Est. 1RM'] as [string, string]}
            />
            <Line
              type="monotone"
              dataKey="estimated1RM"
              stroke="hsl(var(--chart-1))"
              strokeWidth={2}
              dot={{ fill: 'hsl(var(--chart-1))' }}
            />
          </LineChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

