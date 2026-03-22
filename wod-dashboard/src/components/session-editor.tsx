"use client";

import { useState } from "react";
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
import type { ProgramExercise, ProgramSession } from "@/lib/types";

// ─── Props ───────────────────────────────────────────────────────────────────

interface SessionEditorProps {
  session: ProgramSession;
  onChange: (updated: ProgramSession) => void;
  onDelete: () => void;
}

// ─── Blank Exercise ──────────────────────────────────────────────────────────

function blankExercise(): ProgramExercise {
  return {
    exercise: "",
    variant: null as unknown as undefined,
    sets: { type: "fixed", value: 3 },
    reps: { type: "fixed", value: 8 },
    percent1RM: null as unknown as undefined,
    restMinutes: null as unknown as undefined,
    notes: null as unknown as undefined,
    bodyweightOnly: false,
  };
}

// ─── Sortable Exercise Wrapper ───────────────────────────────────────────────

function SortableExerciseRow({
  id,
  exercise,
  onChange,
  onDelete,
}: {
  id: string;
  exercise: ProgramExercise;
  onChange: (updated: ProgramExercise) => void;
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

export function SessionEditor({ session, onChange, onDelete }: SessionEditorProps) {
  const [exerciseKeys, setExerciseKeys] = useState<string[]>(
    session.exercises.map((_, i) => `ex-${i}`)
  );
  const [keyCounter, setKeyCounter] = useState(session.exercises.length);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } })
  );

  const inputClass =
    "border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40";

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = exerciseKeys.indexOf(String(active.id));
    const newIndex = exerciseKeys.indexOf(String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    const newExercises = arrayMove(session.exercises, oldIndex, newIndex);
    setExerciseKeys((prev) => arrayMove(prev, oldIndex, newIndex));
    onChange({ ...session, exercises: newExercises });
  }

  function updateExercise(index: number, updated: ProgramExercise) {
    const newExercises = session.exercises.map((ex, i) =>
      i === index ? updated : ex
    );
    onChange({ ...session, exercises: newExercises });
  }

  function deleteExercise(index: number) {
    const newExercises = session.exercises.filter((_, i) => i !== index);
    setExerciseKeys((prev) => prev.filter((_, i) => i !== index));
    onChange({ ...session, exercises: newExercises });
  }

  function addExercise() {
    onChange({ ...session, exercises: [...session.exercises, blankExercise()] });
    setExerciseKeys((prev) => [...prev, `ex-${keyCounter}`]);
    setKeyCounter((c) => c + 1);
  }

  return (
    <div className="border border-navy/10 rounded p-3 bg-white mb-3">
      <div className="flex items-center gap-2 mb-3">
        <input
          className={`${inputClass} flex-1`}
          type="text"
          placeholder="Session name"
          value={session.sessionName}
          onChange={(e) => onChange({ ...session, sessionName: e.target.value })}
        />

        <select
          className={`${inputClass} w-36`}
          value={session.sessionType}
          onChange={(e) => onChange({ ...session, sessionType: e.target.value })}
        >
          <option value="Lift">Lift</option>
          <option value="Conditioning">Conditioning</option>
          <option value="Recovery">Recovery</option>
        </select>

        <input
          className={`${inputClass} w-40`}
          type="text"
          placeholder="Focus"
          value={session.focus}
          onChange={(e) => onChange({ ...session, focus: e.target.value })}
        />

        <button
          type="button"
          onClick={onDelete}
          className="shrink-0 text-red-400 hover:text-red-600 text-lg px-1"
          title="Delete session"
        >
          &times;
        </button>
      </div>

      {/* Exercises */}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={handleDragEnd}
      >
        <SortableContext
          items={exerciseKeys}
          strategy={verticalListSortingStrategy}
        >
          {session.exercises.map((ex, i) => (
            <SortableExerciseRow
              key={exerciseKeys[i]}
              id={exerciseKeys[i]}
              exercise={ex}
              onChange={(updated) => updateExercise(i, updated)}
              onDelete={() => deleteExercise(i)}
            />
          ))}
        </SortableContext>
      </DndContext>

      <button
        type="button"
        onClick={addExercise}
        className="text-sm text-orange hover:text-orange/80 font-medium mt-2"
      >
        + Add Exercise
      </button>
    </div>
  );
}
