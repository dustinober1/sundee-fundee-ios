"use client";

import { useMemo, useState } from "react";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface WODListItem {
  id: string;
  date: string;
  title: string;
  exerciseCount: number;
  published: boolean;
}

interface WODListProps {
  wods: WODListItem[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  selectedIds: Set<string>;
  onToggleSelect: (id: string) => void;
  onBatchPublish: () => void;
  onPublishOne: (id: string) => Promise<void>;
  batchPublishing: boolean;
}

// ─── Component ───────────────────────────────────────────────────────────────

export function WODList({
  wods,
  selectedId,
  onSelect,
  onNew,
  selectedIds,
  onToggleSelect,
  onBatchPublish,
  onPublishOne,
  batchPublishing,
}: WODListProps) {
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
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
    let items = [...wods];

    // Date range filter
    if (startDate) {
      items = items.filter((w) => w.date >= startDate);
    }
    if (endDate) {
      items = items.filter((w) => w.date <= endDate);
    }

    // Sort by date descending
    items.sort((a, b) => b.date.localeCompare(a.date));

    return items;
  }, [wods, startDate, endDate]);

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center gap-2 mb-3">
        <button
          type="button"
          onClick={onNew}
          className="bg-orange text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-orange/90 transition-colors"
        >
          New WOD
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

      {/* Date range filter */}
      <div className="flex items-center gap-2 mb-3 text-sm">
        <label className="text-navy/70">From</label>
        <input
          type="date"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          className="border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
        <label className="text-navy/70">To</label>
        <input
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          className="border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto border border-navy/10 rounded">
        <table className="w-full text-sm">
          <thead className="bg-navy/5 sticky top-0">
            <tr>
              <th className="w-8 px-2 py-2" />
              <th className="text-left px-2 py-2 font-medium text-navy/70">Date</th>
              <th className="text-left px-2 py-2 font-medium text-navy/70">Title</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Ex.</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Status</th>
              <th className="w-20 px-2 py-2" />
            </tr>
          </thead>
          <tbody>
            {filtered.map((wod) => (
              <tr
                key={wod.id}
                onClick={() => onSelect(wod.id)}
                className={`cursor-pointer border-t border-navy/5 transition-colors hover:bg-orange/5 ${
                  selectedId === wod.id ? "bg-orange/10" : ""
                }`}
              >
                <td className="px-2 py-1.5 text-center">
                  <input
                    type="checkbox"
                    checked={selectedIds.has(wod.id)}
                    onChange={(e) => {
                      e.stopPropagation();
                      onToggleSelect(wod.id);
                    }}
                    onClick={(e) => e.stopPropagation()}
                    className="accent-navy"
                  />
                </td>
                <td className="px-2 py-1.5 whitespace-nowrap font-mono text-navy/80">
                  {wod.date}
                </td>
                <td className="px-2 py-1.5 truncate max-w-[10rem]">{wod.title}</td>
                <td className="px-2 py-1.5 text-center text-navy/60">{wod.exerciseCount}</td>
                <td className="px-2 py-1.5 text-center">
                  <span
                    className={`text-xs font-medium px-1.5 py-0.5 rounded ${
                      wod.published
                        ? "bg-green-100 text-green-700"
                        : "bg-navy/10 text-navy/50"
                    }`}
                  >
                    {wod.published ? "Published" : "Local"}
                  </span>
                </td>
                <td className="px-2 py-1.5 text-center">
                  {!wod.published && (
                    <button
                      type="button"
                      onClick={(e) => handlePublishOne(e, wod.id)}
                      disabled={publishingId === wod.id}
                      className="bg-orange text-white px-2 py-0.5 rounded text-xs font-medium hover:bg-orange/90 transition-colors disabled:opacity-50"
                    >
                      {publishingId === wod.id ? "..." : "Publish"}
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-navy/40">
                  No WODs found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
