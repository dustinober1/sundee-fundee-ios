'use client';

import { useExercise } from '@/contexts/exercise-context';
import { ProgramCard } from '@/components/programs/program-card';
import { FadeIn, StaggerList, StaggerItem } from '@/components/animations';

export default function ProgramsPage() {
  const { programs } = useExercise();

  return (
    <div className="min-h-screen p-4 pb-20">
      <FadeIn>
        <h1 className="text-2xl font-bold mb-4">Workout Programs</h1>
      </FadeIn>

      <StaggerList className="space-y-6">
        {programs.map(program => (
          <StaggerItem key={program.id}>
            <ProgramCard program={program} />
          </StaggerItem>
        ))}
      </StaggerList>
    </div>
  );
}
