"use client";

import { ExerciseAutocomplete } from "@/components/exercise-autocomplete";
import { decodeExerciseValue, ExerciseValue, ProgramExercise } from "@/lib/types";

// ─── Helper ───────────────────────────────────────────────────────────────────

export function evToString(ev: ExerciseValue): string {
  switch (ev.type) {
    case "fixed":
      return String(ev.value);
    case "amrap":
      return "AMRAP";
    case "range":
      return `${ev.low}-${ev.high}`;
    case "text":
      return ev.text;
  }
}

// ─── Props ────────────────────────────────────────────────────────────────────

interface ExerciseRowProps {
  exercise: ProgramExercise;
  onChange: (updated: ProgramExercise) => void;
  onDelete: () => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function ExerciseRow({ exercise, onChange, onDelete }: ExerciseRowProps) {
  const inputClass =
    "border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40";

  function update(patch: Partial<ProgramExercise>) {
    onChange({ ...exercise, ...patch });
  }

  return (
    <div className="flex items-center gap-2 border-b border-navy/10 py-2">
      {/* Exercise name */}
      <div className="w-52 shrink-0">
        <ExerciseAutocomplete
          value={exercise.exercise}
          onChange={(name) => update({ exercise: name })}
        />
      </div>

      {/* Variant */}
      <input
        className={`${inputClass} w-24 shrink-0`}
        type="text"
        placeholder="variant"
        value={exercise.variant ?? ""}
        onChange={(e) =>
          update({ variant: e.target.value.trim() === "" ? undefined : e.target.value })
        }
      />

      {/* Sets */}
      <input
        className={`${inputClass} w-16 shrink-0`}
        type="text"
        placeholder="sets"
        value={evToString(exercise.sets)}
        onChange={(e) =>
          update({ sets: decodeExerciseValue(e.target.value) })
        }
      />

      {/* Reps */}
      <input
        className={`${inputClass} w-20 shrink-0`}
        type="text"
        placeholder="reps"
        value={evToString(exercise.reps)}
        onChange={(e) =>
          update({ reps: decodeExerciseValue(e.target.value) })
        }
      />

      {/* %1RM */}
      <input
        className={`${inputClass} w-16 shrink-0`}
        type="number"
        placeholder="%1RM"
        step={0.01}
        min={0}
        max={1.5}
        value={exercise.percent1RM ?? ""}
        onChange={(e) =>
          update({
            percent1RM:
              e.target.value === "" ? undefined : parseFloat(e.target.value),
          })
        }
      />

      {/* Rest (minutes) */}
      <input
        className={`${inputClass} w-16 shrink-0`}
        type="number"
        placeholder="rest"
        step={0.5}
        min={0}
        value={exercise.restMinutes ?? ""}
        onChange={(e) =>
          update({
            restMinutes:
              e.target.value === "" ? undefined : parseFloat(e.target.value),
          })
        }
      />

      {/* Notes */}
      <input
        className={`${inputClass} flex-1 min-w-0`}
        type="text"
        placeholder="notes"
        value={exercise.notes ?? ""}
        onChange={(e) =>
          update({ notes: e.target.value.trim() === "" ? undefined : e.target.value })
        }
      />

      {/* BW checkbox */}
      <label className="flex items-center gap-1 text-sm shrink-0 cursor-pointer select-none">
        <input
          type="checkbox"
          checked={exercise.bodyweightOnly ?? false}
          onChange={(e) => update({ bodyweightOnly: e.target.checked || undefined })}
          className="accent-navy"
        />
        <span className="text-navy/70 whitespace-nowrap">BW</span>
      </label>

      {/* Delete */}
      <button
        type="button"
        onClick={onDelete}
        aria-label="Delete exercise"
        className="shrink-0 text-red-500 hover:text-red-700 font-bold text-lg leading-none px-1"
      >
        ×
      </button>
    </div>
  );
}
