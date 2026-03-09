'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ProgramFormData,
  ProgramDuration,
  ProgramWeek,
  ProgramSession,
} from '@/types/program';
import { saveProgram } from '@/lib/program-service';

const CATEGORIES = [
  { value: 'strength', label: 'Strength' },
  { value: 'hypertrophy', label: 'Hypertrophy' },
  { value: 'powerlifting', label: 'Powerlifting' },
  { value: 'general', label: 'General' },
];

const DIFFICULTIES = [
  { value: 'beginner', label: 'Beginner' },
  { value: 'intermediate', label: 'Intermediate' },
  { value: 'advanced', label: 'Advanced' },
];

const DURATIONS: ProgramDuration[] = [4, 8, 12];

/** Find the next Sunday on or after a given date string (YYYY-MM-DD). */
function nextSunday(dateStr?: string): string {
  const d = dateStr ? new Date(dateStr + 'T00:00:00') : new Date();
  const day = d.getDay(); // 0=Sun
  if (day !== 0) d.setDate(d.getDate() + (7 - day));
  return d.toISOString().slice(0, 10);
}

/** Calculate end date: startDate + (durationWeeks - 1) weeks (last Sunday). */
function calcEndDate(startDate: string, durationWeeks: number): string {
  const d = new Date(startDate + 'T00:00:00');
  d.setDate(d.getDate() + (durationWeeks - 1) * 7);
  return d.toISOString().slice(0, 10);
}

function nameToSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

function promptToSlug(prompt: string): string {
  const words = prompt.trim().split(/\s+/).slice(0, 5).join(' ');
  const base = nameToSlug(words);
  const suffix = Date.now().toString(36).slice(-4);
  return base ? `${base}-${suffix}` : `ai-program-${suffix}`;
}

function promptToName(prompt: string): string {
  const trimmed = prompt.trim();
  if (trimmed.length <= 60) return trimmed;
  return trimmed.slice(0, 57) + '...';
}

function createEmptySession(weekNum: number, sessionNum: number): ProgramSession {
  return {
    sessionId: `w${weekNum}-s${sessionNum}`,
    sessionName: `Session ${sessionNum}`,
    sessionType: 'strength',
    focus: '',
    exercises: [],
  };
}

function createEmptyWeeks(
  durationWeeks: number,
  sessionsPerWeek: number
): ProgramWeek[] {
  return Array.from({ length: durationWeeks }, (_, i) => ({
    week: i + 1,
    phaseId: null,
    isTestWeek: false,
    sessions: Array.from({ length: sessionsPerWeek }, (_, j) =>
      createEmptySession(i + 1, j + 1)
    ),
  }));
}

