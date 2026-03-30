"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";
import type { WOD, ProgramExercise } from "@/lib/domain/admin-types";

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

function newWOD(): WOD {
  return {
    id: "",
    date: new Date().toISOString().slice(0, 10),
    title: "",
    description: "",
    exercises: [],
  };
}

interface ExerciseRowProps {
  ex: ProgramExercise;
  index: number;
  onChange: (index: number, updated: ProgramExercise) => void;
  onRemove: (index: number) => void;
}

function ExerciseRow({ ex, index, onChange, onRemove }: ExerciseRowProps) {
  function update(field: Partial<ProgramExercise>) {
    onChange(index, { ...ex, ...field });
  }

  const setsVal =
    ex.sets.type === "fixed"
      ? String(ex.sets.value)
      : ex.sets.type === "range"
        ? `${(ex.sets as { type: "range"; low: number; high: number }).low}-${(ex.sets as { type: "range"; low: number; high: number }).high}`
        : "";

  const repsVal =
    ex.reps.type === "fixed"
      ? String(ex.reps.value)
      : ex.reps.type === "range"
        ? `${(ex.reps as { type: "range"; low: number; high: number }).low}-${(ex.reps as { type: "range"; low: number; high: number }).high}`
        : ex.reps.type === "amrap"
          ? "AMRAP"
          : "";

  function parseExerciseValue(val: string): ProgramExercise["sets"] {
    if (val.toLowerCase() === "amrap") return { type: "amrap" };
    if (val.includes("-")) {
      const parts = val.split("-");
      if (parts.length === 2) {
        const low = Number(parts[0].trim());
        const high = Number(parts[1].trim());
        if (!isNaN(low) && !isNaN(high)) return { type: "range", low, high };
      }
    }
    const n = Number(val);
    if (!isNaN(n) && val.trim() !== "") return { type: "fixed", value: n };
    return { type: "text", value: val };
  }

  return (
    <div className="border border-separator rounded-sm p-3 mb-2 bg-navy/2">
      <div className="flex items-center justify-between mb-2">
        <span className="font-mono text-[11px] text-gold tracking-wider uppercase">
          Exercise {index + 1}
        </span>
        <button
          onClick={() => onRemove(index)}
          className="text-error text-xs hover:underline"
        >
          Remove
        </button>
      </div>
      <div className="grid grid-cols-2 gap-2">
        <div className="col-span-2">
          <label className="block text-xs text-text-secondary mb-1">Name</label>
          <input
            className={INPUT_CLASS}
            value={ex.exercise}
            onChange={(e) => update({ exercise: e.target.value })}
            placeholder="e.g. Back Squat"
          />
        </div>
        <div>
          <label className="block text-xs text-text-secondary mb-1">Sets</label>
          <input
            className={INPUT_CLASS}
            value={setsVal}
            onChange={(e) => update({ sets: parseExerciseValue(e.target.value) })}
            placeholder="3"
          />
        </div>
        <div>
          <label className="block text-xs text-text-secondary mb-1">Reps</label>
          <input
            className={INPUT_CLASS}
            value={repsVal}
            onChange={(e) => update({ reps: parseExerciseValue(e.target.value) })}
            placeholder="10 or 8-12 or AMRAP"
          />
        </div>
        <div>
          <label className="block text-xs text-text-secondary mb-1">% 1RM (0–1)</label>
          <input
            type="number"
            min={0}
            max={1}
            step={0.01}
            className={INPUT_CLASS}
            value={ex.percent1RM ?? ""}
            onChange={(e) =>
              update({ percent1RM: e.target.value ? Number(e.target.value) : undefined })
            }
          />
        </div>
        <div>
          <label className="block text-xs text-text-secondary mb-1">Rest (min)</label>
          <input
            type="number"
            min={0}
            step={0.5}
            className={INPUT_CLASS}
            value={ex.restMinutes ?? ""}
            onChange={(e) =>
              update({ restMinutes: e.target.value ? Number(e.target.value) : undefined })
            }
          />
        </div>
        <div className="col-span-2">
          <label className="block text-xs text-text-secondary mb-1">Notes</label>
          <input
            className={INPUT_CLASS}
            value={ex.notes ?? ""}
            onChange={(e) => update({ notes: e.target.value })}
          />
        </div>
        <div className="col-span-2 flex items-center gap-2">
          <input
            type="checkbox"
            id={`bw-${index}`}
            checked={ex.bodyweightOnly ?? false}
            onChange={(e) => update({ bodyweightOnly: e.target.checked })}
          />
          <label htmlFor={`bw-${index}`} className="text-xs text-text-secondary">
            Bodyweight only
          </label>
        </div>
      </div>
    </div>
  );
}

