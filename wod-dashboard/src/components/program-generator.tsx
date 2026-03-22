"use client";

import { useRef, useState } from "react";
import { useToast } from "@/components/toast";

// ─── Types ───────────────────────────────────────────────────────────────────

interface ProgramGeneratorProps {
  onGenerated: (program: any) => void;
}

type Difficulty = "Beginner" | "Intermediate" | "Advanced";

// ─── Component ───────────────────────────────────────────────────────────────

export function ProgramGenerator({ onGenerated }: ProgramGeneratorProps) {
  const { toast } = useToast();

  // Free-text prompt
  const [prompt, setPrompt] = useState("");

  // Structured parameters (collapsible)
  const [showParams, setShowParams] = useState(false);
  const [category, setCategory] = useState("");
  const [durationWeeks, setDurationWeeks] = useState<number | "">("");
  const [sessionsPerWeek, setSessionsPerWeek] = useState<number | "">("");
  const [difficulty, setDifficulty] = useState<Difficulty>("Intermediate");
  const [goal, setGoal] = useState("");

  // Request state
  const [loading, setLoading] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  async function handleGenerate() {
    abortRef.current = new AbortController();
    setLoading(true);

    try {
      const body: Record<string, unknown> = {};

      if (prompt.trim()) body.prompt = prompt.trim();
      if (category.trim()) body.category = category.trim();
      if (durationWeeks !== "") body.duration = durationWeeks;
      if (sessionsPerWeek !== "") body.sessionsPerWeek = sessionsPerWeek;
      body.difficulty = difficulty;
      if (goal.trim()) body.goal = goal.trim();

      const res = await fetch("/api/generate/program", {
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
      onGenerated(parsed);
      toast("Program generated", "success");
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
      <h2 className="text-sm font-semibold text-navy uppercase tracking-wide mb-4">
        AI Program Generator
      </h2>

      {/* Free-text prompt */}
      <div className="flex flex-col gap-1 mb-3">
        <label className="text-xs font-medium text-navy/70">Prompt</label>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          disabled={loading}
          placeholder="e.g. 12-week squat peaking program, 3x/week, intermediate"
          rows={3}
          className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50 resize-none"
        />
      </div>

      {/* Collapsible structured parameters */}
      <div className="mb-3">
        <button
          type="button"
          onClick={() => setShowParams((v) => !v)}
          className="text-xs font-medium text-navy/60 hover:text-navy transition-colors flex items-center gap-1"
        >
          <span className="inline-block transition-transform" style={{ transform: showParams ? "rotate(90deg)" : "rotate(0deg)" }}>
            ▶
          </span>
          Or specify parameters
        </button>

        {showParams && (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 mt-3">
            {/* Category */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-navy/70">Category</label>
              <input
                type="text"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                disabled={loading}
                placeholder="e.g. Strength"
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
            </div>

            {/* Duration in weeks */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-navy/70">Duration (weeks)</label>
              <input
                type="number"
                min={1}
                max={52}
                value={durationWeeks}
                onChange={(e) =>
                  setDurationWeeks(e.target.value === "" ? "" : Math.max(1, parseInt(e.target.value, 10) || 1))
                }
                disabled={loading}
                placeholder="e.g. 12"
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
            </div>

            {/* Sessions per week */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-navy/70">Sessions / week</label>
              <input
                type="number"
                min={1}
                max={7}
                value={sessionsPerWeek}
                onChange={(e) =>
                  setSessionsPerWeek(e.target.value === "" ? "" : Math.max(1, parseInt(e.target.value, 10) || 1))
                }
                disabled={loading}
                placeholder="e.g. 3"
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
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

            {/* Goal */}
            <div className="flex flex-col gap-1 col-span-2 sm:col-span-2">
              <label className="text-xs font-medium text-navy/70">Goal</label>
              <input
                type="text"
                value={goal}
                onChange={(e) => setGoal(e.target.value)}
                disabled={loading}
                placeholder="e.g. increase squat 1RM"
                className="border border-navy/20 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-orange/50 disabled:opacity-50"
              />
            </div>
          </div>
        )}
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
