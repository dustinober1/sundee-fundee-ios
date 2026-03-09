'use client';

import { ProgramSession, ProgramExercise } from '@/types/program';
import ProgramExerciseRow from './ProgramExerciseRow';

interface SessionCardProps {
  session: ProgramSession;
  sessionIndex: number;
  onUpdate: (session: ProgramSession) => void;
  onRemove: () => void;
}

function emptyExercise(): ProgramExercise {
  return {
    exercise: '',
    variant: null,
    sets: 3,
    reps: 10,
    percent1RM: null,
    restMinutes: null,
    notes: null,
    bodyweightOnly: false,
  };
}

const SESSION_TYPES = ['strength', 'hypertrophy', 'power', 'conditioning', 'recovery'];

export default function SessionCard({
  session,
  sessionIndex,
  onUpdate,
  onRemove,
}: SessionCardProps) {
  function updateExercise(index: number, updated: ProgramExercise) {
    const newExercises = [...session.exercises];
    newExercises[index] = updated;
    onUpdate({ ...session, exercises: newExercises });
  }

  function removeExercise(index: number) {
    onUpdate({
      ...session,
      exercises: session.exercises.filter((_, i) => i !== index),
    });
  }

  function addExercise() {
    onUpdate({
      ...session,
      exercises: [...session.exercises, emptyExercise()],
    });
  }

  return (
    <div className="art-deco-card p-4">
      {/* Session header */}
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 grid grid-cols-1 sm:grid-cols-3 gap-2">
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Session Name</label>
            <input
              type="text"
              value={session.sessionName}
              onChange={(e) => onUpdate({ ...session, sessionName: e.target.value })}
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Type</label>
            <select
              value={session.sessionType}
              onChange={(e) => onUpdate({ ...session, sessionType: e.target.value })}
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              {SESSION_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t.charAt(0).toUpperCase() + t.slice(1)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Focus</label>
            <input
              type="text"
              value={session.focus}
              onChange={(e) => onUpdate({ ...session, focus: e.target.value })}
              placeholder="e.g. Upper Body, Squat"
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
        </div>
        <button
          onClick={onRemove}
          className="ml-2 mt-5 p-1.5 text-red-500 hover:bg-red-50 rounded-md transition-colors"
          aria-label="Remove session"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      {/* Exercises */}
      <div className="space-y-2">
        {session.exercises.map((ex, idx) => (
          <ProgramExerciseRow
            key={idx}
            exercise={ex}
            index={idx}
            onUpdate={updateExercise}
            onRemove={removeExercise}
          />
        ))}
      </div>

      <button
        onClick={addExercise}
        className="mt-3 flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-orange border border-orange/30 rounded-md hover:bg-orange/10 transition-colors"
      >
        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
        </svg>
        Add Exercise
      </button>
    </div>
  );
}
