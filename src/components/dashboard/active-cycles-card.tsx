'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useUser } from '@/contexts/user-context';
import { getActiveCycles } from '@/lib/db';
import { useEffect, useState } from 'react';
import type { ActiveCycle } from '@/types';

export function ActiveCyclesCard() {
  const { user } = useUser();
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
          <CardTitle>Active Programs</CardTitle>
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
        <CardTitle>Active Programs</CardTitle>
        <CardDescription>{activeCycles.length} program{activeCycles.length > 1 ? 's' : ''} in progress</CardDescription>
      </CardHeader>
      <CardContent className="space-y-3">
        {activeCycles.map(cycle => (
          <div key={cycle.id} className="flex items-center justify-between p-3 border rounded-lg">
            <div>
              <p className="font-medium">{cycle.cycleName}</p>
              <p className="text-sm text-muted-foreground">Week {cycle.currentWeek} of 8</p>
            </div>
            <Badge>Active</Badge>
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
