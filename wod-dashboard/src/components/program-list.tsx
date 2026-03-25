"use client";

import { useMemo, useState } from "react";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface ProgramListItem {
  id: string;
  name: string;
  category: string;
  difficulty: string;
  durationWeeks: number;
  sessionsPerWeek: number;
  published: boolean;
}

interface ProgramListProps {
  programs: ProgramListItem[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onNew: () => void;
  onPublishOne: (id: string) => Promise<void>;
}

// ─── Component ───────────────────────────────────────────────────────────────

export function ProgramList({
  programs,
  selectedId,
  onSelect,
  onNew,
  onPublishOne,
}: ProgramListProps) {
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
    let items = [...programs];

    if (search) {
      const q = search.toLowerCase();
      items = items.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.category.toLowerCase().includes(q)
      );
    }

    // Sort alphabetically by name
    items.sort((a, b) => a.name.localeCompare(b.name));

    return items;
  }, [programs, search]);

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center gap-2 mb-3">
        <button
          type="button"
          onClick={onNew}
          className="bg-orange text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-orange/90 transition-colors"
        >
          New Program
        </button>
      </div>

      {/* Search filter */}
      <div className="mb-3">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search programs..."
          className="w-full border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
      </div>

      {/* Table */}
      <div className="flex-1 overflow-y-auto border border-navy/10 rounded">
        <table className="w-full text-sm">
          <thead className="bg-navy/5 sticky top-0">
            <tr>
              <th className="text-left px-2 py-2 font-medium text-navy/70">Name</th>
              <th className="text-left px-2 py-2 font-medium text-navy/70">Category</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Difficulty</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Wks</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Sess/Wk</th>
              <th className="text-center px-2 py-2 font-medium text-navy/70">Status</th>
              <th className="w-20 px-2 py-2" />
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => (
              <tr
                key={p.id}
                onClick={() => onSelect(p.id)}
                className={`cursor-pointer border-t border-navy/5 transition-colors hover:bg-orange/5 ${
                  selectedId === p.id ? "bg-orange/10" : ""
                }`}
              >
                <td className="px-2 py-1.5 truncate max-w-[10rem]">{p.name}</td>
                <td className="px-2 py-1.5 truncate max-w-[6rem] text-navy/70">{p.category}</td>
                <td className="px-2 py-1.5 text-center">
                  <span
                    className={`text-xs font-medium px-1.5 py-0.5 rounded ${
                      p.difficulty === "Beginner"
                        ? "bg-green-100 text-green-700"
                        : p.difficulty === "Intermediate"
                        ? "bg-yellow-100 text-yellow-700"
                        : p.difficulty === "Advanced"
                        ? "bg-red-100 text-red-700"
                        : "bg-navy/10 text-navy/50"
                    }`}
                  >
                    {p.difficulty}
                  </span>
                </td>
                <td className="px-2 py-1.5 text-center text-navy/60">{p.durationWeeks}</td>
                <td className="px-2 py-1.5 text-center text-navy/60">{p.sessionsPerWeek}</td>
                <td className="px-2 py-1.5 text-center">
                  <span
                    className={`text-xs font-medium px-1.5 py-0.5 rounded ${
                      p.published
                        ? "bg-green-100 text-green-700"
                        : "bg-navy/10 text-navy/50"
                    }`}
                  >
                    {p.published ? "Published" : "Local"}
                  </span>
                </td>
                <td className="px-2 py-1.5 text-center">
                  <button
                    type="button"
                    onClick={(e) => handlePublishOne(e, p.id)}
                    disabled={publishingId === p.id}
                    className={`px-2 py-0.5 rounded text-xs font-medium transition-colors disabled:opacity-50 ${
                      p.published
                        ? "border border-orange text-orange hover:bg-orange/10"
                        : "bg-orange text-white hover:bg-orange/90"
                    }`}
                  >
                    {publishingId === p.id ? "..." : p.published ? "Republish" : "Publish"}
                  </button>
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-navy/40">
                  No programs found
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
