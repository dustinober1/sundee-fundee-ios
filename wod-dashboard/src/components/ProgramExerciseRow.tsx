'use client';

import { ProgramExercise } from '@/types/program';
import ExercisePicker from './ExercisePicker';
import ExerciseValueInput from './ExerciseValueInput';

interface ProgramExerciseRowProps {
  exercise: ProgramExercise;
  index: number;
  onUpdate: (index: number, ex: ProgramExercise) => void;
  onRemove: (index: number) => void;
}

export default function ProgramExerciseRow({
  exercise,
  index,
  onUpdate,
  onRemove,
}: ProgramExerciseRowProps) {
  return (
    <div className="flex items-start gap-2 p-3 bg-cream/50 rounded-lg border border-navy/10">
      <div className="flex-1 min-w-0">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
          {/* Exercise name */}
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Exercise</label>
            <ExercisePicker
              value={exercise.exercise}
              onChange={(name) => onUpdate(index, { ...exercise, exercise: name })}
            />
          </div>

          {/* Sets */}
          <ExerciseValueInput
            label="Sets"
            value={exercise.sets}
            onChange={(sets) => onUpdate(index, { ...exercise, sets })}
          />

          {/* Reps */}
          <ExerciseValueInput
            label="Reps"
            value={exercise.reps}
            onChange={(reps) => onUpdate(index, { ...exercise, reps })}
          />
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-2">
          {/* %1RM */}
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">% 1RM</label>
            <input
              type="number"
              min={0}
              max={150}
              step={5}
              value={exercise.percent1RM != null ? Math.round(exercise.percent1RM * 100) : ''}
              onChange={(e) =>
                onUpdate(index, {
                  ...exercise,
                  percent1RM: e.target.value ? parseInt(e.target.value) / 100 : null,
                })
              }
              placeholder="e.g. 75"
              className="w-full px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>

          {/* Rest */}
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Rest (min)</label>
            <input
              type="number"
              min={0}
              step={0.5}
              value={exercise.restMinutes ?? ''}
              onChange={(e) =>
                onUpdate(index, {
                  ...exercise,
                  restMinutes: e.target.value ? parseFloat(e.target.value) : null,
                })
              }
              className="w-full px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>

          {/* Variant */}
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Variant</label>
            <input
              type="text"
              value={exercise.variant ?? ''}
              onChange={(e) =>
                onUpdate(index, { ...exercise, variant: e.target.value || null })
              }
              placeholder="Optional"
              className="w-full px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Notes</label>
            <input
              type="text"
              value={exercise.notes ?? ''}
              onChange={(e) =>
                onUpdate(index, { ...exercise, notes: e.target.value || null })
              }
              placeholder="Optional"
              className="w-full px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
        </div>
      </div>

      <button
        onClick={() => onRemove(index)}
        className="mt-5 p-1.5 text-red-500 hover:bg-red-50 rounded-md transition-colors"
        aria-label="Remove exercise"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      </button>
    </div>
  );
}
