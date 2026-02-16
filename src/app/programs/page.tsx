'use client';

import { useExercise } from '@/contexts/exercise-context';
import { ProgramCard } from '@/components/programs/program-card';

export default function ProgramsPage() {
  const { programs } = useExercise();

  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Workout Programs</h1>

      <div className="space-y-4">
        {programs.map(program => (
          <ProgramCard key={program.id} program={program} />
        ))}
      </div>
    </div>
  );
}
