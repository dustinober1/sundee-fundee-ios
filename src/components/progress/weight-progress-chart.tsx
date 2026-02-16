'use client';

import { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { db } from '@/lib/db/dexie';

interface ChartData {
  date: string;
  weight: number;
}

export function WeightProgressChart() {
  const [data, setData] = useState<ChartData[]>([]);

  useEffect(() => {
    let isActive = true;

    void (async () => {
      const sets = await db.completedSets
        .orderBy('createdAt')
        .limit(20)
        .toArray();

      if (!isActive) {
        return;
      }

      const chartData = sets.map(set => ({
        date: new Date(set.createdAt).toLocaleDateString(),
        weight: set.actualWeight
      }));

      setData(chartData);
    })();

    return () => {
      isActive = false;
    };
  }, []);

  if (data.length === 0) {
    return (
      <div className="text-center text-muted-foreground py-8">
        No workout data yet. Complete some workouts to see your progress!
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={250}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis
          dataKey="date"
          tick={{ fontSize: 12 }}
          tickFormatter={(value) => value.slice(0, 5)}
        />
        <YAxis tick={{ fontSize: 12 }} />
        <Tooltip />
        <Line
          type="monotone"
          dataKey="weight"
          stroke="hsl(var(--primary))"
          strokeWidth={2}
          dot={{ fill: 'hsl(var(--primary))' }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
