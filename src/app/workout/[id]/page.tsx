'use client';

import { useExercise } from '@/contexts/exercise-context';
import { ExerciseCard } from '@/components/workout/exercise-card';
import { Button } from '@/components/ui/button';
import { useParams } from 'next/navigation';
import { RestTimerProvider } from '@/contexts/RestTimerContext';
import { RestTimerPill, RestTimerExpanded } from '@/components/rest-timer';

export default function WorkoutPage() {
  const params = useParams();
  const { getProgram } = useExercise();
  const program = getProgram(params.id as string);

  if (!program) {
    return (
      <div className="min-h-screen p-4 pb-20">
        <p>Program not found</p>
      </div>
    );
  }

  // For MVP, showing week 1, day 1
  const workout = program.weeks[0]?.days[0];

  return (
    <RestTimerProvider>
      <div className="min-h-screen p-4 pb-20">
        <h1 className="text-2xl font-bold mb-2">Today's Workout</h1>
        <p className="text-muted-foreground mb-4">{program.name}</p>

        <div className="space-y-4">
          {workout?.exercises.map(exercise => (
            <ExerciseCard
              key={exercise.exercise}
              exercise={exercise}
              prescribedWeight={195} // TODO: Calculate from user's 1RM
            />
          ))}
        </div>

        <Button className="w-full mt-6" size="lg">
          Complete Workout
        </Button>
      </div>
      <RestTimerPill />
      <RestTimerExpanded />
    </RestTimerProvider>
  );
}
