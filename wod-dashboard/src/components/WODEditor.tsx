'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { WOD, WODFormData, TemplateType, ProgramExercise } from '@/types/wod';
import { fetchWODByID, saveWOD, deleteWOD } from '@/lib/wod-service';
import { parseWorkoutText } from '@/lib/workout-parser';
import { generateWorkout, isStructuredInput } from '@/lib/ai-generate';
import TemplateForm from './TemplateForm';

const TEMPLATE_OPTIONS: { value: TemplateType; label: string }[] = [
  { value: 'strength', label: 'Strength' },
  { value: 'amrap', label: 'AMRAP' },
  { value: 'emom', label: 'EMOM' },
  { value: 'forTime', label: 'For Time' },
  { value: 'circuit', label: 'Circuit' },
];

function emptyFormData(date: string): WODFormData {
  return {
    date,
    title: '',
    description: '',
    templateType: 'strength',
    publishDate: date,
    status: 'draft',
    exercises: [],
  };
}

interface WODEditorProps {
  date: string;
}

export default function WODEditor({ date }: WODEditorProps) {
  const router = useRouter();
  const [formData, setFormData] = useState<WODFormData>(emptyFormData(date));
  const [inputText, setInputText] = useState('');
  const [isExisting, setIsExisting] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [modeOverride, setModeOverride] = useState<'auto' | 'parser' | 'ai'>('auto');

  const detectedMode = inputText.trim()
    ? isStructuredInput(inputText)
      ? 'parser'
      : 'ai'
    : null;

  const inputMode = modeOverride === 'auto' ? detectedMode : (inputText.trim() ? modeOverride : null);
  const effectiveMode = inputMode; // Used for generate logic

  const loadExisting = useCallback(async () => {
    try {
      setLoading(true);
      const recordName = `wod-${date}`;
      const existing = await fetchWODByID(recordName);
      if (existing) {
        setFormData({
          date: existing.date,
          title: existing.title,
          description: existing.description,
          templateType: existing.templateType,
          publishDate: existing.publishDate,
          status: existing.status,
          exercises: existing.exercises,
        });
        setIsExisting(true);
      }
    } catch {
      // No existing WOD, that's fine
    } finally {
      setLoading(false);
    }
  }, [date]);

  useEffect(() => {
    loadExisting();
  }, [loadExisting]);

  const handleGenerate = async () => {
    if (!inputText.trim()) return;
    setGenerating(true);
    setMessage(null);
    try {
      if (effectiveMode === 'parser') {
        // Use parser
        const parsed = parseWorkoutText(inputText);
        const exercises: ProgramExercise[] = parsed.exercises.map((ex) => ({
          exercise: ex.exercise,
          variant: ex.variant ?? null,
          sets: ex.sets,
          reps: ex.reps,
          percent1RM: ex.percent1RM ?? null,
          restMinutes: ex.restMinutes ?? null,
          notes: ex.notes ?? null,
          bodyweightOnly: ex.bodyweightOnly,
        }));
        setFormData((prev) => ({
          ...prev,
          templateType: parsed.templateType,
          timeCap: parsed.timeCap,
          exercises,
        }));
        setMessage({ type: 'success', text: 'Parsed successfully!' });
      } else {
        // Use AI
        const generated = await generateWorkout(inputText);
        setFormData((prev) => ({
          ...prev,
          ...generated,
          date: prev.date,
          publishDate: prev.publishDate,
          status: prev.status,
        }));
        setMessage({ type: 'success', text: 'Generated with AI!' });
      }
    } catch (err) {
      setMessage({
        type: 'error',
        text: err instanceof Error ? err.message : 'Generation failed',
      });
    } finally {
      setGenerating(false);
    }
  };

  const handleSave = async (status: 'draft' | 'published') => {
    if (!formData.title.trim()) {
      setMessage({ type: 'error', text: 'Title is required' });
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      await saveWOD({ ...formData, status });
      setIsExisting(true);
      setFormData((prev) => ({ ...prev, status }));
      setMessage({
        type: 'success',
        text: status === 'published' ? 'Published!' : 'Draft saved!',
      });
    } catch (err) {
      setMessage({
        type: 'error',
        text: err instanceof Error ? err.message : 'Save failed',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm('Delete this WOD? This cannot be undone.')) return;
    setSaving(true);
    try {
      await deleteWOD(`wod-${date}`);
      router.push('/');
    } catch (err) {
      setMessage({
        type: 'error',
        text: err instanceof Error ? err.message : 'Delete failed',
      });
      setSaving(false);
    }
  };

  const formatDisplayDate = (dateStr: string) => {
    const [year, month, day] = dateStr.split('-').map(Number);
    const d = new Date(year, month - 1, day);
    return d.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  if (loading) {
    return (
      <div className="text-center py-12 text-navy/60 flex flex-col items-center gap-2">
        <svg className="animate-spin h-6 w-6 text-orange" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        Loading...
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <button
            onClick={() => router.push('/')}
            className="text-sm text-orange hover:underline mb-2 inline-flex items-center gap-1"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Calendar
          </button>
          <h1 className="text-2xl font-bold text-navy">
            {isExisting ? 'Edit WOD' : 'New WOD'}
          </h1>
          <p className="text-navy/60 text-sm">{formatDisplayDate(date)}</p>
        </div>
        {isExisting && (
          <span
            className={`px-3 py-1 rounded-full text-xs font-bold tracking-wider uppercase ${
              formData.status === 'published'
                ? 'bg-green-100 text-green-700'
                : 'bg-yellow-100 text-yellow-700'
            }`}
          >
            {formData.status}
          </span>
        )}
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

      {/* Text input + Generate */}
      <div className="art-deco-card p-5 mb-6">
        <div className="flex items-center justify-between mb-3">
          <label className="block text-sm font-bold text-navy">
            Quick Input
          </label>
          <div className="flex items-center gap-2">
            {/* Mode toggle */}
            <div className="flex items-center bg-cream-dark/50 rounded-lg p-0.5 text-xs font-medium">
              {(['auto', 'parser', 'ai'] as const).map((mode) => (
                <button
                  key={mode}
                  onClick={() => setModeOverride(mode)}
                  className={`px-2.5 py-1 rounded-md transition-colors capitalize ${
                    modeOverride === mode
                      ? mode === 'ai'
                        ? 'bg-orange text-cream'
                        : 'bg-navy text-cream'
                      : 'text-navy/60 hover:text-navy'
                  }`}
                >
                  {mode}
                </button>
              ))}
            </div>
            {/* Active mode indicator */}
            {inputMode && (
              <span
                className={`px-2 py-0.5 rounded text-xs font-bold tracking-wider ${
                  inputMode === 'parser'
                    ? 'bg-navy text-cream'
                    : 'bg-orange text-cream'
                }`}
              >
                {inputMode === 'parser' ? 'PARSER' : 'AI'}
              </span>
            )}
          </div>
        </div>
        <textarea
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          placeholder={'Type structured workout (e.g. "5x5 Back Squat 75%, 3x10 RDL")\nor a natural language prompt (e.g. "full body strength day focusing on posterior chain")'}
          rows={4}
          className="w-full px-3 py-2 border border-navy/20 rounded-md bg-cream/30 text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
        />
        <button
          onClick={handleGenerate}
          disabled={!inputText.trim() || generating}
          className="mt-2 px-4 py-2 bg-orange text-cream font-medium rounded-md hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm inline-flex items-center gap-2"
        >
          {generating && (
            <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
          )}
          {generating ? 'Generating...' : inputMode === 'parser' ? 'Parse Workout' : inputMode === 'ai' ? 'Generate with AI' : 'Generate'}
        </button>
      </div>

      {/* Form */}
      <div className="art-deco-card p-5 space-y-5">
        {/* Title & Description */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-navy mb-1">Title *</label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g. Heavy Squat Day"
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-navy mb-1">Publish Date</label>
            <input
              type="date"
              value={formData.publishDate}
              onChange={(e) => setFormData({ ...formData, publishDate: e.target.value })}
              className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-navy mb-1">Description</label>
          <textarea
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Workout description..."
            rows={2}
            className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange resize-none"
          />
        </div>

        {/* Template Type */}
        <div>
          <label className="block text-sm font-medium text-navy mb-2">Template Type</label>
          <div className="flex flex-wrap gap-2">
            {TEMPLATE_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setFormData({ ...formData, templateType: opt.value })}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors border ${
                  formData.templateType === opt.value
                    ? 'bg-navy text-cream border-navy'
                    : 'bg-white text-navy border-navy/20 hover:border-orange hover:text-orange'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* Template-specific form */}
        <TemplateForm formData={formData} onChange={setFormData} />

        {/* Preview */}
        {formData.exercises.length > 0 && (
          <details className="border border-navy/10 rounded-lg">
            <summary className="px-4 py-2 text-sm font-medium text-navy/60 cursor-pointer hover:text-navy">
              Preview JSON
            </summary>
            <pre className="px-4 py-3 text-xs text-navy/70 bg-cream-dark/20 overflow-x-auto rounded-b-lg">
              {JSON.stringify(formData, null, 2)}
            </pre>
          </details>
        )}

        {/* Action buttons */}
        <div className="flex items-center justify-between pt-4 border-t border-navy/10">
          <div className="flex items-center gap-3">
            <button
              onClick={() => handleSave('draft')}
              disabled={saving || !formData.title.trim()}
              className="px-5 py-2.5 bg-navy text-cream font-medium rounded-lg hover:bg-navy-light disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
            >
              {saving ? 'Saving...' : 'Save Draft'}
            </button>
            <button
              onClick={() => handleSave('published')}
              disabled={saving || !formData.title.trim()}
              className="px-5 py-2.5 bg-orange text-cream font-medium rounded-lg hover:bg-orange/90 disabled:opacity-40 disabled:cursor-not-allowed transition-colors text-sm"
            >
              {saving ? 'Publishing...' : 'Publish'}
            </button>
          </div>
          {isExisting && (
            <button
              onClick={handleDelete}
              disabled={saving}
              className="px-4 py-2 text-red-600 border border-red-200 rounded-lg hover:bg-red-50 disabled:opacity-40 transition-colors text-sm font-medium"
            >
              Delete
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
