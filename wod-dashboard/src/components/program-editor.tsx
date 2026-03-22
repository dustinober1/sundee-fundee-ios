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
import { validateProgram, type ValidationError } from "@/lib/validation";
import { WeekEditor } from "@/components/week-editor";
import type { Program, ProgramPhase, ProgramSession, ProgramWeek } from "@/lib/types";

// ─── Props ───────────────────────────────────────────────────────────────────

interface ProgramEditorProps {
  program: Program | null;
  onSave: (program: Program) => void;
  onDelete: (id: string) => void;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

// ─── Sortable Phase Row ─────────────────────────────────────────────────────

function SortablePhaseRow({
  id,
  phase,
  onChange,
  onDelete,
}: {
  id: string;
  phase: ProgramPhase;
  onChange: (updated: ProgramPhase) => void;
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
    <div
      ref={setNodeRef}
      style={style}
      className="flex items-center gap-2 p-2 border border-navy/10 rounded bg-white mb-2"
    >
      <button
        type="button"
        className="cursor-grab shrink-0 text-navy/30 hover:text-navy/60 px-1 text-lg select-none"
        {...attributes}
        {...listeners}
      >
        &#x2630;
      </button>

      <div className="flex-1 grid grid-cols-4 gap-2 min-w-0">
        <input
          type="text"
          value={phase.name}
          onChange={(e) =>
            onChange({
              ...phase,
              name: e.target.value,
              id: slugify(e.target.value),
            })
          }
          placeholder="Phase name"
          className="border border-navy/20 rounded px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
        <input
          type="text"
          value={phase.goal}
          onChange={(e) => onChange({ ...phase, goal: e.target.value })}
          placeholder="Goal"
          className="border border-navy/20 rounded px-2 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
        <div className="flex items-center gap-1">
          <span className="text-xs text-navy/50">Wk</span>
          <input
            type="number"
            min={1}
            value={phase.weekRange[0] ?? 1}
            onChange={(e) =>
              onChange({
                ...phase,
                weekRange: [parseInt(e.target.value) || 1, phase.weekRange[1] ?? 1],
              })
            }
            className="w-14 border border-navy/20 rounded px-1 py-1 text-sm text-center focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
          <span className="text-xs text-navy/50">-</span>
          <input
            type="number"
            min={1}
            value={phase.weekRange[1] ?? 1}
            onChange={(e) =>
              onChange({
                ...phase,
                weekRange: [phase.weekRange[0] ?? 1, parseInt(e.target.value) || 1],
              })
            }
            className="w-14 border border-navy/20 rounded px-1 py-1 text-sm text-center focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
        </div>
        <div className="flex items-center">
          <span className="text-xs text-navy/40 truncate mr-1">
            {phase.id || "auto-id"}
          </span>
        </div>
      </div>

      <button
        type="button"
        onClick={onDelete}
        className="shrink-0 text-red-400 hover:text-red-600 text-lg px-1"
        title="Remove phase"
      >
        &times;
      </button>
    </div>
  );
}

// ─── Component ───────────────────────────────────────────────────────────────

export function ProgramEditor({ program, onSave, onDelete }: ProgramEditorProps) {
  const [name, setName] = useState("");
  const [category, setCategory] = useState("");
  const [description, setDescription] = useState("");
  const [difficulty, setDifficulty] = useState("Beginner");
  const [sessionsPerWeek, setSessionsPerWeek] = useState(3);
  const [phases, setPhases] = useState<ProgramPhase[]>([]);
  const [phaseKeys, setPhaseKeys] = useState<string[]>([]);
  const [phaseKeyCounter, setPhaseKeyCounter] = useState(0);
  const [hasCycleAdjustments, setHasCycleAdjustments] = useState(false);
  const [errors, setErrors] = useState<ValidationError[]>([]);

  // Keep the original weeks so we can pass them through on save
  const [weeks, setWeeks] = useState<Program["weeks"]>([]);
  const [cycleAdjustmentProfile, setCycleAdjustmentProfile] = useState<
    Program["cycleAdjustmentProfile"] | undefined
  >(undefined);

  // Sync from prop
  useEffect(() => {
    if (program) {
      setName(program.name);
      setCategory(program.category);
      setDescription(program.description);
      setDifficulty(program.difficulty);
      setSessionsPerWeek(program.sessionsPerWeek);
      setPhases(program.phases);
      setWeeks(program.weeks);
      setCycleAdjustmentProfile(program.cycleAdjustmentProfile);
      setHasCycleAdjustments(!!program.cycleAdjustmentProfile);

      const keys = program.phases.map((_, i) => `phase-${i}`);
      setPhaseKeys(keys);
      setPhaseKeyCounter(program.phases.length);
      setErrors([]);
    }
  }, [program]);

  const id = useMemo(() => slugify(name), [name]);

  const durationWeeks = weeks.length;

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } })
  );

  const fieldError = useCallback(
    (field: string) => errors.find((e) => e.field === field)?.message,
    [errors]
  );

  // Build current program for validation
  const currentProgram = useMemo(
    (): Program => ({
      id,
      name,
      category,
      description,
      difficulty,
      durationWeeks,
      sessionsPerWeek,
      phases,
      weeks,
      cycleAdjustmentProfile: hasCycleAdjustments
        ? cycleAdjustmentProfile
        : undefined,
    }),
    [
      id,
      name,
      category,
      description,
      difficulty,
      durationWeeks,
      sessionsPerWeek,
      phases,
      weeks,
      hasCycleAdjustments,
      cycleAdjustmentProfile,
    ]
  );

  const hasValidationErrors = useMemo(
    () => validateProgram(currentProgram).length > 0,
    [currentProgram]
  );

  // ─── Phase handlers ──────────────────────────────────────────────────────

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = phaseKeys.indexOf(String(active.id));
    const newIndex = phaseKeys.indexOf(String(over.id));
    if (oldIndex === -1 || newIndex === -1) return;

    setPhases((prev) => arrayMove(prev, oldIndex, newIndex));
    setPhaseKeys((prev) => arrayMove(prev, oldIndex, newIndex));
  }

  function addPhase() {
    const newPhase: ProgramPhase = {
      id: "",
      name: "",
      goal: "",
      weekRange: [1, 1],
    };
    setPhases((prev) => [...prev, newPhase]);
    setPhaseKeys((prev) => [...prev, `phase-${phaseKeyCounter}`]);
    setPhaseKeyCounter((c) => c + 1);
  }

  function updatePhase(index: number, updated: ProgramPhase) {
    setPhases((prev) => prev.map((p, i) => (i === index ? updated : p)));
  }

  function deletePhase(index: number) {
    setPhases((prev) => prev.filter((_, i) => i !== index));
    setPhaseKeys((prev) => prev.filter((_, i) => i !== index));
  }

  // ─── Week handlers ─────────────────────────────────────────────────────

  function addWeek() {
    const newWeekNumber = weeks.length + 1;
    let sessionCounter = 0;
    const blankSession: ProgramSession = {
      sessionId: `session-${Date.now()}-${++sessionCounter}`,
      sessionName: "Session 1",
      sessionType: "Lift",
      focus: "",
      exercises: [],
    };
    const newWeek: ProgramWeek = {
      week: newWeekNumber,
      sessions: [blankSession],
    };
    setWeeks((prev) => [...prev, newWeek]);
  }

  function removeLastWeek() {
    if (weeks.length === 0) return;
    setWeeks((prev) => prev.slice(0, -1));
  }

  function updateWeek(index: number, updated: ProgramWeek) {
    setWeeks((prev) => prev.map((w, i) => (i === index ? updated : w)));
  }

  // ─── Save / Delete ───────────────────────────────────────────────────────

  function handleSave() {
    const programToSave = currentProgram;
    const validationErrors = validateProgram(programToSave);
    setErrors(validationErrors);
    if (validationErrors.length > 0) return;
    onSave(programToSave);
  }

  // ─── Placeholder ─────────────────────────────────────────────────────────

  if (!program) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40 text-lg">
        Select a program or create a new one
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full overflow-y-auto p-4">
      {/* ── Header Section ──────────────────────────────────────────────── */}
      <h2 className="text-lg font-bold text-navy mb-4">Program Details</h2>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Name
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Program name"
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
          {fieldError("name") && (
            <p className="text-red-500 text-xs mt-1">{fieldError("name")}</p>
          )}
          <p className="text-xs text-navy/40 mt-1">
            ID: <span className="font-mono">{id || "(auto-generated from name)"}</span>
          </p>
          {fieldError("id") && (
            <p className="text-red-500 text-xs mt-1">{fieldError("id")}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Category
          </label>
          <input
            type="text"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            placeholder="e.g. Strength, Hypertrophy"
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">
          Description
        </label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Brief description of the program..."
          rows={2}
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40 resize-y"
        />
      </div>

      <div className="grid grid-cols-3 gap-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Difficulty
          </label>
          <select
            value={difficulty}
            onChange={(e) => setDifficulty(e.target.value)}
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          >
            <option value="Beginner">Beginner</option>
            <option value="Intermediate">Intermediate</option>
            <option value="Advanced">Advanced</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Duration (weeks)
          </label>
          <input
            type="number"
            value={durationWeeks}
            readOnly
            className="w-full border border-navy/10 rounded px-3 py-1.5 text-sm bg-navy/5 text-navy/50"
          />
          {fieldError("durationWeeks") && (
            <p className="text-red-500 text-xs mt-1">
              {fieldError("durationWeeks")}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Sessions / Week
          </label>
          <input
            type="number"
            min={1}
            max={7}
            value={sessionsPerWeek}
            onChange={(e) =>
              setSessionsPerWeek(parseInt(e.target.value) || 1)
            }
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
        </div>
      </div>

      {/* ── Phases Section ──────────────────────────────────────────────── */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-sm font-bold text-navy">
            Phases ({phases.length})
          </h3>
          <button
            type="button"
            onClick={addPhase}
            className="text-sm text-orange hover:text-orange/80 font-medium"
          >
            + Add Phase
          </button>
        </div>

        {phases.length === 0 && (
          <p className="text-sm text-navy/40 py-2">
            No phases defined. Add a phase to organize weekly blocks.
          </p>
        )}

        <DndContext
          sensors={sensors}
          collisionDetection={closestCenter}
          onDragEnd={handleDragEnd}
        >
          <SortableContext
            items={phaseKeys}
            strategy={verticalListSortingStrategy}
          >
            {phases.map((phase, i) => (
              <SortablePhaseRow
                key={phaseKeys[i]}
                id={phaseKeys[i]}
                phase={phase}
                onChange={(updated) => updatePhase(i, updated)}
                onDelete={() => deletePhase(i)}
              />
            ))}
          </SortableContext>
        </DndContext>
      </div>

      {/* ── Weeks Section ──────────────────────────────────────────────── */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-sm font-bold text-navy">
            Weeks ({weeks.length})
          </h3>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={addWeek}
              className="text-sm text-orange hover:text-orange/80 font-medium"
            >
              + Add Week
            </button>
            <button
              type="button"
              onClick={removeLastWeek}
              disabled={weeks.length === 0}
              className="text-sm text-red-400 hover:text-red-600 font-medium disabled:opacity-30 disabled:cursor-not-allowed"
            >
              - Remove Last Week
            </button>
          </div>
        </div>

        {weeks.length === 0 ? (
          <p className="text-sm text-navy/40 py-2">
            No weeks defined yet. Click &quot;Add Week&quot; to get started.
          </p>
        ) : (
          weeks.map((week, i) => (
            <WeekEditor
              key={week.week}
              week={week}
              weekIndex={i}
              phases={phases}
              onChange={(updated) => updateWeek(i, updated)}
            />
          ))
        )}
      </div>

      {/* ── Cycle Adjustment Section (placeholder) ──────────────────────── */}
      <div className="mb-6">
        <h3 className="text-sm font-bold text-navy mb-2">
          Cycle Adjustments
        </h3>
        <label className="flex items-center gap-2 text-sm text-navy/70">
          <input
            type="checkbox"
            checked={hasCycleAdjustments}
            onChange={(e) => setHasCycleAdjustments(e.target.checked)}
            className="accent-navy"
          />
          Has Cycle Adjustments
        </label>
        {hasCycleAdjustments && (
          <p className="text-sm text-navy/40 mt-2 p-2 border border-navy/10 rounded bg-navy/5 italic">
            Cycle adjustment editor coming in a future task.
          </p>
        )}
      </div>

      {/* ── Actions ─────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-3 pt-4 border-t border-navy/10 mt-auto">
        <button
          type="button"
          onClick={handleSave}
          disabled={hasValidationErrors}
          className="bg-orange text-white px-4 py-2 rounded font-medium hover:bg-orange/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          Save
        </button>
        <button
          type="button"
          onClick={() => onDelete(program.id)}
          className="bg-red-500 text-white px-4 py-2 rounded font-medium hover:bg-red-600 transition-colors"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