export default function WODsPage() {
  const [wods, setWods] = useState<WOD[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<WOD | null>(null);
  const [draft, setDraft] = useState<WOD | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [isNew, setIsNew] = useState(false);

  useEffect(() => {
    fetch("/api/admin/wods")
      .then((r) => r.json())
      .then((data) => setWods(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  function handleRowClick(wod: WOD) {
    setSelected(wod);
    setDraft({ ...wod, exercises: wod.exercises ? [...wod.exercises] : [] });
    setIsNew(false);
  }

  function handleNew() {
    const w = newWOD();
    setSelected(null);
    setDraft(w);
    setIsNew(true);
  }

  function handleClose() {
    setSelected(null);
    setDraft(null);
    setIsNew(false);
  }

  function updateDraft(field: Partial<WOD>) {
    setDraft((prev) => (prev ? { ...prev, ...field } : prev));
  }

  function addExercise() {
    setDraft((prev) =>
      prev ? { ...prev, exercises: [...(prev.exercises ?? []), newExercise()] } : prev
    );
  }

  function updateExercise(index: number, updated: ProgramExercise) {
    setDraft((prev) => {
      if (!prev) return prev;
      const exercises = [...(prev.exercises ?? [])];
      exercises[index] = updated;
      return { ...prev, exercises };
    });
  }

  function removeExercise(index: number) {
    setDraft((prev) => {
      if (!prev) return prev;
      const exercises = (prev.exercises ?? []).filter((_, i) => i !== index);
      return { ...prev, exercises };
    });
  }

  async function handleSave() {
    if (!draft) return;
    setSaving(true);
    try {
      const id = isNew ? `wod-${draft.date}` : (selected?.id ?? draft.id);
      const payload = { ...draft, id };
      const url = isNew ? "/api/admin/wods" : `/api/admin/wods/${id}`;
      const method = isNew ? "POST" : "PATCH";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("Save failed");
      const saved: WOD = await res.json();
      setWods((prev) =>
        isNew ? [saved, ...prev] : prev.map((w) => (w.id === saved.id ? saved : w))
      );
      setSelected(saved);
      setDraft({ ...saved });
      setIsNew(false);
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!selected) return;
    try {
      await fetch(`/api/admin/wods/${selected.id}`, { method: "DELETE" });
      setWods((prev) => prev.filter((w) => w.id !== selected.id));
      handleClose();
    } catch (e) {
      console.error(e);
    } finally {
      setDeleteOpen(false);
    }
  }

  const columns: Column<WOD>[] = [
    { key: "date", header: "Date", sortable: true },
    { key: "title", header: "Title" },
    {
      key: "exercises",
      header: "Exercises",
      render: (row) => String(row.exercises?.length ?? 0),
    },
  ];

  const panelTitle = isNew ? "New WOD" : selected ? selected.title || "Edit WOD" : "";

  return (
    <>
      <AdminHeader
        title="WODs"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New WOD
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col ${draft ? "w-1/2" : "w-full"} overflow-hidden`}>
          {loading ? (
            <p className="p-6 text-text-secondary">Loading...</p>
          ) : wods.length === 0 && !draft ? (
            <EmptyState
              title="No WODs yet"
              description="Create your first workout of the day."
              actionLabel="New WOD"
              onAction={handleNew}
            />
          ) : (
            <DataTable
              columns={columns}
              data={wods}
              rowKey={(w) => w.id}
              onRowClick={handleRowClick}
              selectedKey={selected?.id ?? null}
              searchFn={(row, q) =>
                row.title.toLowerCase().includes(q) || row.date.includes(q)
              }
              searchPlaceholder="Search by title or date..."
            />
          )}
        </div>

        {draft && (
          <div className="w-1/2 overflow-hidden">
            <DetailPanel
              title={panelTitle}
              onClose={handleClose}
              actions={
                <div className="flex gap-2">
                  {!isNew && selected && (
                    <Button
                      variant="destructive"
                      onClick={() => setDeleteOpen(true)}
                    >
                      Delete
                    </Button>
                  )}
                  <Button variant="primary" onClick={handleSave} disabled={saving}>
                    {saving ? "Saving..." : "Save"}
                  </Button>
                </div>
              }
            >
              <div className="space-y-4">
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Date</label>
                  <input
                    type="date"
                    className={INPUT_CLASS}
                    value={draft.date}
                    onChange={(e) => updateDraft({ date: e.target.value })}
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Title</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.title}
                    onChange={(e) => updateDraft({ title: e.target.value })}
                    placeholder="WOD title"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Description
                  </label>
                  <textarea
                    className={INPUT_CLASS}
                    rows={3}
                    value={draft.description ?? ""}
                    onChange={(e) => updateDraft({ description: e.target.value })}
                  />
                </div>
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <p className="font-mono text-[11px] tracking-wider uppercase text-gold">
                      Exercises
                    </p>
                    <button
                      onClick={addExercise}
                      className="text-orange text-xs hover:underline"
                    >
                      + Add Exercise
                    </button>
                  </div>
                  {(draft.exercises ?? []).length === 0 ? (
                    <p className="text-xs text-text-secondary">No exercises yet.</p>
                  ) : (
                    (draft.exercises ?? []).map((ex, i) => (
                      <ExerciseRow
                        key={i}
                        ex={ex}
                        index={i}
                        onChange={updateExercise}
                        onRemove={removeExercise}
                      />
                    ))
                  )}
                </div>
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete WOD"
        message={`Are you sure you want to delete "${selected?.title}"? This cannot be undone.`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}
