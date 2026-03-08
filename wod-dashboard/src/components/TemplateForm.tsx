'use client';

import { WODFormData, ProgramExercise, TemplateType } from '@/types/wod';
import ExercisePicker from './ExercisePicker';

interface TemplateFormProps {
  formData: WODFormData;
  onChange: (data: WODFormData) => void;
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

function ExerciseRow({
  exercise,
  index,
  templateType,
  onUpdate,
  onRemove,
}: {
  exercise: ProgramExercise;
  index: number;
  templateType: TemplateType;
  onUpdate: (index: number, ex: ProgramExercise) => void;
  onRemove: (index: number) => void;
}) {
  const showSets = templateType === 'strength' || templateType === 'circuit';
  const showPercent = templateType === 'strength';
  const showRest = templateType === 'strength';

  return (
    <div className="flex items-start gap-2 p-3 bg-cream/50 rounded-lg border border-navy/10">
      <div className="flex-1 min-w-0">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <div className={showSets ? '' : 'sm:col-span-2'}>
            <label className="block text-xs font-medium text-navy/60 mb-1">Exercise</label>
            <ExercisePicker
              value={exercise.exercise}
              onChange={(name) =>
                onUpdate(index, { ...exercise, exercise: name })
              }
            />
          </div>
          {showSets && (
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="block text-xs font-medium text-navy/60 mb-1">Sets</label>
                <input
                  type="number"
                  min={1}
                  value={exercise.sets}
                  onChange={(e) =>
                    onUpdate(index, { ...exercise, sets: parseInt(e.target.value) || 1 })
                  }
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-navy/60 mb-1">Reps</label>
                <input
                  type="text"
                  value={exercise.reps}
                  onChange={(e) =>
                    onUpdate(index, {
                      ...exercise,
                      reps: /^\d+$/.test(e.target.value)
                        ? parseInt(e.target.value)
                        : e.target.value,
                    })
                  }
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
              </div>
            </div>
          )}
          {!showSets && (
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium text-navy/60 mb-1">Reps</label>
              <input
                type="text"
                value={exercise.reps}
                onChange={(e) =>
                  onUpdate(index, {
                    ...exercise,
                    reps: /^\d+$/.test(e.target.value)
                      ? parseInt(e.target.value)
                      : e.target.value,
                  })
                }
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
          )}
          {showPercent && (
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">% 1RM</label>
              <input
                type="number"
                min={0}
                max={100}
                step={5}
                value={exercise.percent1RM ? Math.round(exercise.percent1RM * 100) : ''}
                onChange={(e) =>
                  onUpdate(index, {
                    ...exercise,
                    percent1RM: e.target.value
                      ? parseInt(e.target.value) / 100
                      : null,
                  })
                }
                placeholder="e.g. 75"
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
          )}
          {showRest && (
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
                    restMinutes: e.target.value
                      ? parseFloat(e.target.value)
                      : null,
                  })
                }
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
          )}
        </div>
        <div className="mt-2">
          <label className="block text-xs font-medium text-navy/60 mb-1">Notes</label>
          <input
            type="text"
            value={exercise.notes ?? ''}
            onChange={(e) =>
              onUpdate(index, {
                ...exercise,
                notes: e.target.value || null,
              })
            }
            placeholder="Optional notes..."
            className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
          />
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

export default function TemplateForm({ formData, onChange }: TemplateFormProps) {
  const { templateType, exercises } = formData;

  const updateExercise = (index: number, updated: ProgramExercise) => {
    const newExercises = [...exercises];
    newExercises[index] = updated;
    onChange({ ...formData, exercises: newExercises });
  };

  const removeExercise = (index: number) => {
    onChange({
      ...formData,
      exercises: exercises.filter((_, i) => i !== index),
    });
  };

  const addExercise = () => {
    onChange({
      ...formData,
      exercises: [...exercises, emptyExercise()],
    });
  };

  return (
    <div className="space-y-4">
      {/* Template-specific fields */}
      {(templateType === 'amrap' || templateType === 'emom' || templateType === 'forTime') && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {(templateType === 'amrap' || templateType === 'forTime') && (
            <div>
              <label className="block text-sm font-medium text-navy mb-1">
                Time Cap (minutes)
              </label>
              <input
                type="number"
                min={1}
                value={formData.timeCap ?? ''}
                onChange={(e) =>
                  onChange({
                    ...formData,
                    timeCap: e.target.value ? parseInt(e.target.value) : undefined,
                  })
                }
                placeholder="e.g. 12"
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
          )}
          {templateType === 'emom' && (
            <>
              <div>
                <label className="block text-sm font-medium text-navy mb-1">
                  Duration (minutes)
                </label>
                <input
                  type="number"
                  min={1}
                  value={formData.timeCap ?? ''}
                  onChange={(e) =>
                    onChange({
                      ...formData,
                      timeCap: e.target.value ? parseInt(e.target.value) : undefined,
                    })
                  }
                  placeholder="e.g. 20"
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-navy mb-1">
                  Interval (minutes)
                </label>
                <input
                  type="number"
                  min={0.5}
                  step={0.5}
                  value={formData.interval ?? ''}
                  onChange={(e) =>
                    onChange({
                      ...formData,
                      interval: e.target.value ? parseFloat(e.target.value) : undefined,
                    })
                  }
                  placeholder="e.g. 1"
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
              </div>
            </>
          )}
        </div>
      )}

      {templateType === 'circuit' && (
        <div>
          <label className="block text-sm font-medium text-navy mb-1">Rounds</label>
          <input
            type="number"
            min={1}
            value={formData.rounds ?? ''}
            onChange={(e) =>
              onChange({
                ...formData,
                rounds: e.target.value ? parseInt(e.target.value) : undefined,
              })
            }
            placeholder="e.g. 4"
            className="w-full max-w-[200px] px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
          />
        </div>
      )}

      {/* Exercise list */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-lg font-bold text-navy">Exercises</h3>
          <button
            onClick={addExercise}
            className="flex items-center gap-1 px-3 py-1.5 text-sm font-medium bg-orange text-cream rounded-md hover:bg-orange/90 transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Exercise
          </button>
        </div>

        {exercises.length === 0 ? (
          <p className="text-sm text-navy/40 text-center py-6 bg-cream-dark/30 rounded-lg border border-dashed border-navy/20">
            No exercises yet. Add one or generate from text above.
          </p>
        ) : (
          <div className="space-y-2">
            {exercises.map((ex, idx) => (
              <ExerciseRow
                key={idx}
                exercise={ex}
                index={idx}
                templateType={templateType}
                onUpdate={updateExercise}
                onRemove={removeExercise}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
