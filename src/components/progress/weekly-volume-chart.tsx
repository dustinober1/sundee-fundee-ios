'use client';

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { useWeeklyVolume } from '@/hooks/use-weekly-volume';
import { Skeleton } from '@/components/ui/skeleton';

export function WeeklyVolumeChart() {
  const { data, loading } = useWeeklyVolume();

  if (loading) {
    return <Skeleton className="h-[250px] w-full" />;
  }

  if (data.length === 0) {
    return (
      <div className="flex h-[250px] flex-col items-center justify-center gap-2 text-center">
        <p className="text-sm font-medium">No volume data yet</p>
        <p className="text-xs text-muted-foreground">
          Complete some workouts to see your weekly volume here.
        </p>
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={250}>
      <BarChart data={data} margin={{ top: 4, right: 4, left: 0, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="week" tick={{ fontSize: 11 }} />
        <YAxis
          tick={{ fontSize: 11 }}
          tickFormatter={(value: number) =>
            value >= 1000 ? `${(value / 1000).toFixed(0)}k` : String(value)
          }
        />
        <Tooltip
          formatter={(value) => [
            (value as number).toLocaleString() + ' lbs',
            'Volume',
          ]}
        />
        <Bar
          dataKey="volume"
          fill="hsl(var(--chart-2))"
          radius={[4, 4, 0, 0]}
        />
      </BarChart>
    </ResponsiveContainer>
  );
}
