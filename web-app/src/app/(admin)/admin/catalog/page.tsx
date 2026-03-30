"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";
import type { CatalogExercise } from "@/lib/domain/admin-types";
import { slugify } from "@/lib/domain/admin-types";

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

function newExercise(): CatalogExercise {
  return {
    id: "",
    name: "",
    category: "",
    subcategory: "",
    scoring: "",
  };
}

export default function CatalogPage() {
  const [exercises, setExercises] = useState<CatalogExercise[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<CatalogExercise | null>(null);
  const [draft, setDraft] = useState<CatalogExercise | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [isNew, setIsNew] = useState(false);

  useEffect(() => {
    fetch("/api/admin/catalog")
      .then((r) => r.json())
      .then((data) => setExercises(Array.isArray(data) ? data : []))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  function handleRowClick(ex: CatalogExercise) {
    setSelected(ex);
    setDraft({ ...ex });
    setIsNew(false);
  }

  function handleNew() {
    setSelected(null);
    setDraft(newExercise());
    setIsNew(true);
  }

  function handleClose() {
    setSelected(null);
    setDraft(null);
    setIsNew(false);
  }

  function updateDraft(field: Partial<CatalogExercise>) {
    setDraft((prev) => (prev ? { ...prev, ...field } : prev));
  }

  async function handleSave() {
    if (!draft) return;
    setSaving(true);
    try {
      const id = isNew ? slugify(draft.name) : (selected?.id ?? draft.id);
      const payload: CatalogExercise = { ...draft, id };
      const url = isNew ? "/api/admin/catalog" : `/api/admin/catalog/${id}`;
      const method = isNew ? "POST" : "PATCH";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("Save failed");
      const savedItem: CatalogExercise = isNew ? { ...draft, id } : { ...draft };
      setExercises((prev) =>
        isNew ? [savedItem, ...prev] : prev.map((e) => (e.id === id ? savedItem : e))
      );
      setSelected(savedItem);
      setDraft({ ...savedItem });
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
      await fetch(`/api/admin/catalog/${selected.id}`, { method: "DELETE" });
      setExercises((prev) => prev.filter((e) => e.id !== selected.id));
      handleClose();
    } catch (e) {
      console.error(e);
    } finally {
      setDeleteOpen(false);
    }
  }

  const columns: Column<CatalogExercise>[] = [
    { key: "name", header: "Name", sortable: true },
    { key: "category", header: "Category", sortable: true },
    { key: "subcategory", header: "Subcategory" },
    { key: "scoring", header: "Scoring" },
  ];

  const panelTitle = isNew
    ? "New Exercise"
    : selected
      ? selected.name || "Edit Exercise"
      : "";

  return (
    <>
      <AdminHeader
        title="Exercise Catalog"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New Exercise
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col ${draft ? "w-1/2" : "w-full"} overflow-hidden`}>
          {loading ? (
            <p className="p-6 text-text-secondary">Loading...</p>
          ) : exercises.length === 0 && !draft ? (
            <EmptyState
              title="No exercises yet"
              description="Add your first exercise to the catalog."
              actionLabel="New Exercise"
              onAction={handleNew}
            />
          ) : (
            <DataTable
              columns={columns}
              data={exercises}
              rowKey={(e) => e.id}
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
                    placeholder="Exercise name"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">Category</label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.category}
                    onChange={(e) => updateDraft({ category: e.target.value })}
                    placeholder="e.g. Barbell, Bodyweight"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Subcategory{" "}
                    <span className="text-text-secondary/60">(optional)</span>
                  </label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.subcategory ?? ""}
                    onChange={(e) => updateDraft({ subcategory: e.target.value || undefined })}
                    placeholder="e.g. Lower Body, Push"
                  />
                </div>
                <div>
                  <label className="block text-xs text-text-secondary mb-1">
                    Scoring{" "}
                    <span className="text-text-secondary/60">(optional)</span>
                  </label>
                  <input
                    className={INPUT_CLASS}
                    value={draft.scoring ?? ""}
                    onChange={(e) => updateDraft({ scoring: e.target.value || undefined })}
                    placeholder="e.g. weight, reps, time"
                  />
                </div>
                {isNew && (
                  <div className="bg-navy/5 rounded-sm px-3 py-2 text-xs text-text-secondary">
                    ID will be auto-generated:{" "}
                    <span className="font-mono text-navy">
                      {slugify(draft.name) || "..."}
                    </span>
                  </div>
                )}
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={deleteOpen}
        title="Delete Exercise"
        message={`Are you sure you want to delete "${selected?.name}"? This cannot be undone.`}
        onConfirm={handleDelete}
        onCancel={() => setDeleteOpen(false)}
      />
    </>
  );
}
