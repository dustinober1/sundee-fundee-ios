'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Plus } from 'lucide-react';
import { CycleCalendar } from '@/components/cycle/cycle-calendar';
import { SymptomLogger } from '@/components/cycle/symptom-logger';
import { BBTInput } from '@/components/cycle/bbt-input';
import { PhaseIndicator } from '@/components/cycle/phase-indicator';
import { RecommendationCard } from '@/components/cycle/recommendation-card';
import { useCycle } from '@/contexts/cycle-context';
import { format } from 'date-fns';

export default function CyclePage() {
  const {
    cycleStatus,
    currentRecommendation,
    symptomLogs,
    availableSymptoms,
    logPeriod,
  } = useCycle();

  const today = new Date();
  const recentSymptoms = symptomLogs.slice(0, 5);

  const getSymptomName = (symptomId: string): string => {
    const symptom = availableSymptoms.find(s => s.id === symptomId);
    return symptom?.name ?? symptomId;
  };

  const getSeverityColor = (severity: number): string => {
    const colors: Record<number, string> = { 1: 'bg-green-500', 2: 'bg-lime-500', 3: 'bg-yellow-500', 4: 'bg-orange-500', 5: 'bg-red-500' };
    return colors[severity] ?? 'bg-gray-500';
  };

  return (
    <div className="min-h-screen p-4 pb-20">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">Cycle</h1>
        <p className="text-muted-foreground">Track your cycle and optimize your training</p>
      </div>

      <div className="space-y-6">
        {cycleStatus && <PhaseIndicator compact={false} />}

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>Today&apos;s Log</span>
              <span className="text-sm font-normal text-muted-foreground">
                {format(today, 'MMM d, yyyy')}
              </span>
            </CardTitle>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-2">
            <Button variant="outline" onClick={() => logPeriod(today)}>
              <Plus className="h-4 w-4 mr-1" />
              Log Period
            </Button>
            <SymptomLogger date={today} />
            <BBTInput date={today} />
          </CardContent>
        </Card>

        <CycleCalendar />

        {/* Recent Symptoms */}
        {recentSymptoms.length > 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Recent Symptoms</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {recentSymptoms.map(log => (
                  <div key={log.id} className="flex items-center justify-between p-2 border rounded-md">
                    <div>
                      <p className="font-medium">{getSymptomName(log.symptomId)}</p>
                      <p className="text-sm text-muted-foreground">
                        {format(new Date(log.date), 'MMM d')} ·{' '}
                        <Badge variant="outline" className="ml-1">{log.severity}/5</Badge>
                        {log.notes && <span className="ml-2 text-xs">&ldquo;{log.notes}&rdquo;</span>}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      {[...Array(5)].map((_, i) => (
                        <div
                          key={i}
                          className={`w-2 h-2 rounded-full ${i < log.severity ? getSeverityColor(log.severity) : 'bg-gray-200'}`}
                        />
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}

        {currentRecommendation && <RecommendationCard recommendation={currentRecommendation} />}
      </div>
    </div>
  );
}
