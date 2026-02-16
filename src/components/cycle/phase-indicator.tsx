'use client';

import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Calendar, HeartPulse, Sun, Moon, Droplets } from 'lucide-react';
import { useCycle } from '@/contexts/cycle-context';
import type { CyclePhase } from '@/types';

interface PhaseIndicatorProps {
  compact?: boolean;
  showProgress?: boolean;
}

const phaseConfig: Record<CyclePhase, { icon: typeof Droplets; color: string; badgeVariant: 'default' | 'secondary' | 'destructive' | 'outline' }> = {
  menstrual: { icon: Droplets, color: 'bg-red-500', badgeVariant: 'default' },
  follicular: { icon: Sun, color: 'bg-green-500', badgeVariant: 'secondary' },
  ovulation: { icon: HeartPulse, color: 'bg-pink-500', badgeVariant: 'destructive' },
  luteal: { icon: Moon, color: 'bg-purple-500', badgeVariant: 'outline' },
};

export function PhaseIndicator({ compact = false, showProgress = true }: PhaseIndicatorProps) {
  const { cycleStatus, currentRecommendation } = useCycle();

  if (!cycleStatus) {
    return (
      <Card className="p-3 text-center text-muted-foreground">
        <Calendar className="mx-auto h-5 w-5 mb-1" />
        <p className="text-xs">Track your period to see phases</p>
      </Card>
    );
  }

  const config = phaseConfig[cycleStatus.currentPhase];
  const PhaseIcon = config.icon;

  if (compact) {
    return (
      <div className="flex items-center gap-2">
        <div className={`${config.color} rounded-full p-2 text-white`}>
          <PhaseIcon className="h-4 w-4" />
        </div>
        <span className="text-sm font-medium capitalize">
          {cycleStatus.currentPhase} · Day {cycleStatus.cycleDay}
        </span>
      </div>
    );
  }

  const totalPhaseDays = Math.max(
    1,
    Math.round((cycleStatus.phaseEndDate.getTime() - cycleStatus.phaseStartDate.getTime()) / (1000 * 60 * 60 * 24)) + 1
  );
  const elapsedDays = cycleStatus.cycleDay - Math.round((cycleStatus.phaseStartDate.getTime() - cycleStatus.phaseStartDate.getTime()) / (1000 * 60 * 60 * 24));
  const progressPercentage = Math.min(100, Math.round((elapsedDays / totalPhaseDays) * 100));

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2">
            <div className={`${config.color} rounded-full p-2 text-white`}>
              <PhaseIcon className="h-4 w-4" />
            </div>
            <div>
              <h3 className="font-semibold capitalize">{cycleStatus.currentPhase} Phase</h3>
              <p className="text-sm text-muted-foreground">
                Day {cycleStatus.cycleDay} · {cycleStatus.daysUntilNextPhase} days until next phase
              </p>
            </div>
          </div>
          <Badge variant={config.badgeVariant}>
            {cycleStatus.currentPhase}
          </Badge>
        </div>

        {showProgress && (
          <div className="mt-3">
            <div className="flex justify-between text-xs text-muted-foreground mb-1">
              <span>Phase start</span>
              <span>{progressPercentage}%</span>
              <span>Phase end</span>
            </div>
            <div className="w-full bg-secondary rounded-full h-2">
              <div
                className={`h-2 rounded-full ${config.color}`}
                style={{ width: `${progressPercentage}%` }}
              />
            </div>
          </div>
        )}

        {currentRecommendation && (
          <div className="mt-3 p-2 bg-accent rounded-md">
            <p className="text-sm font-medium">{currentRecommendation.title}</p>
            <p className="text-xs text-muted-foreground">{currentRecommendation.trainingFocus}</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
