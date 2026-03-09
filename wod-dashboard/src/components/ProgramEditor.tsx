'use client';

import { useReducer, useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  ProgramFormData,
  ProgramPhase,
  ProgramWeek,
  ProgramSession,
  ProgramExercise,
  ProgramDuration,
  ProgramCycleAdjustmentProfile,
} from '@/types/program';
import { fetchProgramByID, saveProgram, deleteProgram } from '@/lib/program-service';
import PhaseBar from './PhaseBar';
import WeekTabs from './WeekTabs';
import SessionCard from './SessionCard';
import CycleAdjustmentEditor from './CycleAdjustmentEditor';

// --- Reducer ---

type Action =
  | { type: 'SET_PROGRAM'; program: ProgramFormData }
  | { type: 'SET_METADATA'; field: string; value: string | number }
  | { type: 'SET_PHASES'; phases: ProgramPhase[] }
  | { type: 'UPDATE_WEEK'; weekIndex: number; week: ProgramWeek }
  | { type: 'COPY_WEEK'; sourceIndex: number; targetIndex: number }
  | { type: 'ADD_SESSION'; weekIndex: number }
  | { type: 'REMOVE_SESSION'; weekIndex: number; sessionIndex: number }
  | { type: 'UPDATE_SESSION'; weekIndex: number; sessionIndex: number; session: ProgramSession }
  | { type: 'SET_CYCLE_PROFILE'; profile: ProgramCycleAdjustmentProfile | null };

function createEmptySession(weekNum: number, sessionNum: number): ProgramSession {
  return {
    sessionId: `w${weekNum}-s${sessionNum}`,
    sessionName: `Session ${sessionNum}`,
    sessionType: 'strength',
    focus: '',
    exercises: [],
  };
}

function reducer(state: ProgramFormData, action: Action): ProgramFormData {
  switch (action.type) {
    case 'SET_PROGRAM':
      return action.program;

    case 'SET_METADATA':
      return { ...state, [action.field]: action.value };

    case 'SET_PHASES':
      return { ...state, phases: action.phases };

    case 'UPDATE_WEEK': {
      const weeks = [...state.weeks];
      weeks[action.weekIndex] = action.week;
      return { ...state, weeks };
    }

    case 'COPY_WEEK': {
      const weeks = [...state.weeks];
      const source = state.weeks[action.sourceIndex];
      const target = state.weeks[action.targetIndex];
      // Deep clone sessions/exercises from source, preserve target's week number and phaseId
      const clonedSessions = JSON.parse(JSON.stringify(source.sessions)) as ProgramSession[];
      // Update sessionIds to reflect target week
      clonedSessions.forEach((s, i) => {
        s.sessionId = `w${target.week}-s${i + 1}`;
      });
      weeks[action.targetIndex] = {
        ...target,
        sessions: clonedSessions,
        isTestWeek: source.isTestWeek,
      };
      return { ...state, weeks };
    }

    case 'ADD_SESSION': {
      const weeks = [...state.weeks];
      const week = state.weeks[action.weekIndex];
      const newSession = createEmptySession(week.week, week.sessions.length + 1);
      weeks[action.weekIndex] = {
        ...week,
        sessions: [...week.sessions, newSession],
      };
      return { ...state, weeks };
    }

    case 'REMOVE_SESSION': {
      const weeks = [...state.weeks];
      const week = state.weeks[action.weekIndex];
      weeks[action.weekIndex] = {
        ...week,
        sessions: week.sessions.filter((_, i) => i !== action.sessionIndex),
      };
      return { ...state, weeks };
    }

    case 'UPDATE_SESSION': {
      const weeks = [...state.weeks];
      const week = state.weeks[action.weekIndex];
      const sessions = [...week.sessions];
      sessions[action.sessionIndex] = action.session;
      weeks[action.weekIndex] = { ...week, sessions };
      return { ...state, weeks };
    }

    case 'SET_CYCLE_PROFILE':
      return { ...state, cycleAdjustmentProfile: action.profile };

    default:
      return state;
  }
}

const EMPTY_PROGRAM: ProgramFormData = {
  id: '',
  name: '',
  category: 'general',
  description: '',
  durationWeeks: 4,
  sessionsPerWeek: 3,
  difficulty: 'intermediate',
  status: 'draft',
  phases: [],
  weeks: [],
};

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

// --- Component ---

interface ProgramEditorProps {
  programId: string;
}

