'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ProgramListItem } from '@/types/program';
import { fetchPrograms, deleteProgram } from '@/lib/program-service';

const DIFFICULTY_COLORS: Record<string, string> = {
  beginner: 'bg-green-100 text-green-700',
  intermediate: 'bg-yellow-100 text-yellow-700',
  advanced: 'bg-red-100 text-red-700',
};

const CATEGORY_LABELS: Record<string, string> = {
  strength: 'Strength',
  hypertrophy: 'Hypertrophy',
  powerlifting: 'Powerlifting',
  general: 'General',
};

export default function ProgramList() {
  const router = useRouter();
  const [programs, setPrograms] = useState<ProgramListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPrograms();
  }, []);

  async function loadPrograms() {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchPrograms();
      setPrograms(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load programs');
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete(id: string, name: string) {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    try {
      await deleteProgram(id);
      setPrograms((prev) => prev.filter((p) => p.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete program');
    }
  }

  if (loading) {
    return (
      <div className="text-center py-12 text-navy/60 flex flex-col items-center gap-2">
        <svg className="animate-spin h-6 w-6 text-orange" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        Loading programs...
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-navy">Programs</h1>
        <button
          onClick={() => router.push('/programs/new')}
          className="flex items-center gap-2 px-4 py-2 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 transition-colors text-sm"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Program
        </button>
      </div>

      {error && (
        <div className="mb-4 px-4 py-3 rounded-lg text-sm font-medium bg-red-50 text-red-700 border border-red-200">
          {error}
        </div>
      )}

      {programs.length === 0 ? (
        <div className="art-deco-card p-12 text-center">
          <p className="text-navy/40 text-lg mb-4">No programs yet</p>
          <button
            onClick={() => router.push('/programs/new')}
            className="px-6 py-3 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 transition-colors"
          >
            Create Your First Program
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {programs.map((program) => (
            <div
              key={program.id}
              className="art-deco-card p-5 cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => router.push(`/programs/${program.id}`)}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <h3 className="text-lg font-bold text-navy truncate">{program.name}</h3>
                  <p className="text-sm text-navy/60 mt-1 line-clamp-2">
                    {program.description || 'No description'}
                  </p>
                </div>
                <span
                  className={`ml-3 px-2.5 py-0.5 rounded-full text-xs font-bold tracking-wider uppercase ${
                    program.status === 'published'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-yellow-100 text-yellow-700'
                  }`}
                >
                  {program.status}
                </span>
              </div>

              <div className="flex flex-wrap gap-2 mb-3">
                <span className="px-2 py-0.5 rounded text-xs font-medium bg-navy/10 text-navy">
                  {CATEGORY_LABELS[program.category] || program.category}
                </span>
                <span className="px-2 py-0.5 rounded text-xs font-medium bg-navy/10 text-navy">
                  {program.durationWeeks} weeks
                </span>
                <span className="px-2 py-0.5 rounded text-xs font-medium bg-navy/10 text-navy">
                  {program.sessionsPerWeek}x/week
                </span>
                <span
                  className={`px-2 py-0.5 rounded text-xs font-medium ${
                    DIFFICULTY_COLORS[program.difficulty] || 'bg-navy/10 text-navy'
                  }`}
                >
                  {program.difficulty}
                </span>
                {program.startDate && (
                  <span className="px-2 py-0.5 rounded text-xs font-medium bg-navy/10 text-navy">
                    {program.startDate}
                  </span>
                )}
              </div>

              <div className="flex items-center justify-end">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleDelete(program.id, program.name);
                  }}
                  className="p-1.5 text-red-500 hover:bg-red-50 rounded-md transition-colors"
                  aria-label="Delete program"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
