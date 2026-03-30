"use client";

import { useEffect, useState } from "react";
import { AdminHeader } from "@/components/admin/admin-header";
import { DataTable, Column } from "@/components/admin/data-table";
import { DetailPanel } from "@/components/admin/detail-panel";
import { EmptyState } from "@/components/admin/empty-state";
import { ConfirmDialog } from "@/components/admin/confirm-dialog";
import { Button } from "@/components/ui/button";

interface AiPrompt {
  id: string;
  name: string;
  description: string;
  promptText: string;
  modelConfig: {
    temperature: number;
    maxTokens: number;
  };
  updatedAt: string;
}

const INPUT_CLASS =
  "w-full bg-card-bg border border-separator rounded-sm px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-orange/40";

function newPrompt(): AiPrompt {
  return {
    id: "",
    name: "",
    description: "",
    promptText: "",
    modelConfig: { temperature: 0.7, maxTokens: 2048 },
    updatedAt: "",
  };
}

const columns: Column<AiPrompt>[] = [
  { key: "name", header: "Name", sortable: true },
  { key: "description", header: "Description" },
  {
    key: "updatedAt",
    header: "Updated At",
    render: (row) =>
      row.updatedAt ? new Date(row.updatedAt).toLocaleString() : "—",
    sortable: true,
  },
];

export default function AIPromptsPage() {
  const [prompts, setPrompts] = useState<AiPrompt[]>([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState<AiPrompt | null>(null);
  const [editing, setEditing] = useState<AiPrompt | null>(null);
  const [saving, setSaving] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  async function loadPrompts() {
    setLoading(true);
    try {
      const res = await fetch("/api/admin/ai/prompts");
      const data: AiPrompt[] = await res.json();
      setPrompts(Array.isArray(data) ? data : []);
    } catch {
      setPrompts([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadPrompts();
  }, []);

  function handleRowClick(row: AiPrompt) {
    setSelected(row);
    setEditing({ ...row });
  }

  function handleNew() {
    const p = newPrompt();
    setSelected(p);
    setEditing(p);
  }

  async function handleSave() {
    if (!editing) return;
    setSaving(true);
    try {
      let res: Response;
      if (editing.id) {
        res = await fetch(`/api/admin/ai/prompts/${editing.id}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(editing),
        });
      } else {
        const id = editing.name.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "") || Date.now().toString();
        res = await fetch("/api/admin/ai/prompts", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...editing, id }),
        });
      }
      if (res.ok) await loadPrompts();
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!selected?.id) return;
    await fetch(`/api/admin/ai/prompts/${selected.id}`, { method: "DELETE" });
    setSelected(null);
    setEditing(null);
    setConfirmDelete(false);
    await loadPrompts();
  }

  function updateEditing(patch: Partial<AiPrompt>) {
    setEditing((prev) => (prev ? { ...prev, ...patch } : prev));
  }

  function updateModelConfig(patch: Partial<AiPrompt["modelConfig"]>) {
    setEditing((prev) =>
      prev ? { ...prev, modelConfig: { ...prev.modelConfig, ...patch } } : prev
    );
  }

  const isValid = !!(editing?.id || editing?.name);

  return (
    <div className="flex flex-col h-screen">
      <AdminHeader
        title="AI Prompts"
        actions={
          <Button variant="primary" onClick={handleNew}>
            New Prompt
          </Button>
        }
      />
      <div className="flex flex-1 overflow-hidden">
        <div className={`flex flex-col overflow-hidden ${selected ? "w-1/2" : "flex-1"}`}>
          {loading ? (
            <p className="p-6 text-sm text-text-secondary">Loading...</p>
          ) : prompts.length === 0 ? (
            <EmptyState title="No prompts found." description="Create a new prompt to get started." />
          ) : (
            <DataTable
              columns={columns}
              data={prompts}
              rowKey={(row) => row.id}
              onRowClick={handleRowClick}
              selectedKey={selected?.id ?? null}
            />
          )}
        </div>

        {selected !== null && editing !== null && (
          <div className="w-1/2 overflow-hidden">
            <DetailPanel
              title={editing.id ? editing.name || "Edit Prompt" : "New Prompt"}
              onClose={() => {
                setSelected(null);
                setEditing(null);
              }}
              actions={
                <div className="flex gap-2">
                  {editing.id && (
                    <Button variant="destructive" onClick={() => setConfirmDelete(true)}>
                      Delete
                    </Button>
                  )}
                  <Button variant="primary" onClick={handleSave} disabled={!isValid || saving}>
                    {saving ? "Saving..." : "Save"}
                  </Button>
                </div>
              }
            >
              <div className="flex flex-col gap-4">
                <div>
                  <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                    Name
                  </label>
                  <input
                    type="text"
                    value={editing.name}
                    onChange={(e) => updateEditing({ name: e.target.value })}
                    className={INPUT_CLASS}
                    placeholder="Prompt name"
                  />
                </div>

                <div>
                  <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                    Description
                  </label>
                  <textarea
                    value={editing.description}
                    onChange={(e) => updateEditing({ description: e.target.value })}
                    className={INPUT_CLASS}
                    rows={2}
                    placeholder="Brief description"
                  />
                </div>

                <div>
                  <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                    Prompt Text
                  </label>
                  <textarea
                    value={editing.promptText}
                    onChange={(e) => updateEditing({ promptText: e.target.value })}
                    className={`${INPUT_CLASS} font-mono`}
                    rows={12}
                    placeholder="Enter prompt text..."
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                      Temperature
                    </label>
                    <input
                      type="number"
                      min={0}
                      max={1}
                      step={0.1}
                      value={editing.modelConfig.temperature}
                      onChange={(e) =>
                        updateModelConfig({ temperature: parseFloat(e.target.value) })
                      }
                      className={INPUT_CLASS}
                    />
                  </div>
                  <div>
                    <label className="font-mono text-[10px] tracking-widest uppercase text-text-secondary block mb-1">
                      Max Tokens
                    </label>
                    <input
                      type="number"
                      min={1}
                      value={editing.modelConfig.maxTokens}
                      onChange={(e) =>
                        updateModelConfig({ maxTokens: parseInt(e.target.value, 10) })
                      }
                      className={INPUT_CLASS}
                    />
                  </div>
                </div>
              </div>
            </DetailPanel>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={confirmDelete}
        title="Delete Prompt"
        message={`Are you sure you want to delete "${selected?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setConfirmDelete(false)}
      />
    </div>
  );
}
