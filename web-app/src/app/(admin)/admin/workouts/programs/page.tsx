"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";
import type {
  Program,
  ProgramPhase,
  ProgramWeek,
  ProgramSession,
  ProgramExercise,
} from "@/lib/domain/admin-types";
import { slugify } from "@/lib/domain/admin-types";

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

function newExercise(): ProgramExercise {
  return {
    exercise: "",
    sets: { type: "fixed", value: 3 },
    reps: { type: "fixed", value: 10 },
    percent1RM: undefined,
    restMinutes: undefined,
    notes: "",
    bodyweightOnly: false,
  };
}

function newSession(weekIndex: number, sessionIndex: number): ProgramSession {
  return {
    sessionId: `w${weekIndex + 1}-s${sessionIndex + 1}`,
    sessionName: "",
    sessionType: "",
    focus: "",
    exercises: [],
  };
}

function newWeek(weekNumber: number): ProgramWeek {
  return {
    week: weekNumber,
    sessions: [],
  };
}

function newProgram(): Program {
  return {
    id: "",
    name: "",
    category: "",
    description: "",
    durationWeeks: 4,
    sessionsPerWeek: 3,
    difficulty: "Intermediate",
    phases: [],
    weeks: [],
    status: "draft",
  };
}

function parseExerciseValue(val: string): ProgramExercise["sets"] {
  if (val.toLowerCase() === "amrap") return { type: "amrap" };
  if (val.includes("-")) {
    const parts = val.split("-");
    if (parts.length === 2) {
      const lo = parseInt(parts[0].trim(), 10);
      const hi = parseInt(parts[1].trim(), 10);
      if (!isNaN(lo) && !isNaN(hi)) return { type: "range", low: lo, high: hi };
    }
  }
  const n = Number(val);
  if (!isNaN(n) && val.trim() !== "") return { type: "fixed", value: n };
  return { type: "text", value: val };
}

function exerciseValueDisplay(ev: ProgramExercise["sets"]): string {
  if (ev.type === "fixed") return String(ev.value);
  if (ev.type === "amrap") return "AMRAP";
  if (ev.type === "range") return `${ev.low}-${ev.high}`;
  if (ev.type === "text") return ev.value;
  return "";
}

interface ExerciseRowProps {
  ex: ProgramExercise;
  onChange: (updated: ProgramExercise) => void;
  onRemove: () => void;
  label: string;
}

function ExerciseRow({ ex, onChange, onRemove, label }: ExerciseRowProps) {
  return (
    <div className="border border-separator/60 rounded-sm p-2 mb-2 bg-navy/2">
      <div className="flex items-center justify-between mb-1">
        <span className="text-[10px] text-gold font-mono uppercase tracking-wider">{label}</span>
        <button onClick={onRemove} className="text-error text-xs hover:underline">
          Remove
        </button>
      </div>
      <div className="grid grid-cols-2 gap-1.5">
        <div className="col-span-2">
          <input
            className={INPUT_CLASS}
            value={ex.exercise}
            onChange={(e) => onChange({ ...ex, exercise: e.target.value })}
            placeholder="Exercise name"
          />
        </div>
        <input
          className={INPUT_CLASS}
          value={exerciseValueDisplay(ex.sets)}
          onChange={(e) => onChange({ ...ex, sets: parseExerciseValue(e.target.value) })}
          placeholder="Sets (e.g. 3)"
        />
        <input
          className={INPUT_CLASS}
          value={exerciseValueDisplay(ex.reps)}
          onChange={(e) => onChange({ ...ex, reps: parseExerciseValue(e.target.value) })}
          placeholder="Reps (e.g. 8-12)"
        />
        <input
          type="number"
          min={0}
          max={1}
          step={0.01}
          className={INPUT_CLASS}
          value={ex.percent1RM ?? ""}
          onChange={(e) =>
            onChange({ ...ex, percent1RM: e.target.value ? Number(e.target.value) : undefined })
          }
          placeholder="% 1RM (0-1)"
        />
        <input
          type="number"
          min={0}
          step={0.5}
          className={INPUT_CLASS}
          value={ex.restMinutes ?? ""}
          onChange={(e) =>
            onChange({ ...ex, restMinutes: e.target.value ? Number(e.target.value) : undefined })
          }
          placeholder="Rest min"
        />
        <div className="col-span-2">
          <input
            className={INPUT_CLASS}
            value={ex.notes ?? ""}
            onChange={(e) => onChange({ ...ex, notes: e.target.value })}
            placeholder="Notes"
          />
        </div>
        <div className="col-span-2 flex items-center gap-2">
          <input
            type="checkbox"
            checked={ex.bodyweightOnly ?? false}
            onChange={(e) => onChange({ ...ex, bodyweightOnly: e.target.checked })}
          />
          <span className="text-xs text-text-secondary">Bodyweight only</span>
        </div>
      </div>
    </div>
  );
}

