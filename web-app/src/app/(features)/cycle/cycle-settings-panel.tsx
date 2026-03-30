"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { SectionHeader } from "@/components/ui/art-deco";
import { saveCycleSettings } from "./actions";

interface CycleSettingsPanelProps {
  initialCycleLength: number;
  initialPeriodLength: number;
  initialLutealLength: number;
}

export function CycleSettingsPanel({
  initialCycleLength,
  initialPeriodLength,
  initialLutealLength,
}: CycleSettingsPanelProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [cycleLength, setCycleLength] = useState(initialCycleLength);
  const [periodLength, setPeriodLength] = useState(initialPeriodLength);
  const [lutealLength, setLutealLength] = useState(initialLutealLength);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    try {
      await saveCycleSettings({
        averageCycleLengthDays: cycleLength,
        averagePeriodLengthDays: periodLength,
        lutealPhaseLengthDays: lutealLength,
      });
      router.refresh();
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <button
        type="button"
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between"
      >
        <SectionHeader label="Configuration" title="Cycle Settings" />
        <svg
          className={`w-4 h-4 text-text-secondary transition-transform ${open ? "rotate-180" : ""}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {open && (
        <div className="mt-4 space-y-5">
          <SliderField
            label="Cycle Length"
            value={cycleLength}
            min={21}
            max={45}
            unit="days"
            onChange={setCycleLength}
          />
          <SliderField
            label="Period Length"
            value={periodLength}
            min={2}
            max={10}
            unit="days"
            onChange={setPeriodLength}
          />
          <SliderField
            label="Luteal Phase"
            value={lutealLength}
            min={8}
            max={18}
            unit="days"
            onChange={setLutealLength}
          />
          <Button fullWidth disabled={saving} onClick={handleSave}>
            {saving ? "Saving..." : "Save Settings"}
          </Button>
        </div>
      )}
    </Card>
  );
}

function SliderField({
  label,
  value,
  min,
  max,
  unit,
  onChange,
}: {
  label: string;
  value: number;
  min: number;
  max: number;
  unit: string;
  onChange: (v: number) => void;
}) {
  return (
    <div>
      <div className="flex justify-between text-[13px] mb-2">
        <span className="text-navy">{label}</span>
        <span className="font-mono text-orange font-bold">
          {value} {unit}
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        value={value}
        onChange={(e) => onChange(parseInt(e.target.value))}
        className="w-full accent-orange"
      />
    </div>
  );
}
