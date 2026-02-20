'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Trophy } from 'lucide-react';
import { useUser } from '@/contexts/user-context';
import { useExercise } from '@/contexts/exercise-context';
import { getActiveCycles } from '@/lib/db';
import { useEffect, useState } from 'react';
import type { ActiveCycle } from '@/types';
import Link from 'next/link';

export function ActiveCyclesCard() {
  const { user } = useUser();
  const { getProgram, getPhaseForWeek, getPhaseProgress } = useExercise();
  const [activeCycles, setActiveCycles] = useState<ActiveCycle[]>([]);

  useEffect(() => {
    if (user) {
      getActiveCycles(user.id).then(setActiveCycles);
    }
  }, [user]);

  if (activeCycles.length === 0) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Trophy className="h-5 w-5 text-yellow-500" />
            Active Programs
          </CardTitle>
          <CardDescription>No active programs</CardDescription>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            Browse programs to start training
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Trophy className="h-5 w-5 text-yellow-500" />
          Active Programs
        </CardTitle>
        <CardDescription>{activeCycles.length} program{activeCycles.length > 1 ? 's' : ''} in progress</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {activeCycles.map(cycle => {
          const program = getProgram(cycle.programId);
          const phase = getPhaseForWeek(cycle.programId, cycle.currentWeek);
          const phaseProgress = getPhaseProgress(cycle.programId, cycle.currentWeek, phase?.id || '');

          return (
            <Link key={cycle.id} href={`/workout/${cycle.programId}`}>
              <div className="hover:bg-accent flex cursor-pointer items-center justify-between rounded-lg border p-3 transition-colors">
                <div className="flex-1">
                  <p className="font-medium">{cycle.cycleName}</p>
                  <p className="text-muted-foreground text-sm">
                    Week {cycle.currentWeek} of {program?.durationWeeks || 8}
                  </p>
                  {phase && (
                    <p className="text-muted-foreground mt-1 text-xs">
                      {phase.name} - {phaseProgress}%
                    </p>
                  )}
                </div>
                <Badge>Active</Badge>
              </div>
            </Link>
          );
        })}
      </CardContent>
    </Card>
  );
}