interface SessionEditorProps {
  session: ProgramSession;
  sessionIndex: number;
  onChange: (updated: ProgramSession) => void;
  onRemove: () => void;
}

function SessionEditor({
  session,
  sessionIndex,
  onChange,
  onRemove,
}: SessionEditorProps) {
  function addExercise() {
    onChange({ ...session, exercises: [...session.exercises, newExercise()] });
  }

  function updateExercise(i: number, updated: ProgramExercise) {
    const exercises = [...session.exercises];
    exercises[i] = updated;
    onChange({ ...session, exercises });
  }

  function removeExercise(i: number) {
    onChange({ ...session, exercises: session.exercises.filter((_, idx) => idx !== i) });
  }

  return (
    <div className="border border-separator rounded-sm p-3 mb-2">
      <div className="flex items-center justify-between mb-2">
        <span className="font-mono text-[11px] text-orange uppercase tracking-wider">
          Session {sessionIndex + 1}
        </span>
        <button onClick={onRemove} className="text-error text-xs hover:underline">
          Remove Session
        </button>
      </div>
      <div className="space-y-1.5 mb-3">
        <input
          className={INPUT_CLASS}
          value={session.sessionName}
          onChange={(e) => onChange({ ...session, sessionName: e.target.value })}
          placeholder="Session name"
        />
        <input
          className={INPUT_CLASS}
          value={session.sessionType}
          onChange={(e) => onChange({ ...session, sessionType: e.target.value })}
          placeholder="Session type"
        />
        <input
          className={INPUT_CLASS}
          value={session.focus}
          onChange={(e) => onChange({ ...session, focus: e.target.value })}
          placeholder="Focus"
        />
      </div>
      <div>
        <div className="flex items-center justify-between mb-1">
          <span className="text-[10px] font-mono text-gold uppercase tracking-wider">Exercises</span>
          <button onClick={addExercise} className="text-orange text-xs hover:underline">
            + Add Exercise
          </button>
        </div>
        {session.exercises.map((ex, i) => (
          <ExerciseRow
            key={i}
            ex={ex}
            label={`Ex ${i + 1}`}
            onChange={(updated) => updateExercise(i, updated)}
            onRemove={() => removeExercise(i)}
          />
        ))}
      </div>
    </div>
  );
}

