'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { ProgramFormData, ExerciseValue } from '@/types/program';
import { fetchProgramByID } from '@/lib/program-service';

function formatExerciseValue(value: ExerciseValue): string {
  if (typeof value === 'number') return String(value);
  if (Array.isArray(value)) return `${value[0]}-${value[1]}`;
  return value;
}

const CATEGORY_LABELS: Record<string, string> = {
  strength: 'Strength',
  hypertrophy: 'Hypertrophy',
  powerlifting: 'Powerlifting',
  general: 'General',
};

const DIFFICULTY_COLORS: Record<string, string> = {
  beginner: 'bg-green-100 text-green-700',
  intermediate: 'bg-yellow-100 text-yellow-700',
  advanced: 'bg-red-100 text-red-700',
};

interface ProgramPreviewProps {
  programId: string;
}

export default function ProgramPreview({ programId }: ProgramPreviewProps) {
  const router = useRouter();
  const [program, setProgram] = useState<ProgramFormData | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      setLoading(true);
      const data = await fetchProgramByID(programId);
      setProgram(data);
    } finally {
      setLoading(false);
    }
  }, [programId]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading) {
    return (
      <div className="text-center py-12 text-navy/60 flex flex-col items-center gap-2">
        <svg className="animate-spin h-6 w-6 text-orange" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        Loading preview...
      </div>
    );
  }

  if (!program) {
    return <div className="text-center py-12 text-navy/60">Program not found</div>;
  }

  return (
    <div className="max-w-4xl mx-auto">
      <button
        onClick={() => router.push(`/programs/${programId}`)}
        className="text-sm text-orange hover:underline mb-4 inline-flex items-center gap-1"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
        Back to Editor
      </button>

      {/* Program Header */}
      <div className="art-deco-card p-6 mb-6">
        <h1 className="text-3xl font-bold text-navy mb-2">{program.name}</h1>
        <p className="text-navy/60 mb-4">{program.description}</p>
        <div className="flex flex-wrap gap-2">
          <span className="px-3 py-1 rounded-full text-xs font-bold bg-navy/10 text-navy">
            {CATEGORY_LABELS[program.category] || program.category}
          </span>
          <span className="px-3 py-1 rounded-full text-xs font-bold bg-navy/10 text-navy">
            {program.durationWeeks} weeks
          </span>
          <span className="px-3 py-1 rounded-full text-xs font-bold bg-navy/10 text-navy">
            {program.sessionsPerWeek}x/week
          </span>
          <span
            className={`px-3 py-1 rounded-full text-xs font-bold ${
              DIFFICULTY_COLORS[program.difficulty] || 'bg-navy/10 text-navy'
            }`}
          >
            {program.difficulty}
          </span>
        </div>
        {program.startDate && program.endDate && (
          <p className="mt-3 text-sm text-navy/60">
            Sundays from {new Date(program.startDate + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} to {new Date(program.endDate + 'T00:00:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })} &middot; Make up missed workouts anytime
          </p>
        )}
      </div>

      {/* Phase Overview */}
      {program.phases.length > 0 && (
        <div className="art-deco-card p-5 mb-6">
          <h2 className="text-lg font-bold text-navy mb-3">Phases</h2>
          <div className="space-y-2">
            {program.phases.map((phase) => (
              <div
                key={phase.id}
                className="flex items-center justify-between p-3 bg-cream-dark/30 rounded-lg"
              >
                <div>
                  <span className="font-bold text-navy">{phase.name}</span>
                  <span className="text-sm text-navy/60 ml-2">{phase.goal}</span>
                </div>
                <span className="text-xs text-navy/40">
                  Weeks {phase.weekRange[0]}-{phase.weekRange[1]}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Week-by-week breakdown */}
      {program.weeks.map((week) => {
        const phase = program.phases.find((p) => p.id === week.phaseId);
        const weekSunday = program.startDate
          ? (() => {
              const d = new Date(program.startDate + 'T00:00:00');
              d.setDate(d.getDate() + (week.week - 1) * 7);
              return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
            })()
          : null;
        return (
          <div key={week.week} className="art-deco-card p-5 mb-4">
            <div className="flex items-center gap-2 mb-3">
              <h2 className="text-lg font-bold text-navy">Week {week.week}</h2>
              {weekSunday && (
                <span className="text-xs text-navy/40">Sun {weekSunday}</span>
              )}
              {phase && (
                <span className="px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-700">
                  {phase.name}
                </span>
              )}
              {week.isTestWeek && (
                <span className="px-2 py-0.5 rounded text-xs font-bold bg-gold/20 text-gold">
                  TEST WEEK
                </span>
              )}
            </div>

            <div className="space-y-4">
              {week.sessions.map((session) => (
                <div key={session.sessionId}>
                  <div className="flex items-center gap-2 mb-2">
                    <h3 className="font-bold text-navy text-sm">{session.sessionName}</h3>
                    <span className="text-xs text-navy/40 capitalize">{session.sessionType}</span>
                    {session.focus && (
                      <span className="text-xs text-navy/40">&middot; {session.focus}</span>
                    )}
                  </div>

                  <div className="overflow-x-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="text-xs text-navy/50 font-medium border-b border-navy/10">
                          <th className="text-left py-1.5 pr-3">Exercise</th>
                          <th className="text-center py-1.5 px-2">Sets</th>
                          <th className="text-center py-1.5 px-2">Reps</th>
                          <th className="text-center py-1.5 px-2">%1RM</th>
                          <th className="text-center py-1.5 px-2">Rest</th>
                          <th className="text-left py-1.5 pl-2">Notes</th>
                        </tr>
                      </thead>
                      <tbody>
                        {session.exercises.map((ex, i) => (
                          <tr key={i} className="border-b border-navy/5">
                            <td className="py-1.5 pr-3 text-navy font-medium">
                              {ex.exercise}
                              {ex.variant && (
                                <span className="text-navy/40 text-xs ml-1">({ex.variant})</span>
                              )}
                            </td>
                            <td className="text-center py-1.5 px-2">
                              {formatExerciseValue(ex.sets)}
                            </td>
                            <td className="text-center py-1.5 px-2">
                              {formatExerciseValue(ex.reps)}
                            </td>
                            <td className="text-center py-1.5 px-2 text-navy/60">
                              {ex.percent1RM != null
                                ? `${Math.round(ex.percent1RM * 100)}%`
                                : '-'}
                            </td>
                            <td className="text-center py-1.5 px-2 text-navy/60">
                              {ex.restMinutes != null ? `${ex.restMinutes}m` : '-'}
                            </td>
                            <td className="py-1.5 pl-2 text-navy/50 text-xs">
                              {ex.notes || ''}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
            </div>
          </div>
        );
      })}
    </div>
  );
}
