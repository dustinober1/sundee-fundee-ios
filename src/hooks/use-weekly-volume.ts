'use client';

import { useState, useEffect } from 'react';
import { format, startOfWeek } from 'date-fns';
import { db } from '@/lib/db/dexie';

export interface WeeklyVolumePoint {
  week: string;
  weekKey: string;
  volume: number;
}

export function useWeeklyVolume(): { data: WeeklyVolumePoint[]; loading: boolean } {
  const [data, setData] = useState<WeeklyVolumePoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isActive = true;

    async function load() {
      const [completedWorkouts, completedSets] = await Promise.all([
        db.completedWorkouts.toArray(),
        db.completedSets.toArray(),
      ]);

      // Build map: workoutId → Date
      const workoutDateMap = new Map<string, Date>();
      for (const w of completedWorkouts) {
        workoutDateMap.set(w.id, new Date(w.completedAt));
      }

      // Accumulate volume per week key
      const volumeByWeek = new Map<string, number>();
      for (const set of completedSets) {
        const workoutDate = workoutDateMap.get(set.workoutId);
        if (!workoutDate) continue;

        const weekStart = startOfWeek(workoutDate, { weekStartsOn: 1 });
        const weekKey = format(weekStart, 'yyyy-MM-dd');
        const volume = (set.actualWeight ?? 0) * (set.actualReps ?? 0);
        volumeByWeek.set(weekKey, (volumeByWeek.get(weekKey) ?? 0) + volume);
      }

      // Sort ascending, keep last 12 weeks
      const sorted = Array.from(volumeByWeek.entries())
        .sort(([a], [b]) => a.localeCompare(b))
        .slice(-12)
        .map(([weekKey, total]) => ({
          week: format(new Date(weekKey + 'T00:00:00'), 'MMM d'),
          weekKey,
          volume: Math.round(total),
        }));

      if (isActive) {
        setData(sorted);
        setLoading(false);
      }
    }

    load();
    return () => {
      isActive = false;
    };
  }, []);

  return { data, loading };
}
