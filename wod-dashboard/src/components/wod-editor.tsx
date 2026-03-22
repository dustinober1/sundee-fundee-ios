"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import {
  DndContext,
  closestCenter,
  type DragEndEvent,
  PointerSensor,
  useSensor,
  useSensors,
} from "@dnd-kit/core";
import {
  SortableContext,
  verticalListSortingStrategy,
  useSortable,
  arrayMove,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { ExerciseRow } from "@/components/exercise-row";
import { validateWOD, type ValidationError } from "@/lib/validation";
import type { WOD, ProgramExercise } from "@/lib/types";

// ─── Props ───────────────────────────────────────────────────────────────────

interface WODEditorProps {
  wod: WOD | null;
  existingDates: string[];
  onSave: (wod: WOD) => void;
  onDelete: (id: string) => void;
  saving?: boolean;
}

// ─── Blank exercise ──────────────────────────────────────────────────────────

function blankExercise(): ProgramExercise {
  return {
    exercise: "",
    variant: undefined,
    sets: { type: "fixed", value: 3 },
    reps: { type: "fixed", value: 10 },
    percent1RM: undefined,
    restMinutes: undefined,
    notes: undefined,
    bodyweightOnly: undefined,
  };
}

// ─── Sortable wrapper ────────────────────────────────────────────────────────

function SortableExercise({
  id,
  exercise,
  onChange,
  onDelete,
}: {
  id: string;
  exercise: ProgramExercise;
  onChange: (ex: ProgramExercise) => void;
  onDelete: () => void;
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <div ref={setNodeRef} style={style} className="flex items-center gap-1">
      <button
        type="button"
        className="cursor-grab shrink-0 text-navy/30 hover:text-navy/60 px-1 text-lg select-none"
        {...attributes}
        {...listeners}
      >
        &#x2630;
      </button>
      <div className="flex-1 min-w-0">
        <ExerciseRow exercise={exercise} onChange={onChange} onDelete={onDelete} />
      </div>
    </div>
  );
}

// ─── Component ───────────────────────────────────────────────────────────────

export function WODEditor({ wod, existingDates, onSave, onDelete, saving = false }: WODEditorProps) {
  const [date, setDate] = useState("");
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [exercises, setExercises] = useState<ProgramExercise[]>([]);
  const [errors, setErrors] = useState<ValidationError[]>([]);
  const [exerciseKeys, setExerciseKeys] = useState<string[]>([]);
  const [keyCounter, setKeyCounter] = useState(0);

  // Sync from prop
  useEffect(() => {
    if (wod) {
      setDate(wod.date);
      setTitle(wod.title);
      setDescription(wod.description);
      setExercises(wod.exercises);
      // Generate stable keys for each exercise
      const keys = wod.exercises.map((_, i) => `ex-${i}`);
      setExerciseKeys(keys);
      setKeyCounter(wod.exercises.length);
      setErrors([]);
    }
  }, [wod]);

  const id = useMemo(() => `wod-${date}`, [date]);

  const isDuplicate = useMemo(() => {
    if (!date) return false;
    // Don't flag as duplicate if editing the same WOD
    return existingDates.some((d) => d === date) && wod?.date !== date;
  }, [date, existingDates, wod]);

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }));

  const fieldError = useCallback(
    (field: string) => errors.find((e) => e.field === field)?.message,
    [errors]
  );

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = exerciseKeys.indexOf(String(active.id));
    const newIndex = exerciseKeys.indexOf(String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    setExercises((prev) => arrayMove(prev, oldIndex, newIndex));
    setExerciseKeys((prev) => arrayMove(prev, oldIndex, newIndex));
  }

  function addExercise() {
    setExercises((prev) => [...prev, blankExercise()]);
    setExerciseKeys((prev) => [...prev, `ex-${keyCounter}`]);
    setKeyCounter((c) => c + 1);
  }

  function updateExercise(index: number, updated: ProgramExercise) {
    setExercises((prev) => prev.map((ex, i) => (i === index ? updated : ex)));
  }

  function deleteExercise(index: number) {
    setExercises((prev) => prev.filter((_, i) => i !== index));
    setExerciseKeys((prev) => prev.filter((_, i) => i !== index));
  }

  function handleSave() {
    const wodToSave: WOD = { id, date, title, description, exercises };
    const validationErrors = validateWOD(wodToSave);
    setErrors(validationErrors);
    if (validationErrors.length > 0) return;
    onSave(wodToSave);
  }

  const hasValidationErrors = useMemo(() => {
    const wodToCheck: WOD = { id, date, title, description, exercises };
    return validateWOD(wodToCheck).length > 0;
  }, [id, date, title, description, exercises]);

  // Placeholder when no WOD selected
  if (!wod) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40 text-lg">
        Select a WOD or create a new one
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full overflow-y-auto p-4">
      {/* Header fields */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">Date</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
          {fieldError("date") && (
            <p className="text-red-500 text-xs mt-1">{fieldError("date")}</p>
          )}
          {isDuplicate && (
            <div className="bg-yellow-50 border border-yellow-300 text-yellow-800 text-xs px-2 py-1 mt-1 rounded">
              A WOD already exists for this date. Saving will overwrite it.
            </div>
          )}
        </div>
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">ID</label>
          <input
            type="text"
            value={id}
            readOnly
            className="w-full border border-navy/10 rounded px-3 py-1.5 text-sm bg-navy/5 text-navy/50"
          />
          {fieldError("id") && (
            <p className="text-red-500 text-xs mt-1">{fieldError("id")}</p>
          )}
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">Title</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="WOD title"
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
        {fieldError("title") && (
          <p className="text-red-500 text-xs mt-1">{fieldError("title")}</p>
        )}
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">Description</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Brief description..."
          rows={2}
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40 resize-y"
        />
      </div>

      {/* Exercises */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <label className="text-sm font-medium text-navy/70">
            Exercises ({exercises.length})
          </label>
          <button
            type="button"
            onClick={addExercise}
            className="text-sm text-orange hover:text-orange/80 font-medium"
          >
            + Add Exercise
          </button>
        </div>

        {fieldError("exercises") && (
          <p className="text-red-500 text-xs mb-2">{fieldError("exercises")}</p>
        )}

        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={handleDragEnd}
        >
          <SortableContext
            items={exerciseKeys}
            strategy={verticalListSortingStrategy}
          >
            {exercises.map((ex, i) => {
              const errMsg = fieldError(`exercises[${i}]`);
              return (
                <div key={exerciseKeys[i]}>
                  <SortableExercise
                    id={exerciseKeys[i]}
                    exercise={ex}
                    onChange={(updated) => updateExercise(i, updated)}
                    onDelete={() => deleteExercise(i)}
                  />
                  {errMsg && (
                    <p className="text-red-500 text-xs ml-8 mb-1">{errMsg}</p>
                  )}
                </div>
              );
            })}
          </SortableContext>
        </DndContext>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3 pt-4 border-t border-navy/10 mt-auto">
        <button
          type="button"
          onClick={handleSave}
          disabled={hasValidationErrors || saving}
          className="bg-orange text-white px-4 py-2 rounded font-medium hover:bg-orange/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {saving ? "Saving…" : "Save"}
        </button>
        <button
          type="button"
          onClick={() => {
            if (window.confirm(`Are you sure you want to delete this WOD (${wod.title || wod.date})?`)) {
              onDelete(wod.id);
            }
          }}
          className="bg-red-500 text-white px-4 py-2 rounded font-medium hover:bg-red-600 transition-colors"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
