'use client';

import { useState, useRef, useEffect } from 'react';
import { ALL_EXERCISES, EXERCISE_CATALOG, CATEGORY_LABELS, ExerciseCategory } from '@/data/exercise-catalog';

interface ExercisePickerProps {
  value: string;
  onChange: (exercise: string) => void;
}

export default function ExercisePicker({ value, onChange }: ExercisePickerProps) {
  const [query, setQuery] = useState(value);
  const [isOpen, setIsOpen] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(0);
  const wrapperRef = useRef<HTMLDivElement>(null);

  const filtered = query.trim()
    ? ALL_EXERCISES.filter((e) =>
        e.toLowerCase().includes(query.toLowerCase())
      )
    : ALL_EXERCISES;

  // Determine which category an exercise belongs to
  function getCategory(exercise: string): string | null {
    for (const [cat, exercises] of Object.entries(EXERCISE_CATALOG)) {
      if ((exercises as readonly string[]).includes(exercise)) {
        return CATEGORY_LABELS[cat as ExerciseCategory];
      }
    }
    return null;
  }

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Sync external value changes
  useEffect(() => {
    setQuery(value);
  }, [value]);

  const handleSelect = (exercise: string) => {
    setQuery(exercise);
    onChange(exercise);
    setIsOpen(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!isOpen) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlightedIndex((prev) => Math.min(prev + 1, filtered.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlightedIndex((prev) => Math.max(prev - 1, 0));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filtered[highlightedIndex]) {
        handleSelect(filtered[highlightedIndex]);
      }
    } else if (e.key === 'Escape') {
      setIsOpen(false);
    }
  };

  return (
    <div ref={wrapperRef} className="relative">
      <input
        type="text"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setIsOpen(true);
          setHighlightedIndex(0);
        }}
        onFocus={() => setIsOpen(true)}
        onKeyDown={handleKeyDown}
        placeholder="Search exercises..."
        className="w-full px-3 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange focus:border-transparent"
      />
      {isOpen && filtered.length > 0 && (
        <ul className="absolute z-50 w-full mt-1 max-h-60 overflow-y-auto bg-white border border-navy/20 rounded-md shadow-lg">
          {filtered.slice(0, 50).map((exercise, idx) => {
            const category = getCategory(exercise);
            return (
              <li
                key={exercise}
                onClick={() => handleSelect(exercise)}
                className={`px-3 py-2 text-sm cursor-pointer flex items-center justify-between ${
                  idx === highlightedIndex
                    ? 'bg-orange/10 text-navy'
                    : 'text-navy hover:bg-cream-dark/50'
                }`}
              >
                <span>{exercise}</span>
                {category && (
                  <span className="text-[10px] text-navy/40 font-medium uppercase tracking-wider">
                    {category}
                  </span>
                )}
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