export default function ProgramsPage() {
  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<Program | null>(null);
  const [draft, setDraft] = useState<Program | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [isNew, setIsNew] = useState(false);

  useEffect(() => {
    fetch("/api/admin/programs")
      .then((r) => r.json())
      .then((data) => setPrograms(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  function handleRowClick(p: Program) {
    setSelected(p);
    setDraft(JSON.parse(JSON.stringify(p)));
    setIsNew(false);
  }

  function handleNew() {
    setSelected(null);
    setDraft(newProgram());
    setIsNew(true);
  }

  function handleClose() {
    setSelected(null);
    setDraft(null);
    setIsNew(false);
  }

  function updateDraft(field: Partial<Program>) {
    setDraft((prev) => (prev ? { ...prev, ...field } : prev));
  }

  // Phase helpers
  function addPhase() {
    setDraft((prev) => {
      if (!prev) return prev;
      const phase: ProgramPhase = {
        id: `phase-${prev.phases.length + 1}`,
        name: "",
        goal: "",
        weekRange: [],
      };
      return { ...prev, phases: [...prev.phases, phase] };
    });
  }

  function updatePhase(i: number, updated: ProgramPhase) {
    setDraft((prev) => {
      if (!prev) return prev;
      const phases = [...prev.phases];
      phases[i] = updated;
      return { ...prev, phases };
    });
  }

  function removePhase(i: number) {
    setDraft((prev) => {
      if (!prev) return prev;
      return { ...prev, phases: prev.phases.filter((_, idx) => idx !== i) };
    });
  }

  // Week helpers
  function addWeek() {
    setDraft((prev) => {
      if (!prev) return prev;
      return { ...prev, weeks: [...prev.weeks, newWeek(prev.weeks.length + 1)] };
    });
  }

  function removeLastWeek() {
    setDraft((prev) => {
      if (!prev || prev.weeks.length === 0) return prev;
      return { ...prev, weeks: prev.weeks.slice(0, -1) };
    });
  }

  function addSessionToWeek(weekIndex: number) {
    setDraft((prev) => {
      if (!prev) return prev;
      const weeks = [...prev.weeks];
      const week = { ...weeks[weekIndex] };
      week.sessions = [...week.sessions, newSession(weekIndex, week.sessions.length)];
      weeks[weekIndex] = week;
      return { ...prev, weeks };
    });
  }

  function updateSession(weekIndex: number, sessionIndex: number, updated: ProgramSession) {
    setDraft((prev) => {
      if (!prev) return prev;
      const weeks = [...prev.weeks];
      const week = { ...weeks[weekIndex] };
      const sessions = [...week.sessions];
      sessions[sessionIndex] = updated;
      week.sessions = sessions;
      weeks[weekIndex] = week;
      return { ...prev, weeks };
    });
  }

  function removeSession(weekIndex: number, sessionIndex: number) {
    setDraft((prev) => {
      if (!prev) return prev;
      const weeks = [...prev.weeks];
      const week = { ...weeks[weekIndex] };
      week.sessions = week.sessions.filter((_, i) => i !== sessionIndex);
      weeks[weekIndex] = week;
      return { ...prev, weeks };
    });
  }

  async function handleSave() {
    if (!draft) return;
    if (!draft.name.trim()) {
      setSaveError("Program name is required");
      return;
    }
    setSaveError(null);
    setSaving(true);
    try {
      const id = isNew ? slugify(draft.name) : (selected?.id ?? draft.id);
      const payload = { ...draft, id };
      const url = isNew ? "/api/admin/programs" : `/api/admin/programs/${id}`;
      const method = isNew ? "POST" : "PATCH";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.error || "Save failed");
      }
      const savedItem: Program = isNew ? { ...draft, id } : { ...draft };
      setPrograms((prev) =>
        isNew ? [savedItem, ...prev] : prev.map((p) => (p.id === id ? savedItem : p))
      );
      setSelected(savedItem);
      setDraft(JSON.parse(JSON.stringify(savedItem)));
      setIsNew(false);
    } catch (e) {
      console.error(e);
      setSaveError((e as Error).message || "Failed to save. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!selected) return;
    try {
      await fetch(`/api/admin/programs/${selected.id}`, { method: "DELETE" });
      setPrograms((prev) => prev.filter((p) => p.id !== selected.id));
      handleClose();
    } catch (e) {
      console.error(e);
    } finally {
      setDeleteOpen(false);
    }
  }

  const columns: Column<Program>[] = [
    { key: "name", header: "Name", sortable: true },
    { key: "category", header: "Category" },
    { key: "durationWeeks", header: "Duration (wks)" },
    { key: "difficulty", header: "Difficulty" },
    {
      key: "status",
      header: "Status",
      render: (p) => (
        <span
          className={`text-[10px] px-2 py-0.5 rounded-full font-mono tracking-wider uppercase ${
            p.status === "published"
              ? "bg-green-500/10 text-green-500 border border-green-500/20"
              : "bg-text-secondary/10 text-text-secondary border border-text-secondary/20"
          }`}
        >
          {p.status || "draft"}
        </span>
      ),
    },
  ];

  const panelTitle = isNew ? "New Program" : selected ? selected.name || "Edit Program" : "";

  return (
    <>
      <AdminHeader
        title="Programs"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New Program
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col ${draft ? "w-1/2" : "w-full"} overflow-hidden`}>
          {loading ? (
            <p className="p-6 text-text-secondary">Loading...</p>
          ) : programs.length === 0 && !draft ? (
            <EmptyState
              title="No programs yet"
              description="Create your first training program."
              actionLabel="New Program"
              onAction={handleNew}
            />
          ) : (
            <DataTable
              columns={columns}
              data={programs}
              rowKey={(p) => p.id}
              onRowClick={handleRowClick}
              selectedKey={selected?.id ?? null}
              searchFn={(row, q) => row.name.toLowerCase().includes(q)}
              searchPlaceholder="Search by name..."
            />
          )}
        </div>

        {draft && (
          <div className="w-1/2 overflow-hidden">
            <DetailPanel
              title={panelTitle}
              onClose={handleClose}
              actions={
                <div className="flex flex-col items-end gap-1">
                  <div className="flex gap-2">
                    {!isNew && selected && (
                      <Button variant="destructive" onClick={() => setDeleteOpen(true)}>
                        Delete
                      </Button>
                    )}
                    <Button variant="primary" onClick={handleSave} disabled={saving}>
                      {saving ? "Saving..." : "Save"}
                    </Button>
                  </div>
                  {saveError && <p className="text-error text-sm">{saveError}</p>}
                </div>
              }
            >
              <div className="space-y-4">
                {/* Basic Info */}
                <section>
                  <div className="flex items-center justify-between mb-2">
                    <p className="font-mono text-[11px] tracking-wider uppercase text-gold">
                      Basic Info
                    </p>
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono uppercase text-text-secondary">
                        {draft.status || "draft"}
                      </span>
                      <button
                        onClick={() =>
                          updateDraft({
                            status: draft.status === "published" ? "draft" : "published",
                          })
                        }
                        className={`text-[10px] px-2 py-0.5 rounded-full font-mono tracking-wider uppercase border transition-colors ${
                          draft.status === "published"
                            ? "border-error text-error hover:bg-error/10"
                            : "border-green-500 text-green-500 hover:bg-green-500/10"
                        }`}
                      >
                        {draft.status === "published" ? "Unpublish" : "Publish"}
                      </button>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <div>
                      <label className="block text-xs text-text-secondary mb-1">Name</label>
                      <input
                        className={INPUT_CLASS}
                        value={draft.name}
                        onChange={(e) => updateDraft({ name: e.target.value })}
                        placeholder="Program name"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-text-secondary mb-1">Category</label>
                      <input
                        className={INPUT_CLASS}
                        value={draft.category}
                        onChange={(e) => updateDraft({ category: e.target.value })}
                        placeholder="e.g. Strength"
                      />
                    </div>
                    <div>
                      <label className="block text-xs text-text-secondary mb-1">Description</label>
                      <textarea
                        className={INPUT_CLASS}
                        rows={3}
                        value={draft.description}
                        onChange={(e) => updateDraft({ description: e.target.value })}
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="block text-xs text-text-secondary mb-1">Difficulty</label>
                        <select
                          className={INPUT_CLASS}
                          value={draft.difficulty}
                          onChange={(e) => updateDraft({ difficulty: e.target.value })}
                        >
                          <option value="Beginner">Beginner</option>
                          <option value="Intermediate">Intermediate</option>
                          <option value="Advanced">Advanced</option>
                        </select>
                      </div>
                      <div>
                        <label className="block text-xs text-text-secondary mb-1">Duration (weeks)</label>
                        <input
                          type="number"
                          min={1}
                          className={INPUT_CLASS}
                          value={draft.durationWeeks}
                          onChange={(e) => updateDraft({ durationWeeks: Number(e.target.value) })}
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-xs text-text-secondary mb-1">Sessions/Week</label>
                      <input
                        type="number"
                        min={1}
                        className={INPUT_CLASS}
                        value={draft.sessionsPerWeek}
                        onChange={(e) => updateDraft({ sessionsPerWeek: Number(e.target.value) })}
                      />
                    </div>
                  </div>
                </section>

                {/* Phases */}
                <section>
                  <div className="flex items-center justify-between mb-2">
                    <p className="font-mono text-[11px] tracking-wider uppercase text-gold">Phases</p>
                    <button onClick={addPhase} className="text-orange text-xs hover:underline">
                      + Add Phase
                    </button>
                  </div>
                  {draft.phases.length === 0 ? (
                    <p className="text-xs text-text-secondary">No phases defined.</p>
                  ) : (
                    draft.phases.map((phase, i) => (
                      <div
                        key={i}
                        className="border border-separator rounded-sm p-2 mb-2 space-y-1.5"
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-[10px] font-mono text-gold uppercase">
                            Phase {i + 1}
                          </span>
                          <button
                            onClick={() => removePhase(i)}
                            className="text-error text-xs hover:underline"
                          >
                            Remove
                          </button>
                        </div>
                        <input
                          className={INPUT_CLASS}
                          value={phase.name}
                          onChange={(e) => updatePhase(i, { ...phase, name: e.target.value })}
                          placeholder="Phase name"
                        />
                        <input
                          className={INPUT_CLASS}
                          value={phase.goal}
                          onChange={(e) => updatePhase(i, { ...phase, goal: e.target.value })}
                          placeholder="Goal"
                        />
                      </div>
                    ))
                  )}
                </section>

                {/* Weeks */}
                <section>
                  <div className="flex items-center justify-between mb-2">
                    <p className="font-mono text-[11px] tracking-wider uppercase text-gold">Weeks</p>
                    <div className="flex gap-2">
                      <button onClick={addWeek} className="text-orange text-xs hover:underline">
                        + Add Week
                      </button>
                      {draft.weeks.length > 0 && (
                        <button
                          onClick={removeLastWeek}
                          className="text-error text-xs hover:underline"
                        >
                          Remove Last
                        </button>
                      )}
                    </div>
                  </div>
                  {draft.weeks.length === 0 ? (
                    <p className="text-xs text-text-secondary">No weeks defined.</p>
                  ) : (
                    draft.weeks.map((week, wi) => (
                      <div
                        key={wi}
                        className="border border-orange/20 rounded-sm p-3 mb-3"
                      >
                        <div className="flex items-center justify-between mb-2">
                          <span className="font-mono text-[11px] text-orange uppercase tracking-wider">
                            Week {week.week}
                          </span>
                          <button
                            onClick={() => addSessionToWeek(wi)}
                            className="text-orange text-xs hover:underline"
                          >
                            + Add Session
                          </button>
                        </div>
                        {week.sessions.length === 0 ? (
                          <p className="text-xs text-text-secondary">No sessions yet.</p>
                        ) : (
                          week.sessions.map((session, si) => (
                            <SessionEditor
                              key={si}
                              session={session}
                              sessionIndex={si}
                              onChange={(updated) => updateSession(wi, si, updated)}
                              onRemove={() => removeSession(wi, si)}
                            />
                          ))
                        )}
                      </div>
                    ))
                  )}
                </section>
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete Program"
        message={`Are you sure you want to delete "${selected?.name}"? This cannot be undone.`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}
