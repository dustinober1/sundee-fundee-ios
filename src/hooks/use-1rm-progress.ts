'use client';

import { useEffect, useState } from 'react';
import { format } from 'date-fns';
import { db } from '@/lib/db/dexie';
import { EXERCISES } from '@/data/exercises';

export interface OneRMPoint {
  date: string;
  estimated1RM: number;
}

function epley(weight: number, reps: number): number {
  if (reps <= 1) return weight;
  return weight * (1 + Math.min(reps, 10) / 30);
}

export function use1RMProgress(exerciseId: string): { data: OneRMPoint[]; loading: boolean } {
  const [data, setData] = useState<OneRMPoint[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!exerciseId) {
      return;
    }

    let isActive = true;

    void (async () => {
      if (isActive) setLoading(true);
      const sets = await db.completedSets
        .where('exerciseId')
        .equals(exerciseId)
        .toArray();

      if (!isActive) return;

      const workoutIds = [...new Set(sets.map(s => s.workoutId))];

      const workouts = await db.completedWorkouts
        .where('id')
        .anyOf(workoutIds)
        .toArray();

      if (!isActive) return;

      // Group sets by workoutId
      const setsByWorkout = new Map<string, typeof sets>();
      for (const set of sets) {
        const group = setsByWorkout.get(set.workoutId) ?? [];
        group.push(set);
        setsByWorkout.set(set.workoutId, group);
      }

      // Sort workouts by date ascending and build points
      const sortedWorkouts = workouts.sort(
        (a, b) => new Date(a.completedAt).getTime() - new Date(b.completedAt).getTime()
      );

      const sortedPoints: OneRMPoint[] = sortedWorkouts
        .filter(w => setsByWorkout.has(w.id))
        .map(w => {
          const workoutSets = setsByWorkout.get(w.id)!;
          const max1RM = Math.max(
            ...workoutSets.map(s => epley(s.actualWeight, s.actualReps))
          );
          return {
            date: format(new Date(w.completedAt), 'MMM d'),
            estimated1RM: Math.round(max1RM),
          };
        });

      if (isActive) {
        setData(sortedPoints);
        setLoading(false);
      }
    })();

    return () => {
      isActive = false;
    };
  }, [exerciseId]);

  return { data, loading };
}

export function useTrackedExercises(): { exercises: { id: string; name: string }[]; loading: boolean } {
  const [exercises, setExercises] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const sets = await db.completedSets.toArray();

      if (!isActive) return;

      const uniqueIds = [...new Set(sets.map(s => s.exerciseId))];

      const result = uniqueIds.map(id => {
        const found = EXERCISES.find(e => e.id === id);
        return { id, name: found?.name ?? id };
      });

      if (isActive) {
        setExercises(result);
        setLoading(false);
      }
    })();

    return () => {
      isActive = false;
    };
  }, []);

  return { exercises, loading };
}
