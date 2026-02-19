'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { WeightProgressChart } from '@/components/progress/weight-progress-chart';
import { WeeklyVolumeChart } from '@/components/progress/weekly-volume-chart';
import { WorkoutHeatmap } from '@/components/progress/workout-heatmap';
import { CycleFilter } from '@/components/progress/cycle-filter';

export default function ProgressPage() {
  const [filter, setFilter] = useState('all-time');

  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Progress</h1>

      <CycleFilter onFilterChange={setFilter} />

      <Card>
        <CardHeader>
          <CardTitle>Estimated 1RM Progress</CardTitle>
          <CardDescription>Track your estimated one-rep max over time</CardDescription>
        </CardHeader>
        <CardContent>
          <WeightProgressChart />
        </CardContent>
      </Card>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Weekly Volume</CardTitle>
          <CardDescription>Total weight × reps lifted per week</CardDescription>
        </CardHeader>
        <CardContent>
          <WeeklyVolumeChart />
        </CardContent>
      </Card>

      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Training Frequency</CardTitle>
          <CardDescription>Your workout activity over the last year</CardDescription>
        </CardHeader>
        <CardContent className="overflow-x-auto">
          <WorkoutHeatmap />
        </CardContent>
      </Card>

      {filter === 'cycle-phase' && (
        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Performance by Cycle Phase</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8 text-muted-foreground">
              <p>Track how your performance varies across cycle phases</p>
              <p className="text-sm mt-2">Complete 2+ full cycles to see insights</p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