export default function ProgramMetadataForm() {
  const router = useRouter();

  // Shared config (used by both paths)
  const [category, setCategory] = useState('strength');
  const [durationWeeks, setDurationWeeks] = useState<ProgramDuration>(4);
  const [sessionsPerWeek, setSessionsPerWeek] = useState(3);
  const [difficulty, setDifficulty] = useState('intermediate');

  // AI path
  const [aiPrompt, setAiPrompt] = useState('');
  const [generating, setGenerating] = useState(false);

  // Manual path
  const [showManual, setShowManual] = useState(false);
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState(nextSunday());
  const [saving, setSaving] = useState(false);

  const [error, setError] = useState<string | null>(null);

  const endDate = calcEndDate(startDate, durationWeeks);
  const slug = nameToSlug(name);
  const isManualValid = name.trim().length > 0 && slug.length > 0;
  const isAiValid = aiPrompt.trim().length > 0;
  const busy = saving || generating;

  async function handleGenerateWithAI() {
    if (!isAiValid) return;
    setGenerating(true);
    setError(null);
    try {
      const response = await fetch('/api/generate-program', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt: aiPrompt,
          durationWeeks,
          sessionsPerWeek,
          difficulty,
          category,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'AI generation failed');
      }

      const generated = await response.json();
      const now = new Date().toISOString();
      const autoSlug = promptToSlug(aiPrompt);
      const autoName = promptToName(aiPrompt);
      const autoStartDate = nextSunday();

      const program: ProgramFormData = {
        id: autoSlug,
        name: autoName,
        category,
        description: generated.description || '',
        durationWeeks,
        sessionsPerWeek,
        difficulty,
        status: 'draft',
        startDate: autoStartDate,
        endDate: calcEndDate(autoStartDate, durationWeeks),
        createdAt: now,
        updatedAt: now,
        phases: generated.phases || [],
        weeks: generated.weeks || [],
        cycleAdjustmentProfile: generated.cycleAdjustmentProfile || null,
      };

      await saveProgram(program);
      router.push(`/programs/${autoSlug}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate program');
      setGenerating(false);
    }
  }

  async function handleBuildManually() {
    if (!isManualValid) return;
    setSaving(true);
    setError(null);
    try {
      const program: ProgramFormData = {
        id: slug,
        name: name.trim(),
        category,
        description: description.trim(),
        durationWeeks,
        sessionsPerWeek,
        difficulty,
        status: 'draft',
        startDate,
        endDate,
        phases: [],
        weeks: createEmptyWeeks(durationWeeks, sessionsPerWeek),
      };
      await saveProgram(program);
      router.push(`/programs/${slug}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create program');
      setSaving(false);
    }
  }

  return (
    <div className="max-w-3xl mx-auto">
      <button
        onClick={() => router.push('/programs')}
        className="text-sm text-orange hover:underline mb-4 inline-flex items-center gap-1"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
        </svg>
        Back to Programs
      </button>

      <h1 className="text-2xl font-bold text-navy mb-6">New Program</h1>

      {error && (
        <div className="mb-4 px-4 py-3 rounded-lg text-sm font-medium bg-red-50 text-red-700 border border-red-200">
          {error}
        </div>
      )}

      {/* ── Section 1: Generate with AI (Primary) ── */}
      <div className="art-deco-card p-5 space-y-5">
        <div className="flex items-center gap-2 mb-1">
          <svg className="w-5 h-5 text-orange" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
          <h2 className="text-lg font-bold text-navy">Generate with AI</h2>
        </div>
        <p className="text-xs text-navy/50">
          Describe the program you want and AI will generate all weeks, sessions, and exercises. You can edit everything after.
        </p>

        {/* AI Prompt */}
        <div>
          <label className="block text-sm font-medium text-navy mb-1">What kind of program?</label>
          <textarea
            value={aiPrompt}
            onChange={(e) => setAiPrompt(e.target.value)}
            placeholder="e.g. A progressive overload strength program for intermediates focusing on the big 3 lifts with accessories, including a deload week every 4th week"
            rows={4}
            className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream/30 text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
          />
        </div>

        {/* Quick Config Row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Duration</label>
            <select
              value={durationWeeks}
              onChange={(e) => setDurationWeeks(Number(e.target.value) as ProgramDuration)}
              className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              {DURATIONS.map((d) => (
                <option key={d} value={d}>
                  {d} weeks
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Sessions/wk</label>
            <select
              value={sessionsPerWeek}
              onChange={(e) => setSessionsPerWeek(Number(e.target.value))}
              className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              {[1, 2, 3, 4, 5, 6].map((n) => (
                <option key={n} value={n}>
                  {n}x
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Difficulty</label>
            <select
              value={difficulty}
              onChange={(e) => setDifficulty(e.target.value)}
              className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              {DIFFICULTIES.map((d) => (
                <option key={d.value} value={d.value}>
                  {d.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Category</label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            >
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Generate Button */}
        <button
          onClick={handleGenerateWithAI}
          disabled={!isAiValid || busy}
          className="w-full px-5 py-3 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm inline-flex items-center justify-center gap-2"
        >
          {generating && (
            <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
          )}
          {generating ? 'Generating Program...' : 'Generate with AI'}
        </button>
      </div>

      {/* ── Divider ── */}
      <div className="relative my-6">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-navy/10" />
        </div>
        <div className="relative flex justify-center text-xs">
          <span className="bg-cream px-3 text-navy/40 font-medium uppercase tracking-wider">
            or
          </span>
        </div>
      </div>

      {/* ── Section 2: Build from Scratch (Secondary) ── */}
      <div className="art-deco-card p-5">
        <button
          onClick={() => setShowManual(!showManual)}
          className="w-full flex items-center justify-between text-left"
        >
          <div className="flex items-center gap-2">
            <svg className="w-5 h-5 text-navy/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            <h2 className="text-lg font-bold text-navy">Build from Scratch</h2>
          </div>
          <svg
            className={`w-5 h-5 text-navy/40 transition-transform ${showManual ? 'rotate-180' : ''}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {showManual && (
          <div className="mt-5 space-y-5">
            {/* Name */}
            <div>
              <label className="block text-sm font-medium text-navy mb-1">Program Name *</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Beginner Strength Builder"
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
              {slug && (
                <p className="mt-1 text-xs text-navy/40">
                  ID: <code className="bg-cream-dark/50 px-1 rounded">{slug}</code>
                </p>
              )}
            </div>

            {/* Category */}
            <div>
              <label className="block text-sm font-medium text-navy mb-2">Category</label>
              <div className="flex flex-wrap gap-2">
                {CATEGORIES.map((c) => (
                  <button
                    key={c.value}
                    onClick={() => setCategory(c.value)}
                    className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors border ${
                      category === c.value
                        ? 'bg-navy text-cream border-navy'
                        : 'bg-white text-navy border-navy/20 hover:border-orange hover:text-orange'
                    }`}
                  >
                    {c.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-navy mb-1">Description</label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Brief description of the program..."
                rows={2}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
              />
            </div>

            {/* Duration + Sessions + Difficulty */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-navy mb-1">Duration (weeks)</label>
                <select
                  value={durationWeeks}
                  onChange={(e) => setDurationWeeks(Number(e.target.value) as ProgramDuration)}
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                >
                  {DURATIONS.map((d) => (
                    <option key={d} value={d}>
                      {d} weeks
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-navy mb-1">Sessions / Week</label>
                <select
                  value={sessionsPerWeek}
                  onChange={(e) => setSessionsPerWeek(Number(e.target.value))}
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                >
                  {[1, 2, 3, 4, 5, 6].map((n) => (
                    <option key={n} value={n}>
                      {n}x
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-navy mb-1">Difficulty</label>
                <select
                  value={difficulty}
                  onChange={(e) => setDifficulty(e.target.value)}
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                >
                  {DIFFICULTIES.map((d) => (
                    <option key={d.value} value={d.value}>
                      {d.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Schedule */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-navy mb-1">Start Date (Sunday)</label>
                <input
                  type="date"
                  value={startDate}
                  onChange={(e) => setStartDate(nextSunday(e.target.value))}
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
                {new Date(startDate + 'T00:00:00').getDay() === 0 && (
                  <p className="mt-1 text-xs text-navy/40">
                    Week 1 starts {new Date(startDate + 'T00:00:00').toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' })}
                  </p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-navy mb-1">End Date (auto)</label>
                <input
                  type="date"
                  value={endDate}
                  disabled
                  className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream-dark/30 text-navy/60 text-sm"
                />
                <p className="mt-1 text-xs text-navy/40">
                  Runs {durationWeeks} Sundays &middot; Users can make up missed workouts anytime
                </p>
              </div>
            </div>

            {/* Build Manually Button */}
            <button
              onClick={handleBuildManually}
              disabled={!isManualValid || busy}
              className="w-full px-5 py-3 bg-navy text-cream font-medium rounded-lg hover:bg-navy-light disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
            >
              {saving ? 'Creating...' : 'Build Manually'}
            </button>
            <p className="text-xs text-navy/40 text-center">
              Creates empty program shell with {durationWeeks} weeks x {sessionsPerWeek} sessions
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
