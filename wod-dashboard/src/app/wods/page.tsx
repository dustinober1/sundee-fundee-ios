"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { WODList, type WODListItem } from "@/components/wod-list";
import { WODEditor } from "@/components/wod-editor";
import { WODGenerator } from "@/components/wod-generator";
import { useToast } from "@/components/toast";
import type { WOD, ProgramExerciseJSON } from "@/lib/types";
import { exerciseFromJSON, exerciseToJSON } from "@/lib/types";
import { saveWODRecord } from "@/lib/cloudkit";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function todayString(): string {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

function blankWOD(): WOD {
  return {
    id: `wod-${todayString()}`,
    date: todayString(),
    title: "",
    description: "",
    exercises: [],
  };
}

/** Decode raw JSON exercises into typed ProgramExercise objects. */
function decodeWOD(raw: any): WOD {
  return {
    id: raw.id,
    date: raw.date,
    title: raw.title,
    description: raw.description ?? "",
    exercises: (raw.exercises ?? []).map((ex: ProgramExerciseJSON) =>
      exerciseFromJSON(ex)
    ),
  };
}

/** Encode typed WOD back to JSON-safe shape for the API. */
function encodeWOD(wod: WOD): any {
  return {
    id: wod.id,
    date: wod.date,
    title: wod.title,
    description: wod.description,
    exercises: wod.exercises.map(exerciseToJSON),
  };
}

// ─── Page ────────────────────────────────────────────────────────────────────

interface PublishStatus {
  wods: Record<string, { publishedAt: string }>;
  programs: Record<string, { publishedAt: string }>;
}

export default function WODsPage() {
  const { toast } = useToast();
  const [wods, setWods] = useState<WOD[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showGenerator, setShowGenerator] = useState(false);
  const [publishStatus, setPublishStatus] = useState<PublishStatus>({ wods: {}, programs: {} });
  const [batchPublishing, setBatchPublishing] = useState(false);

  // Fetch publish status
  const fetchPublishStatus = useCallback(async () => {
    try {
      const res = await fetch("/api/cloudkit/publish");
      if (res.ok) {
        setPublishStatus(await res.json());
      }
    } catch {
      // Non-critical — ignore
    }
  }, []);

  // Fetch WODs
  const fetchWODs = useCallback(async () => {
    try {
      const res = await fetch("/api/wods");
      if (!res.ok) throw new Error("Failed to fetch WODs");
      const raw = await res.json();
      setWods(Array.isArray(raw) ? raw.map(decodeWOD) : []);
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchWODs();
    fetchPublishStatus();
  }, [fetchWODs, fetchPublishStatus]);

  // Derived data
  const selectedWOD = useMemo(
    () => wods.find((w) => w.id === selectedId) ?? null,
    [wods, selectedId]
  );

  const listItems: WODListItem[] = useMemo(
    () =>
      wods.map((w) => ({
        id: w.id,
        date: w.date,
        title: w.title,
        exerciseCount: w.exercises.length,
        published: w.id in publishStatus.wods,
      })),
    [wods, publishStatus]
  );

  const existingDates = useMemo(() => wods.map((w) => w.date), [wods]);

  // Handlers
  function handleNew() {
    const newWOD = blankWOD();
    // If this ID doesn't already exist in the list, add it temporarily
    setWods((prev) => {
      if (prev.some((w) => w.id === newWOD.id)) return prev;
      return [...prev, newWOD];
    });
    setSelectedId(newWOD.id);
  }

  async function handleSave(wod: WOD) {
    setSaving(true);
    try {
      const res = await fetch("/api/wods", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(encodeWOD(wod)),
      });
      if (!res.ok) throw new Error("Failed to save WOD");
      toast("WOD saved", "success");
      await fetchWODs();
      setSelectedId(wod.id);
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string) {
    try {
      const res = await fetch(`/api/wods?id=${encodeURIComponent(id)}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("Failed to delete WOD");
      toast("WOD deleted", "success");
      setSelectedId(null);
      await fetchWODs();
    } catch (e) {
      toast(String(e), "error");
    }
  }

  function handleToggleSelect(id: string) {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }

  async function publishSingleWOD(id: string) {
    const wod = wods.find((w) => w.id === id);
    if (!wod) return;
    try {

      await saveWODRecord(wod);
      // Mark as published server-side
      await fetch("/api/cloudkit/publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type: "wod", id }),
      });
      await fetchPublishStatus();
      toast(`Published WOD: ${wod.title || wod.date}`, "success");
    } catch (e) {
      toast(String(e), "error");
    }
  }

  async function handlePublishOne(id: string) {
    await publishSingleWOD(id);
  }

  async function handleBatchPublish() {
    setBatchPublishing(true);
    try {

      for (const id of checkedIds) {
        const wod = wods.find((w) => w.id === id);
        if (!wod) continue;
        try {
          await saveWODRecord(wod);
          await fetch("/api/cloudkit/publish", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: "wod", id }),
          });
        } catch (e) {
          toast(`Failed to publish ${wod.title || wod.date}: ${e}`, "error");
        }
      }
      await fetchPublishStatus();
      toast(`Published ${checkedIds.size} WODs`, "success");
      setCheckedIds(new Set());
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setBatchPublishing(false);
    }
  }

  function handleGenerated(rawWods: any[]) {
    const decoded = rawWods.map(decodeWOD);
    // Merge into local state (replace by ID if already exists)
    setWods((prev) => {
      const map = new Map(prev.map((w) => [w.id, w]));
      for (const w of decoded) {
        map.set(w.id, w);
      }
      return [...map.values()].sort((a, b) => a.date.localeCompare(b.date));
    });
    // Load the first generated WOD into the editor
    if (decoded.length > 0) {
      setSelectedId(decoded[0].id);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40">
        Loading WODs...
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full gap-4 p-4">
      {/* Generator toggle */}
      <div className="shrink-0">
        <button
          onClick={() => setShowGenerator((v) => !v)}
          className="px-3 py-1.5 border border-navy/20 rounded text-sm font-medium text-navy hover:bg-navy/5 transition-colors"
        >
          {showGenerator ? "Hide Generator" : "Generate WOD"}
        </button>
      </div>

      {/* AI generator panel */}
      {showGenerator && (
        <div className="shrink-0">
          <WODGenerator onGenerated={handleGenerated} />
        </div>
      )}

      {/* Two-panel layout */}
      <div className="flex flex-1 gap-4 min-h-0">
        {/* Left panel: list */}
        <div className="w-96 shrink-0">
          <WODList
            wods={listItems}
            selectedId={selectedId}
            onSelect={setSelectedId}
            onNew={handleNew}
            selectedIds={checkedIds}
            onToggleSelect={handleToggleSelect}
            onBatchPublish={handleBatchPublish}
            onPublishOne={handlePublishOne}
            batchPublishing={batchPublishing}
          />
        </div>

        {/* Right panel: editor */}
        <div className="flex-1 border border-navy/10 rounded bg-white min-h-0">
          <WODEditor
            wod={selectedWOD}
            existingDates={existingDates}
            onSave={handleSave}
            onDelete={handleDelete}
            saving={saving}
          />
        </div>
      </div>
    </div>
  );
}
