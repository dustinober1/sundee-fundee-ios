'use client';

import { notFound } from 'next/navigation';
import { useExercise } from '@/contexts/exercise-context';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useParams } from 'next/navigation';

export default function ProgramDetailPage() {
  const params = useParams();
  const { getProgram } = useExercise();
  const program = getProgram(params.id as string);

  if (!program) {
    notFound();
  }

  return (
    <div className="min-h-screen p-4 pb-20">
      <Card>
        <CardHeader>
          <div className="flex justify-between items-start">
            <CardTitle>{program.name}</CardTitle>
            <Badge>{program.difficulty}</Badge>
          </div>
          <CardDescription>{program.description}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1 text-sm">
            <p><strong>Duration:</strong> {program.durationWeeks} weeks</p>
            <p><strong>Frequency:</strong> {program.sessionsPerWeek} sessions per week</p>
            <p><strong>Sessions:</strong> {program.sessionsPerWeek} per week</p>
          </div>

          {program.phases.length > 0 && (
            <div className="space-y-2">
              <h3 className="font-semibold">Training Phases</h3>
              {program.phases.map(phase => (
                <div key={phase.id} className="rounded-lg border p-3">
                  <p className="font-medium">{phase.name}</p>
                  <p className="text-muted-foreground text-sm">{phase.goal}</p>
                  <p className="text-muted-foreground text-xs">
                    Weeks {phase.weekRange[0]}-{phase.weekRange[1]}
                  </p>
                </div>
              ))}
            </div>
          )}

          <Button className="w-full">
            Start This Program
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
