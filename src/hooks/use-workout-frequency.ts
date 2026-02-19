'use client';

import { useState, useEffect } from 'react';
import { format, eachDayOfInterval, subYears } from 'date-fns';
import { db } from '@/lib/db/dexie';

export interface Activity {
  date: string;
  count: number;
  level: 0 | 1 | 2 | 3 | 4;
}

function countToLevel(count: number): 0 | 1 | 2 | 3 | 4 {
  if (count === 0) return 0;
  if (count === 1) return 1;
  if (count === 2) return 2;
  if (count <= 4) return 3;
  return 4;
}

export function useWorkoutFrequency(): {
  data: Activity[];
  loading: boolean;
  totalWorkouts: number;
} {
  const [data, setData] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);
  const [totalWorkouts, setTotalWorkouts] = useState(0);

  useEffect(() => {
    let isActive = true;

    async function load() {
      const completedWorkouts = await db.completedWorkouts.toArray();

      // Build map: date string → count
      const countByDate = new Map<string, number>();
      for (const w of completedWorkouts) {
        const dateKey = format(new Date(w.completedAt), 'yyyy-MM-dd');
        countByDate.set(dateKey, (countByDate.get(dateKey) ?? 0) + 1);
      }

      // Generate full 365-day range
      const today = new Date();
      const yearAgo = subYears(today, 1);
      const days = eachDayOfInterval({ start: yearAgo, end: today });

      const activities: Activity[] = days.map((day) => {
        const dateKey = format(day, 'yyyy-MM-dd');
        const count = countByDate.get(dateKey) ?? 0;
        return {
          date: dateKey,
          count,
          level: countToLevel(count),
        };
      });

      // Sort ascending
      activities.sort((a, b) => a.date.localeCompare(b.date));

      const total = Array.from(countByDate.values()).reduce((sum, n) => sum + n, 0);

      if (isActive) {
        setData(activities);
        setTotalWorkouts(total);
        setLoading(false);
      }
    }

    load();
    return () => {
      isActive = false;
    };
  }, []);

  return { data, loading, totalWorkouts };
}
