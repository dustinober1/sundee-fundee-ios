'use client';

import { Card } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';

interface PhaseBannerProps {
  phaseName: string;
  phaseGoal: string;
  progress: number;
}

export function PhaseBanner({ phaseName, phaseGoal, progress }: PhaseBannerProps) {
  return (
    <Card className="mb-4 p-4">
      <div className="space-y-2">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h3 className="text-lg font-semibold">{phaseName}</h3>
            <p className="text-muted-foreground text-sm">{phaseGoal}</p>
          </div>
          <span className="text-2xl font-bold">{progress}%</span>
        </div>
        <Progress value={progress} />
      </div>
    </Card>
  );
}
