"use client";

import { useRef, useState } from "react";
import { useToast } from "@/components/toast";

// ─── Types ───────────────────────────────────────────────────────────────────

interface WODGeneratorProps {
  onGenerated: (wods: any[]) => void;
}

type FocusArea = "Squat" | "Hip Hinge" | "Press" | "Pull" | "Full Body";
type Difficulty = "Beginner" | "Intermediate" | "Advanced";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

/** Return all ISO date strings from start to end (inclusive). */
function datesInRange(start: string, end: string): string[] {
  const dates: string[] = [];
  const cur = new Date(start + "T00:00:00");
  const last = new Date(end + "T00:00:00");
  while (cur <= last) {
    dates.push(cur.toISOString().slice(0, 10));
    cur.setDate(cur.getDate() + 1);
  }
  return dates;
}

// ─── Component ───────────────────────────────────────────────────────────────

export function WODGenerator({ onGenerated }: WODGeneratorProps) {
  const { toast } = useToast();

  // Mode
  const [batchMode, setBatchMode] = useState(false);

  // Fields
  const [date, setDate] = useState(todayString());
  const [startDate, setStartDate] = useState(todayString());
  const [endDate, setEndDate] = useState(todayString());
  const [focusArea, setFocusArea] = useState<FocusArea>("Full Body");
  const [difficulty, setDifficulty] = useState<Difficulty>("Intermediate");
  const [exerciseCount, setExerciseCount] = useState(4);
  const [equipment, setEquipment] = useState("full gym");
  const [notes, setNotes] = useState("");

  // Request state
  const [loading, setLoading] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  async function handleGenerate() {
    abortRef.current = new AbortController();
    setLoading(true);

    try {
      const body: Record<string, unknown> = {
        focusArea,
        difficulty,
        exerciseCount,
        equipment,
        ...(notes.trim() ? { notes: notes.trim() } : {}),
      };

      if (batchMode) {
        const dates = datesInRange(startDate, endDate);
        if (dates.length === 0) {
          toast("End date must be on or after start date", "error");
          return;
        }
        body.batchDates = dates;
      } else {
        body.date = date;
      }

      const res = await fetch("/api/generate/wod", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
        signal: abortRef.current.signal,
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: res.statusText }));
        throw new Error(err.error ?? `HTTP ${res.status}`);
      }

      const parsed = await res.json();
      // API returns either a single WOD object or an array for batch
      const wodArray: any[] = Array.isArray(parsed) ? parsed : [parsed];
      onGenerated(wodArray);
      toast(`Generated ${wodArray.length} WOD${wodArray.length !== 1 ? "s" : ""}`, "success");
    } catch (e: unknown) {
      if (e instanceof Error && e.name === "AbortError") {
        toast("Generation cancelled", "error");
      } else {
        toast(String(e), "error");
      }
    } finally {
      setLoading(false);
      abortRef.current = null;
    }
  }

  function handleCancel() {
    abortRef.current?.abort();
  }

  // ─── Render ────────────────────────────────────────────────────────────────

  return (
    <div className="border border-navy/10 rounded bg-white p-4 mb-4">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-sm font-semibold text-navy uppercase tracking-wide">
          AI WOD Generator
        </h2>
        <label className="flex items-center gap-2 text-xs text-navy/70 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={batchMode}
            onChange={(e) => setBatchMode(e.target.checked)}
            className="rounded"
          />
          Batch (date range)
        </label>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
        {/* Date / date range */}
        {batchMode ? (
          <>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-navy/70">Start Date</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                disabled={loading}
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-navy/70">End Date</label>
              <input
                type="date"
                value={endDate}
                min={startDate}
                onChange={(e) => setEndDate(e.target.value)}
                disabled={loading}
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
            </div>
          </>
        ) : (
          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-navy/70">Date</label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              disabled={loading}
              className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
            />
          </div>
        )}

        {/* Focus area */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-navy/70">Focus Area</label>
          <select
            value={focusArea}
            onChange={(e) => setFocusArea(e.target.value as FocusArea)}
            disabled={loading}
            className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50 bg-white"
          >
            <option>Squat</option>
            <option>Hip Hinge</option>
            <option>Press</option>
            <option>Pull</option>
            <option>Full Body</option>
          </select>
        </div>

        {/* Difficulty */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-navy/70">Difficulty</label>
          <select
            value={difficulty}
            onChange={(e) => setDifficulty(e.target.value as Difficulty)}
            disabled={loading}
            className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50 bg-white"
          >
            <option>Beginner</option>
            <option>Intermediate</option>
            <option>Advanced</option>
          </select>
        </div>

        {/* Exercise count */}
        <div className="flex flex-col gap-1">
          <label className="text-xs font-medium text-navy/70">Exercises</label>
          <input
            type="number"
            min={1}
            max={12}
            value={exerciseCount}
            onChange={(e) => setExerciseCount(Math.max(1, parseInt(e.target.value, 10) || 1))}
            disabled={loading}
            className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
          />
        </div>

        {/* Equipment */}
        <div className="flex flex-col gap-1 col-span-2 sm:col-span-1">
          <label className="text-xs font-medium text-navy/70">Equipment</label>
          <input
            type="text"
            value={equipment}
            onChange={(e) => setEquipment(e.target.value)}
            disabled={loading}
            placeholder="full gym"
            className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
          />
        </div>

        {/* Notes */}
        <div className="flex flex-col gap-1 col-span-2 lg:col-span-2">
          <label className="text-xs font-medium text-navy/70">Notes (optional)</label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            disabled={loading}
            placeholder="Any special instructions..."
            rows={1}
            className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50 resize-none"
          />
        </div>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3 mt-4">
        <button
          onClick={handleGenerate}
          disabled={loading}
          className="px-4 py-2 bg-navy text-cream text-sm font-medium rounded hover:bg-navy/90 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 transition-colors"
        >
          {loading ? (
            <>
              <span className="inline-block w-4 h-4 border-2 border-cream/30 border-t-cream rounded-full animate-spin" />
              Generating...
            </>
          ) : (
            "Generate"
          )}
        </button>

        {loading && (
          <button
            onClick={handleCancel}
            className="px-4 py-2 border border-navy/20 text-navy text-sm font-medium rounded hover:bg-navy/5 transition-colors"
          >
            Cancel
          </button>
        )}
      </div>
    </div>
  );
}
