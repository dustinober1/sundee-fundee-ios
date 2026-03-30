"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { FormAlert } from "@/components/ui/form-alert";
import { SectionHeader } from "@/components/ui/art-deco";
import { logPeriod } from "./actions";
import { getErrorMessage } from "@/lib/client-errors";

const FLOW_LEVELS = ["light", "medium", "heavy"] as const;
type FlowLevel = (typeof FLOW_LEVELS)[number];

const SYMPTOM_OPTIONS = [
  { value: "cramps", label: "Cramps" },
  { value: "headache", label: "Headache" },
  { value: "fatigue", label: "Fatigue" },
  { value: "bloating", label: "Bloating" },
  { value: "mood_changes", label: "Mood" },
  { value: "back_pain", label: "Back Pain" },
] as const;

export function LogPeriodForm() {
  const router = useRouter();
  const [startDate, setStartDate] = useState(() => new Date().toISOString().split("T")[0]);
  const [endDate, setEndDate] = useState("");
  const [flowLevel, setFlowLevel] = useState<FlowLevel>("medium");
  const [symptoms, setSymptoms] = useState<string[]>([]);
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function toggleSymptom(value: string) {
    setSymptoms((prev) =>
      prev.includes(value) ? prev.filter((s) => s !== value) : [...prev, value]
    );
  }

  async function handleSubmit() {
    setError(null);
    setSaving(true);
    try {
      await logPeriod({
        startDate,
        endDate: endDate || undefined,
        flowLevel,
        symptoms: symptoms.length > 0 ? symptoms : undefined,
        notes: notes || undefined,
      });
      setEndDate("");
      setFlowLevel("medium");
      setSymptoms([]);
      setNotes("");
      router.refresh();
    } catch (error) {
      setError(getErrorMessage(error));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <SectionHeader label="Journal" title="Log Period" />

      <div className="mt-4 space-y-4">
        {/* Dates */}
        <div className="flex gap-3">
          <div className="flex-1">
            <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
              Start Date
            </label>
            <Input
              type="date"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
            />
          </div>
          <div className="flex-1">
            <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
              End Date
            </label>
            <Input
              type="date"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              placeholder="Optional"
            />
          </div>
        </div>

        {/* Flow Level */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-2 block">
            Flow Level
          </label>
          <div className="grid grid-cols-3 gap-2">
            {FLOW_LEVELS.map((level) => (
              <button
                key={level}
                type="button"
                onClick={() => setFlowLevel(level)}
                className={`px-3 py-2.5 rounded-button text-[13px] font-medium border transition-all ${
                  flowLevel === level
                    ? "bg-orange text-cream border-orange shadow-sm shadow-orange/20"
                    : "bg-card-bg text-navy border-gold/15 hover:border-gold/40"
                }`}
              >
                {level.charAt(0).toUpperCase() + level.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Symptoms */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-2 block">
            Symptoms
          </label>
          <div className="flex flex-wrap gap-2">
            {SYMPTOM_OPTIONS.map((symptom) => (
              <button
                key={symptom.value}
                type="button"
                onClick={() => toggleSymptom(symptom.value)}
                className={`px-3 py-1.5 rounded-full text-[12px] font-medium border transition-all ${
                  symptoms.includes(symptom.value)
                    ? "bg-orange text-cream border-orange"
                    : "bg-card-bg text-text-secondary border-gold/15 hover:border-gold/40"
                }`}
              >
                {symptom.label}
              </button>
            ))}
          </div>
        </div>

        {/* Notes */}
        <div>
          <label className="text-[11px] font-mono text-text-secondary uppercase tracking-wider mb-1 block">
            Notes
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Optional notes..."
            rows={2}
            className="w-full px-3.5 py-3 bg-card-bg border border-separator rounded-sm text-navy text-[15px] placeholder:text-text-secondary/50 focus:outline-none focus:ring-2 focus:ring-orange/40 focus:border-orange resize-none"
          />
        </div>

        {error && <FormAlert message={error} />}

        <Button fullWidth disabled={saving || !startDate} onClick={handleSubmit}>
          {saving ? "Saving..." : "Log Period"}
        </Button>
      </div>
    </Card>
  );
}
