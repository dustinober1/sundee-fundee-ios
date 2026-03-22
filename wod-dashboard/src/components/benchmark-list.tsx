"use client";

import { useMemo, useState } from "react";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface BenchmarkListItem {
  id: string;
  name: string;
  scoringTypeRaw: string;
  sortOrder: number;
  published: boolean;
}

interface BenchmarkListProps {
  benchmarks: BenchmarkListItem[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  selectedIds: Set<string>;
  onToggleSelect: (id: string) => void;
  onBatchPublish: () => void;
  onPublishOne: (id: string) => Promise<void>;
  batchPublishing: boolean;
}

const SCORING_LABELS: Record<string, string> = {
  time: "For Time",
  reps: "Max Reps",
  weight: "Max Weight",
  distance: "Distance",
  roundsAndReps: "Rounds + Reps",
};

// ─── Component ───────────────────────────────────────────────────────────────

export function BenchmarkList({
  benchmarks,
  selectedId,
  onSelect,
  onNew,
  selectedIds,
  onToggleSelect,
  onBatchPublish,
  onPublishOne,
  batchPublishing,
}: BenchmarkListProps) {
  const [search, setSearch] = useState("");
  const [publishingId, setPublishingId] = useState<string | null>(null);

  async function handlePublishOne(e: React.MouseEvent, id: string) {
    e.stopPropagation();
    setPublishingId(id);
    try {
      await onPublishOne(id);
    } finally {
      setPublishingId(null);
    }
  }

  const filtered = useMemo(() => {
    let items = [...benchmarks];
    if (search) {
      const q = search.toLowerCase();
      items = items.filter((b) => b.name.toLowerCase().includes(q));
    }
    items.sort((a, b) => a.sortOrder - b.sortOrder);
    return items;
  }, [benchmarks, search]);

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center gap-2 mb-3">
        <button
          type="button"
          onClick={onNew}
          className="bg-orange text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-orange/90 transition-colors"
        >
          New Benchmark
        </button>
        <button
          type="button"
          onClick={onBatchPublish}
          disabled={selectedIds.size === 0 || batchPublishing}
          className="bg-navy text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-navy/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {batchPublishing ? "Publishing..." : "Publish Selected"}
        </button>
      </div>

      {/* Search */}
      <div className="mb-3">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search benchmarks..."
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto border border-navy/10 rounded">
        <table className="w-full text-sm">
          <thead className="bg-navy/5 sticky top-0">
            <tr>
              <th className="w-8 px-2 py-2" />
              <th className="text-left px-2 py-2 font-medium text-navy/70">Name</th>
              <th className="text-left px-2 py-2 font-medium text-navy/70">Scoring</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Order</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Status</th>
              <th className="w-20 px-2 py-2" />
            </tr>
          </thead>
          <tbody>
            {filtered.map((b) => (
              <tr
                key={b.id}
                onClick={() => onSelect(b.id)}
                className={`cursor-pointer border-t border-navy/5 transition-colors hover:bg-orange/5 ${
                  selectedId === b.id ? "bg-orange/10" : ""
                }`}
              >
                <td className="px-2 py-1.5 text-center">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(b.id)}
                    onChange={(e) => {
                      e.stopPropagation();
                      onToggleSelect(b.id);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    className="accent-navy"
                  />
                </td>
                <td className="px-2 py-1.5 truncate max-w-[12rem] font-medium">
                  {b.name}
                </td>
                <td className="px-2 py-1.5 text-navy/60">
                  {SCORING_LABELS[b.scoringTypeRaw] ?? b.scoringTypeRaw}
                </td>
                <td className="px-2 py-1.5 text-center text-navy/60">{b.sortOrder}</td>
                <td className="px-2 py-1.5 text-center">
                  <span
                    className={`text-xs font-medium px-1.5 py-0.5 rounded ${
                      b.published
                        ? "bg-green-100 text-green-700"
                        : "bg-navy/10 text-navy/50"
                    }`}
                  >
                    {b.published ? "Published" : "Local"}
                  </span>
                </td>
                <td className="px-2 py-1.5 text-center">
                  {!b.published && (
                    <button
                      type="button"
                      onClick={(e) => handlePublishOne(e, b.id)}
                      disabled={publishingId === b.id}
                      className="bg-orange text-white px-2 py-0.5 rounded text-xs font-medium hover:bg-orange/90 transition-colors disabled:opacity-50"
                    >
                      {publishingId === b.id ? "..." : "Publish"}
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-navy/40">
                  No benchmarks found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
