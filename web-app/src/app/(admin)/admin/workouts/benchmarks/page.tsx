"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";
import type { BenchmarkDefinition } from "@/lib/domain/admin-types";
import { slugify } from "@/lib/domain/admin-types";

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

type ScoringTypeRaw = "time" | "reps" | "weight" | "distance" | "roundsAndReps";

interface BenchmarkDraft {
  id: string;
  name: string;
  category: string;
  workoutDescription: string;
  scoringTypeRaw: ScoringTypeRaw;
  sortOrder: number;
  isPredefined: boolean;
}

function newBenchmark(): BenchmarkDraft {
  return {
    id: "",
    name: "",
    category: "",
    workoutDescription: "",
    scoringTypeRaw: "time",
    sortOrder: 0,
    isPredefined: false,
  };
}

function toBenchmarkDraft(b: BenchmarkDefinition): BenchmarkDraft {
  return {
    id: b.id,
    name: b.name,
    category: b.category,
    workoutDescription: b.workoutDescription,
    scoringTypeRaw: b.scoringType as ScoringTypeRaw,
    sortOrder: b.sortOrder,
    isPredefined: b.isPredefined,
  };
}

function fromBenchmarkDraft(d: BenchmarkDraft): BenchmarkDefinition {
  return {
    id: d.id,
    name: d.name,
    category: d.category,
    workoutDescription: d.workoutDescription,
    scoringType: d.scoringTypeRaw,
    sortOrder: d.sortOrder,
    isPredefined: d.isPredefined,
  };
}

const SCORING_LABELS: Record<ScoringTypeRaw, string> = {
  time: "For Time",
  reps: "Max Reps",
  weight: "Max Weight",
  distance: "Distance",
  roundsAndReps: "Rounds + Reps",
};

export default function BenchmarksPage() {
  const [benchmarks, setBenchmarks] = useState<BenchmarkDefinition[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<BenchmarkDefinition | null>(null);
  const [draft, setDraft] = useState<BenchmarkDraft | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [isNew, setIsNew] = useState(false);

  useEffect(() => {
    fetch("/api/admin/benchmarks")
      .then((r) => r.json())
      .then((data) => setBenchmarks(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  function handleRowClick(b: BenchmarkDefinition) {
    setSelected(b);
    setDraft(toBenchmarkDraft(b));
    setIsNew(false);
  }

  function handleNew() {
    setSelected(null);
    setDraft(newBenchmark());
    setIsNew(true);
  }

  function handleClose() {
    setSelected(null);
    setDraft(null);
    setIsNew(false);
  }

  function updateDraft(field: Partial<BenchmarkDraft>) {
    setDraft((prev) => (prev ? { ...prev, ...field } : prev));
  }

  async function handleSave() {
    if (!draft) return;
    setSaving(true);
    try {
      const payload = fromBenchmarkDraft(draft);
      const id = isNew ? slugify(draft.name) : (selected?.id ?? draft.id);
      payload.id = id;
      const url = isNew ? "/api/admin/benchmarks" : `/api/admin/benchmarks/${id}`;
      const method = isNew ? "POST" : "PATCH";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("Save failed");
      const savedItem: BenchmarkDefinition = isNew ? { ...payload, id } : { ...payload };
      setBenchmarks((prev) =>
        isNew ? [savedItem, ...prev] : prev.map((b) => (b.id === id ? savedItem : b))
      );
      setSelected(savedItem);
      setDraft(toBenchmarkDraft(savedItem));
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
      await fetch(`/api/admin/benchmarks/${selected.id}`, { method: "DELETE" });
      setBenchmarks((prev) => prev.filter((b) => b.id !== selected.id));
      handleClose();
    } catch (e) {
      console.error(e);
    } finally {
      setDeleteOpen(false);
    }
  }

  const columns: Column<BenchmarkDefinition>[] = [
    { key: "name", header: "Name", sortable: true },
    { key: "category", header: "Category", sortable: true },
    {
      key: "scoringType",
      header: "Scoring Type",
      render: (row) => SCORING_LABELS[row.scoringType as ScoringTypeRaw] ?? row.scoringType,
    },
    { key: "sortOrder", header: "Sort Order", sortable: true },
  ];

  const panelTitle = isNew
    ? "New Benchmark"
    : selected
      ? selected.name || "Edit Benchmark"
      : "";

  return (
    <>
      <AdminHeader
        title="Benchmarks"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New Benchmark
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col ${draft ? "w-1/2" : "w-full"} overflow-hidden`}>
          {loading ? (
            <p className="p-6 text-text-secondary">Loading...</p>
          ) : benchmarks.length === 0 && !draft ? (
            <EmptyState
              title="No benchmarks yet"
              description="Create your first benchmark workout."
              actionLabel="New Benchmark"
              onAction={handleNew}
            />
          ) : (
            <DataTable
              columns={columns}
              data={benchmarks}
              rowKey={(b) => b.id}
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
              }
            >
              <div className="space-y-4">
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Name</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.name}
                    onChange={(e) => updateDraft({ name: e.target.value })}
                    placeholder="Benchmark name"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Category</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.category}
                    onChange={(e) => updateDraft({ category: e.target.value })}
                    placeholder="e.g. Classic WODs"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Workout Description
                  </label>
                  <textarea
                    className={INPUT_CLASS}
                    rows={6}
                    value={draft.workoutDescription}
                    onChange={(e) => updateDraft({ workoutDescription: e.target.value })}
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Scoring Type</label>
                  <select
                    className={INPUT_CLASS}
                    value={draft.scoringTypeRaw}
                    onChange={(e) =>
                      updateDraft({ scoringTypeRaw: e.target.value as ScoringTypeRaw })
                    }
                  >
                    <option value="time">For Time</option>
                    <option value="reps">Max Reps</option>
                    <option value="weight">Max Weight</option>
                    <option value="distance">Distance</option>
                    <option value="roundsAndReps">Rounds + Reps</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Sort Order</label>
                  <input
                    type="number"
                    className={INPUT_CLASS}
                    value={draft.sortOrder}
                    onChange={(e) => updateDraft({ sortOrder: Number(e.target.value) })}
                  />
                </div>
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete Benchmark"
        message={`Are you sure you want to delete "${selected?.name}"? This cannot be undone.`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}
