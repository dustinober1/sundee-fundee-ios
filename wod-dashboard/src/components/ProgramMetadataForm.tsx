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
  const [name, setName] = useState('');
  const [category, setCategory] = useState('strength');
  const [description, setDescription] = useState('');
  const [durationWeeks, setDurationWeeks] = useState<ProgramDuration>(4);
  const [sessionsPerWeek, setSessionsPerWeek] = useState(3);
  const [difficulty, setDifficulty] = useState('intermediate');
  const [startDate, setStartDate] = useState(nextSunday());
  const [aiPrompt, setAiPrompt] = useState('');

  const endDate = calcEndDate(startDate, durationWeeks);
  const [saving, setSaving] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const slug = nameToSlug(name);
  const isValid = name.trim().length > 0 && slug.length > 0;

  async function handleBuildManually() {
    if (!isValid) return;
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

  async function handleGenerateWithAI() {
    if (!isValid || !aiPrompt.trim()) return;
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

      const program: ProgramFormData = {
        id: slug,
        name: name.trim(),
        category,
        description: generated.description || description.trim(),
        durationWeeks,
        sessionsPerWeek,
        difficulty,
        status: 'draft',
        startDate,
        endDate,
        createdAt: now,
        updatedAt: now,
        phases: generated.phases || [],
        weeks: generated.weeks || [],
        cycleAdjustmentProfile: generated.cycleAdjustmentProfile || null,
      };

      await saveProgram(program);
      router.push(`/programs/${slug}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate program');
      setGenerating(false);
    }
  }

  const busy = saving || generating;

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

      <div className="art-deco-card p-5 space-y-5">
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

        {/* Divider */}
        <div className="art-deco-divider" />

        {/* Build Manually */}
        <div>
          <button
            onClick={handleBuildManually}
            disabled={!isValid || busy}
            className="w-full px-5 py-3 bg-navy text-cream font-medium rounded-lg hover:bg-navy-light disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
          >
            {saving ? 'Creating...' : 'Build Manually'}
          </button>
          <p className="mt-1 text-xs text-navy/40 text-center">
            Creates empty program shell with {durationWeeks} weeks x {sessionsPerWeek} sessions
          </p>
        </div>

        {/* Or generate with AI */}
        <div className="relative">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-navy/10" />
          </div>
          <div className="relative flex justify-center text-xs">
            <span className="bg-white px-3 text-navy/40 font-medium uppercase tracking-wider">
              or
            </span>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-navy mb-1">Generate with AI</label>
          <textarea
            value={aiPrompt}
            onChange={(e) => setAiPrompt(e.target.value)}
            placeholder="Describe the program you want, e.g. 'A progressive overload strength program for intermediates focusing on the big 3 lifts with accessories'"
            rows={3}
            className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream/30 text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
          />
          <button
            onClick={handleGenerateWithAI}
            disabled={!isValid || !aiPrompt.trim() || busy}
            className="mt-2 w-full px-5 py-3 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm inline-flex items-center justify-center gap-2"
          >
            {generating && (
              <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
            )}
            {generating ? 'Generating...' : 'Generate with AI'}
          </button>
        </div>
      </div>
    </div>
  );
}
