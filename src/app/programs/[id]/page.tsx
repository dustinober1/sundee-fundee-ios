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
          <div className="text-sm">
            <p><strong>Duration:</strong> {program.durationWeeks} weeks</p>
            <p><strong>Frequency:</strong> {program.daysPerWeek} days per week</p>
            <p><strong>Exercises:</strong> {program.exercises.join(', ')}</p>
          </div>

          <Button className="w-full">
            Start This Program
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
