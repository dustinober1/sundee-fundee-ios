'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Calendar, ArrowRight, Flame, BarChart2 } from 'lucide-react';
import { PhaseIndicator } from '@/components/cycle/phase-indicator';
import { useCycle } from '@/contexts/cycle-context';
import { useUser } from '@/contexts/user-context';
import Link from 'next/link';

export function CycleWidget() {
  const { cycleStatus, currentRecommendation } = useCycle();
  const { user } = useUser();

  if (!user) return null;

  if (!cycleStatus) {
    return (
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg flex items-center gap-2">
            <Flame className="h-5 w-5 text-orange-500" />
            Cycle Tracking
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-6 text-muted-foreground">
            <Calendar className="mx-auto h-10 w-10 mb-2" />
            <p className="text-sm">Start tracking your cycle</p>
            <Link href="/cycle" className="inline-block mt-2 text-primary hover:underline text-sm">
              Begin tracking
            </Link>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-lg flex items-center gap-2">
          <Flame className="h-5 w-5 text-orange-500" />
          Cycle Phase
        </CardTitle>
        <Link href="/cycle" className="text-sm text-primary hover:underline flex items-center">
          View <ArrowRight className="ml-1 h-4 w-4" />
        </Link>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          <PhaseIndicator compact={false} showProgress={true} />

          {currentRecommendation && (
            <div className="p-3 bg-accent rounded-md">
              <h4 className="font-medium text-sm mb-1 flex items-center gap-1.5">
                <BarChart2 className="h-4 w-4 text-muted-foreground" />
                Today&apos;s Focus
              </h4>
              <p className="text-xs text-muted-foreground">
                {currentRecommendation.trainingFocus}
              </p>
              <div className="mt-2">
                <Badge
                  variant={
                    currentRecommendation.intensityRecommendation === 'peak' ? 'destructive' :
                    currentRecommendation.intensityRecommendation === 'high' ? 'default' :
                    currentRecommendation.intensityRecommendation === 'moderate' ? 'secondary' : 'outline'
                  }
                  className="text-xs"
                >
                  {currentRecommendation.intensityRecommendation} intensity
                </Badge>
              </div>
            </div>
          )}

          <div className="pt-2">
            <p className="text-xs text-muted-foreground">
              Next period expected: {new Date(cycleStatus.predictedNextPeriod).toLocaleDateString()}
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