export default function ProgramEditor({ programId }: ProgramEditorProps) {
  const router = useRouter();
  const [state, dispatch] = useReducer(reducer, EMPTY_PROGRAM);
  const [selectedWeek, setSelectedWeek] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [showMetadata, setShowMetadata] = useState(false);

  const loadProgram = useCallback(async () => {
    try {
      setLoading(true);
      const program = await fetchProgramByID(programId);
      if (program) {
        dispatch({ type: 'SET_PROGRAM', program });
      } else {
        setMessage({ type: 'error', text: 'Program not found' });
      }
    } catch (err) {
      setMessage({ type: 'error', text: err instanceof Error ? err.message : 'Failed to load' });
    } finally {
      setLoading(false);
    }
  }, [programId]);

  useEffect(() => {
    loadProgram();
  }, [loadProgram]);

  async function handleSave(status: 'draft' | 'published') {
    setSaving(true);
    setMessage(null);
    try {
      await saveProgram({ ...state, status });
      dispatch({ type: 'SET_METADATA', field: 'status', value: status });
      setMessage({
        type: 'success',
        text: status === 'published' ? 'Published!' : 'Draft saved!',
      });
    } catch (err) {
      setMessage({ type: 'error', text: err instanceof Error ? err.message : 'Save failed' });
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!confirm(`Delete "${state.name}"? This cannot be undone.`)) return;
    setSaving(true);
    try {
      await deleteProgram(programId);
      router.push('/programs');
    } catch (err) {
      setMessage({ type: 'error', text: err instanceof Error ? err.message : 'Delete failed' });
      setSaving(false);
    }
  }

  function handleExportJSON() {
    const json = JSON.stringify(state, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${state.id}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const currentWeek = state.weeks[selectedWeek];

  if (loading) {
    return (
      <div className="text-center py-12 text-navy/60 flex flex-col items-center gap-2">
        <svg className="animate-spin h-6 w-6 text-orange" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        Loading program...
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <button
            onClick={() => router.push('/programs')}
            className="text-sm text-orange hover:underline mb-2 inline-flex items-center gap-1"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Programs
          </button>
          <h1 className="text-2xl font-bold text-navy">{state.name || 'Untitled Program'}</h1>
          <p className="text-sm text-navy/40">
            {state.id} &middot; {state.durationWeeks} weeks &middot; {state.sessionsPerWeek}x/week
            {state.startDate && state.endDate && (
              <span> &middot; {state.startDate} to {state.endDate}</span>
            )}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => router.push(`/programs/${programId}/preview`)}
            className="px-3 py-1.5 text-sm font-medium text-navy/60 border border-navy/15 rounded-md hover:text-navy hover:border-navy/30 transition-colors"
          >
            Preview
          </button>
          <span
            className={`px-3 py-1 rounded-full text-xs font-bold tracking-wider uppercase ${
              state.status === 'published'
                ? 'bg-green-100 text-green-700'
                : 'bg-yellow-100 text-yellow-700'
            }`}
          >
            {state.status}
          </span>
        </div>
      </div>

      {/* Message */}
      {message && (
        <div
          className={`mb-4 px-4 py-3 rounded-lg text-sm font-medium ${
            message.type === 'success'
              ? 'bg-green-50 text-green-700 border border-green-200'
              : 'bg-red-50 text-red-700 border border-red-200'
          }`}
        >
          {message.text}
        </div>
      )}

      {/* Metadata (collapsible) */}
      <details
        className="art-deco-card mb-4"
        open={showMetadata}
        onToggle={(e) => setShowMetadata((e.target as HTMLDetailsElement).open)}
      >
        <summary className="px-5 py-3 text-sm font-bold text-navy cursor-pointer hover:bg-cream-dark/20">
          Program Metadata
        </summary>
        <div className="px-5 pb-4 space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Name</label>
              <input
                type="text"
                value={state.name}
                onChange={(e) => dispatch({ type: 'SET_METADATA', field: 'name', value: e.target.value })}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Category</label>
              <select
                value={state.category}
                onChange={(e) => dispatch({ type: 'SET_METADATA', field: 'category', value: e.target.value })}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              >
                {CATEGORIES.map((c) => (
                  <option key={c.value} value={c.value}>{c.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-navy/60 mb-1">Description</label>
            <textarea
              value={state.description}
              onChange={(e) => dispatch({ type: 'SET_METADATA', field: 'description', value: e.target.value })}
              rows={2}
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Difficulty</label>
              <select
                value={state.difficulty}
                onChange={(e) => dispatch({ type: 'SET_METADATA', field: 'difficulty', value: e.target.value })}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              >
                {DIFFICULTIES.map((d) => (
                  <option key={d.value} value={d.value}>{d.label}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Sessions/Week</label>
              <input
                type="number"
                min={1}
                max={7}
                value={state.sessionsPerWeek}
                onChange={(e) => dispatch({ type: 'SET_METADATA', field: 'sessionsPerWeek', value: parseInt(e.target.value) || 3 })}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Duration (weeks)</label>
              <input
                type="number"
                value={state.durationWeeks}
                disabled
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream-dark/30 text-navy/60 text-sm"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Start Date (Sunday)</label>
              <input
                type="date"
                value={state.startDate || ''}
                onChange={(e) => {
                  const d = new Date(e.target.value + 'T00:00:00');
                  const day = d.getDay();
                  if (day !== 0) d.setDate(d.getDate() + (7 - day));
                  const sunday = d.toISOString().slice(0, 10);
                  dispatch({ type: 'SET_METADATA', field: 'startDate', value: sunday });
                  // Auto-calculate end date
                  const end = new Date(sunday + 'T00:00:00');
                  end.setDate(end.getDate() + (state.durationWeeks - 1) * 7);
                  dispatch({ type: 'SET_METADATA', field: 'endDate', value: end.toISOString().slice(0, 10) });
                }}
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">End Date (auto)</label>
              <input
                type="date"
                value={state.endDate || ''}
                disabled
                className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream-dark/30 text-navy/60 text-sm"
              />
              <p className="mt-1 text-xs text-navy/40">
                Users can make up missed workouts anytime during the program
              </p>
            </div>
          </div>
        </div>
      </details>

      {/* Phase Bar */}
      <div className="art-deco-card p-4 mb-4">
        <h3 className="text-sm font-bold text-navy mb-2">Phases</h3>
        <PhaseBar
          phases={state.phases}
          totalWeeks={state.durationWeeks}
          onChange={(phases) => dispatch({ type: 'SET_PHASES', phases })}
        />
      </div>

      {/* Week Tabs */}
      <div className="mb-4">
        <WeekTabs
          weeks={state.weeks}
          selectedWeek={selectedWeek}
          onSelectWeek={setSelectedWeek}
          onCopyWeek={(source, target) =>
            dispatch({ type: 'COPY_WEEK', sourceIndex: source, targetIndex: target })
          }
        />
      </div>

      {/* Selected week */}
      {currentWeek && (
        <div className="space-y-4 mb-4">
          {/* Week metadata */}
          <div className="flex items-center gap-3 px-1">
            <h2 className="text-lg font-bold text-navy">Week {currentWeek.week}</h2>
            {state.phases.length > 0 && (
              <select
                value={currentWeek.phaseId || ''}
                onChange={(e) =>
                  dispatch({
                    type: 'UPDATE_WEEK',
                    weekIndex: selectedWeek,
                    week: { ...currentWeek, phaseId: e.target.value || null },
                  })
                }
                className="px-2 py-1 border border-navy/20 rounded-md bg-white text-navy text-xs focus:outline-none focus:ring-2 focus:ring-orange"
              >
                <option value="">No phase</option>
                {state.phases.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            )}
            <label className="flex items-center gap-1.5 text-xs text-navy/60">
              <input
                type="checkbox"
                checked={currentWeek.isTestWeek || false}
                onChange={(e) =>
                  dispatch({
                    type: 'UPDATE_WEEK',
                    weekIndex: selectedWeek,
                    week: { ...currentWeek, isTestWeek: e.target.checked },
                  })
                }
                className="rounded border-navy/30"
              />
              Test Week
            </label>
          </div>

          {/* Sessions */}
          {currentWeek.sessions.map((session, i) => (
            <SessionCard
              key={session.sessionId}
              session={session}
              sessionIndex={i}
              onUpdate={(updated) =>
                dispatch({
                  type: 'UPDATE_SESSION',
                  weekIndex: selectedWeek,
                  sessionIndex: i,
                  session: updated,
                })
              }
              onRemove={() =>
                dispatch({
                  type: 'REMOVE_SESSION',
                  weekIndex: selectedWeek,
                  sessionIndex: i,
                })
              }
            />
          ))}

          <button
            onClick={() => dispatch({ type: 'ADD_SESSION', weekIndex: selectedWeek })}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-orange border border-orange/30 rounded-lg hover:bg-orange/10 transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Session
          </button>
        </div>
      )}

      {/* Cycle Adjustment */}
      <div className="mb-4">
        <CycleAdjustmentEditor
          profile={state.cycleAdjustmentProfile}
          onChange={(profile) => dispatch({ type: 'SET_CYCLE_PROFILE', profile })}
        />
      </div>

      {/* Preview JSON */}
      <details className="border border-navy/10 rounded-lg mb-4">
        <summary className="px-4 py-2 text-sm font-medium text-navy/60 cursor-pointer hover:text-navy">
          Preview JSON
        </summary>
        <pre className="px-4 py-3 text-xs text-navy/70 bg-cream-dark/20 overflow-x-auto rounded-b-lg max-h-96 overflow-y-auto">
          {JSON.stringify(state, null, 2)}
        </pre>
      </details>

      {/* Action bar */}
      <div className="flex items-center justify-between pt-4 border-t border-navy/10">
        <div className="flex items-center gap-3">
          <button
            onClick={() => handleSave('draft')}
            disabled={saving}
            className="px-5 py-2.5 bg-navy text-cream font-medium rounded-lg hover:bg-navy-light disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
          >
            {saving ? 'Saving...' : 'Save Draft'}
          </button>
          <button
            onClick={() => handleSave('published')}
            disabled={saving}
            className="px-5 py-2.5 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
          >
            {saving ? 'Publishing...' : 'Publish'}
          </button>
          <button
            onClick={handleExportJSON}
            className="px-4 py-2 text-navy/60 border border-navy/15 rounded-lg hover:text-navy hover:border-navy/30 transition-colors text-sm font-medium"
          >
            Export JSON
          </button>
        </div>
        <button
          onClick={handleDelete}
          disabled={saving}
          className="px-4 py-2 text-red-600 border border-red-200 rounded-lg hover:bg-red-50 disabled:opacity-40 transition-colors text-sm font-medium"
        >
          Delete
        </button>
      </div>
    </div>
  );
}
