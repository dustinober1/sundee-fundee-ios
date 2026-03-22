"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { BenchmarkList, type BenchmarkListItem } from "@/components/benchmark-list";
import { BenchmarkEditor } from "@/components/benchmark-editor";
import { useToast } from "@/components/toast";
import type { BenchmarkDefinition } from "@/lib/types";
import { saveBenchmarkRecord } from "@/lib/cloudkit";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function blankBenchmark(nextOrder: number): BenchmarkDefinition {
  const slug = `sf-benchmark-${Date.now()}`;
  return {
    id: slug,
    name: "",
    category: "Sundee Fundee",
    workoutDescription: "",
    scoringTypeRaw: "time",
    sortOrder: nextOrder,
  };
}

// ─── Page ────────────────────────────────────────────────────────────────────

interface PublishStatus {
  benchmarks: Record<string, { publishedAt: string }>;
}

export default function BenchmarksPage() {
  const { toast } = useToast();
  const [benchmarks, setBenchmarks] = useState<BenchmarkDefinition[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [publishStatus, setPublishStatus] = useState<PublishStatus>({ benchmarks: {} });
  const [batchPublishing, setBatchPublishing] = useState(false);

  const fetchPublishStatus = useCallback(async () => {
    try {
      const res = await fetch("/api/cloudkit/publish");
      if (res.ok) {
        const data = await res.json();
        setPublishStatus({ benchmarks: data.benchmarks ?? {} });
      }
    } catch {
      // Non-critical
    }
  }, []);

  const fetchBenchmarks = useCallback(async () => {
    try {
      const res = await fetch("/api/benchmarks");
      if (!res.ok) throw new Error("Failed to fetch benchmarks");
      const raw = await res.json();
      setBenchmarks(Array.isArray(raw) ? raw : []);
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchBenchmarks();
    fetchPublishStatus();
  }, [fetchBenchmarks, fetchPublishStatus]);

  const selectedBenchmark = useMemo(
    () => benchmarks.find((b) => b.id === selectedId) ?? null,
    [benchmarks, selectedId]
  );

  const listItems: BenchmarkListItem[] = useMemo(
    () =>
      benchmarks.map((b) => ({
        id: b.id,
        name: b.name,
        scoringTypeRaw: b.scoringTypeRaw,
        sortOrder: b.sortOrder,
        published: b.id in publishStatus.benchmarks,
      })),
    [benchmarks, publishStatus]
  );

  function handleNew() {
    const nextOrder = benchmarks.length > 0
      ? Math.max(...benchmarks.map((b) => b.sortOrder)) + 1
      : 1;
    const newBenchmark = blankBenchmark(nextOrder);
    setBenchmarks((prev) => [...prev, newBenchmark]);
    setSelectedId(newBenchmark.id);
  }

  async function handleSave(benchmark: BenchmarkDefinition) {
    setSaving(true);
    try {
      const res = await fetch("/api/benchmarks", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(benchmark),
      });
      if (!res.ok) throw new Error("Failed to save benchmark");
      toast("Benchmark saved", "success");
      await fetchBenchmarks();
      setSelectedId(benchmark.id);
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string) {
    try {
      const res = await fetch(`/api/benchmarks?id=${encodeURIComponent(id)}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("Failed to delete benchmark");
      toast("Benchmark deleted", "success");
      setSelectedId(null);
      await fetchBenchmarks();
    } catch (e) {
      toast(String(e), "error");
    }
  }

  function handleToggleSelect(id: string) {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) { next.delete(id); } else { next.add(id); }
      return next;
    });
  }

  async function publishSingle(id: string) {
    const benchmark = benchmarks.find((b) => b.id === id);
    if (!benchmark) return;
    try {
      await saveBenchmarkRecord(benchmark);
      await fetch("/api/cloudkit/publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type: "benchmark", id }),
      });
      await fetchPublishStatus();
      toast(`Published benchmark: ${benchmark.name}`, "success");
    } catch (e) {
      toast(String(e), "error");
    }
  }

  async function handleBatchPublish() {
    setBatchPublishing(true);
    try {
      for (const id of checkedIds) {
        const benchmark = benchmarks.find((b) => b.id === id);
        if (!benchmark) continue;
        try {
          await saveBenchmarkRecord(benchmark);
          await fetch("/api/cloudkit/publish", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: "benchmark", id }),
          });
        } catch (e) {
          toast(`Failed to publish ${benchmark.name}: ${e}`, "error");
        }
      }
      await fetchPublishStatus();
      toast(`Published ${checkedIds.size} benchmarks`, "success");
      setCheckedIds(new Set());
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setBatchPublishing(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40">
        Loading benchmarks...
      </div>
    );
  }

  return (
    <div className="flex flex-1 gap-4 min-h-0 p-4 h-full">
      {/* Left panel: list */}
      <div className="w-96 shrink-0">
        <BenchmarkList
          benchmarks={listItems}
          selectedId={selectedId}
          onSelect={setSelectedId}
          onNew={handleNew}
          selectedIds={checkedIds}
          onToggleSelect={handleToggleSelect}
          onBatchPublish={handleBatchPublish}
          onPublishOne={publishSingle}
          batchPublishing={batchPublishing}
        />
      </div>

      {/* Right panel: editor */}
      <div className="flex-1 border border-navy/10 rounded bg-white min-h-0">
        <BenchmarkEditor
          benchmark={selectedBenchmark}
          onSave={handleSave}
          onDelete={handleDelete}
          saving={saving}
        />
      </div>
    </div>
  );
}
