"use client";

import { useState, useRef } from "react";
import {
  weightliftingExercises,
  conditioningExercises,
} from "@/lib/exercise-catalog";

type GroupedExercises = Record<string, string[]>;

const CATEGORY_ORDER = [
  "Squat",
  "Hip Hinge",
  "Press",
  "Pull",
  "Carry",
  "Olympic Weightlifting",
  "Conditioning (Reps)",
  "Conditioning (Time)",
];

function buildGrouped(): GroupedExercises {
  const groups: GroupedExercises = {};

  for (const ex of weightliftingExercises) {
    if (!groups[ex.category]) groups[ex.category] = [];
    groups[ex.category].push(ex.name);
  }

  for (const ex of conditioningExercises) {
    const category =
      ex.scoring === "Reps" ? "Conditioning (Reps)" : "Conditioning (Time)";
    if (!groups[category]) groups[category] = [];
    groups[category].push(ex.name);
  }

  return groups;
}

const ALL_GROUPED = buildGrouped();

interface Props {
  value: string;
  onChange: (value: string) => void;
}

export function ExerciseAutocomplete({ value, onChange }: Props) {
  const [open, setOpen] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const query = value.toLowerCase();

  const filteredGroups: GroupedExercises = {};
  for (const category of CATEGORY_ORDER) {
    const names = ALL_GROUPED[category] ?? [];
    const matches = query
      ? names.filter((name) => name.toLowerCase().includes(query))
      : names;
    if (matches.length > 0) {
      filteredGroups[category] = matches;
    }
  }

  const hasResults = Object.keys(filteredGroups).length > 0;

  return (
    <div className="relative">
      <input
        ref={inputRef}
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
        placeholder="Exercise name"
        className="w-full px-3 py-2 bg-white border border-navy/20 rounded text-navy placeholder:text-navy/40 focus:outline-none focus:ring-2 focus:ring-orange/40"
      />

      {open && hasResults && (
        <div className="absolute z-50 mt-1 w-full bg-white border border-navy/20 rounded shadow-lg max-h-72 overflow-y-auto">
          {CATEGORY_ORDER.filter((cat) => filteredGroups[cat]).map(
            (category) => (
              <div key={category}>
                <div className="px-3 pt-2 pb-1 text-xs font-semibold uppercase tracking-wide text-navy/50">
                  {category}
                </div>
                {filteredGroups[category].map((name) => (
                  <div
                    key={name}
                    onMouseDown={(e) => {
                      e.preventDefault();
                      onChange(name);
                      setOpen(false);
                    }}
                    className="px-3 py-2 cursor-pointer text-navy hover:bg-orange/10"
                  >
                    {name}
                  </div>
                ))}
              </div>
            )
          )}
        </div>
      )}
    </div>
  );
}
