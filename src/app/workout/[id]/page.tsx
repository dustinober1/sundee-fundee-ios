'use client';

import { useExercise } from '@/contexts/exercise-context';
import { ExerciseCard } from '@/components/workout/exercise-card';
import { useParams } from 'next/navigation';
import { RestTimerProvider, useRestTimerContext } from '@/contexts/RestTimerContext';
import { RestTimerPill, RestTimerExpanded } from '@/components/rest-timer';
import type { Exercise } from '@/types';
import { ScaleButton, FadeIn, StaggerList, StaggerItem } from '@/components/animations';
import { useConfetti } from '@/hooks/use-confetti';

function WorkoutContent() {
  const params = useParams();
  const { getProgram } = useExercise();
  const { startRest, settings } = useRestTimerContext();
  const { fireConfetti } = useConfetti();
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

  const handleSetComplete = (exercise: Exercise) => {
    if (settings.autoStartEnabled) {
      // Convert restMinutes to seconds, default to 3 minutes if not specified
      const restSeconds = (exercise.restMinutes ?? 3) * 60;
      // Format exercise name for display
      const exerciseName = exercise.exercise.replace(/-/g, ' ');
      startRest(restSeconds, exerciseName);
    }
  };

  const handleComplete = () => {
    fireConfetti();
    // TODO: Add actual completion logic here
  };

  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-2">Today's Workout</h1>
        <p className="text-muted-foreground mb-4">{program.name}</p>
      </FadeIn>

      <StaggerList className="space-y-4">
        {workout?.exercises.map(exercise => (
          <StaggerItem key={exercise.exercise}>
            <ExerciseCard
              exercise={exercise}
              prescribedWeight={195} // TODO: Calculate from user's 1RM
              onSetComplete={handleSetComplete}
            />
          </StaggerItem>
        ))}
      </StaggerList>

      <FadeIn delay={0.5}>
        <div className="mt-6">
          <ScaleButton
            className="w-full"
            size="lg"
            onClick={handleComplete}
          >
            Complete Workout
          </ScaleButton>
        </div>
      </FadeIn>
    </div>
  );
}

export default function WorkoutPage() {
  return (
    <RestTimerProvider>
      <WorkoutContent />
      <RestTimerPill />
      <RestTimerExpanded />
    </RestTimerProvider>
  );
}
