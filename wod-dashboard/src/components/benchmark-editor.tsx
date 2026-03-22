"use client";

import { useEffect, useState } from "react";
import type { BenchmarkDefinition } from "@/lib/types";

// ─── Props ───────────────────────────────────────────────────────────────────

interface BenchmarkEditorProps {
  benchmark: BenchmarkDefinition | null;
  onSave: (benchmark: BenchmarkDefinition) => void;
  onDelete: (id: string) => void;
  saving?: boolean;
}

const SCORING_OPTIONS = [
  { value: "time", label: "For Time (lower is better)" },
  { value: "reps", label: "Max Reps (higher is better)" },
  { value: "weight", label: "Max Weight (higher is better)" },
  { value: "distance", label: "Distance (time-based, lower is better)" },
  { value: "roundsAndReps", label: "Rounds + Reps (AMRAP, higher is better)" },
];

// ─── Component ───────────────────────────────────────────────────────────────

export function BenchmarkEditor({
  benchmark,
  onSave,
  onDelete,
  saving = false,
}: BenchmarkEditorProps) {
  const [name, setName] = useState("");
  const [workoutDescription, setWorkoutDescription] = useState("");
  const [scoringTypeRaw, setScoringTypeRaw] = useState("time");
  const [sortOrder, setSortOrder] = useState(0);

  // Sync from prop
  useEffect(() => {
    if (benchmark) {
      setName(benchmark.name);
      setWorkoutDescription(benchmark.workoutDescription);
      setScoringTypeRaw(benchmark.scoringTypeRaw);
      setSortOrder(benchmark.sortOrder);
    }
  }, [benchmark]);

  function handleSave() {
    if (!benchmark || !name.trim()) return;
    onSave({
      id: benchmark.id,
      name: name.trim(),
      category: "Sundee Fundee",
      workoutDescription,
      scoringTypeRaw,
      sortOrder,
    });
  }

  if (!benchmark) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40 text-lg">
        Select a benchmark or create a new one
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full overflow-y-auto p-4">
      {/* ID (read-only) */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">ID</label>
        <input
          type="text"
          value={benchmark.id}
          readOnly
          className="w-full border border-navy/10 rounded px-3 py-1.5 text-sm bg-navy/5 text-navy/50"
        />
      </div>

      {/* Name */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">Name</label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Benchmark name"
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
        />
      </div>

      {/* Category (read-only) */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">Category</label>
        <input
          type="text"
          value="Sundee Fundee"
          readOnly
          className="w-full border border-navy/10 rounded px-3 py-1.5 text-sm bg-navy/5 text-navy/50"
        />
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        {/* Scoring Type */}
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Scoring Type
          </label>
          <select
            value={scoringTypeRaw}
            onChange={(e) => setScoringTypeRaw(e.target.value)}
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          >
            {SCORING_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        {/* Sort Order */}
        <div>
          <label className="block text-sm font-medium text-navy/70 mb-1">
            Sort Order
          </label>
          <input
            type="number"
            value={sortOrder}
            onChange={(e) => setSortOrder(parseInt(e.target.value, 10) || 0)}
            min={0}
            className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
          />
        </div>
      </div>

      {/* Description */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-navy/70 mb-1">
          Workout Description
        </label>
        <textarea
          value={workoutDescription}
          onChange={(e) => setWorkoutDescription(e.target.value)}
          placeholder="Describe the workout, movements, rep scheme..."
          rows={6}
          className="w-full border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40 resize-y"
        />
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3 pt-4 border-t border-navy/10 mt-auto">
        <button
          type="button"
          onClick={handleSave}
          disabled={!name.trim() || saving}
          className="bg-orange text-white px-4 py-2 rounded font-medium hover:bg-orange/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
        >
          {saving ? "Saving..." : "Save"}
        </button>
        <button
          type="button"
          onClick={() => {
            if (window.confirm(`Delete benchmark "${benchmark.name}"?`)) {
              onDelete(benchmark.id);
            }
          }}
          className="bg-red-500 text-white px-4 py-2 rounded font-medium hover:bg-red-600 transition-colors"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
