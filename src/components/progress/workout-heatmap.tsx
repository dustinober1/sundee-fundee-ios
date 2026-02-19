'use client';

import { ActivityCalendar } from 'react-activity-calendar';
import { useWorkoutFrequency } from '@/hooks/use-workout-frequency';
import { Skeleton } from '@/components/ui/skeleton';

export function WorkoutHeatmap() {
  const { data, loading, totalWorkouts } = useWorkoutFrequency();

  if (loading) {
    return <Skeleton className="h-[160px] w-full" />;
  }

  return (
    <div>
      <ActivityCalendar
        data={data}
        theme={{
          light: ['#ebedf0', '#9be9a8', '#40c463', '#30a14e', '#216e39'],
        }}
        labels={{ totalCount: '{{count}} workouts in the last year' }}
        showWeekdayLabels
        blockSize={12}
        blockMargin={3}
        fontSize={12}
      />
      <p className="text-sm text-muted-foreground mt-2">
        {totalWorkouts} workouts in the last year
      </p>
    </div>
  );
}
