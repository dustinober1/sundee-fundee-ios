/**
 * History source filtering and date grouping.
 * Pure functions — no storage access.
 */

import { isToday, isYesterday, format } from 'date-fns';
import type { HistoryItem } from './history-item';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type HistorySourceFilter = 'all' | 'ai' | 'program' | 'custom';

export interface HistoryDateGroup {
  label: string;
  items: HistoryItem[];
}

// ---------------------------------------------------------------------------
// filterHistoryBySource
// ---------------------------------------------------------------------------

/**
 * Filters a list of history items by source kind.
 * 'all' returns the list unchanged.
 */
export function filterHistoryBySource(
  items: HistoryItem[],
  filter: HistorySourceFilter
): HistoryItem[] {
  if (filter === 'all') return items;

  const kindMap: Record<Exclude<HistorySourceFilter, 'all'>, string> = {
    ai: 'aiWorkout',
    program: 'program',
    custom: 'custom',
  };

  const targetKind = kindMap[filter];
  return items.filter((item) => item.source.kind === targetKind);
}

// ---------------------------------------------------------------------------
// groupHistoryByDate
// ---------------------------------------------------------------------------

/**
 * Groups history items into date sections with human-readable labels.
 * Labels: 'Today', 'Yesterday', or formatted date (e.g. 'Mar 12').
 * Sections are sorted most recent first.
 * Items within each section are sorted most recent first.
 */
export function groupHistoryByDate(items: HistoryItem[]): HistoryDateGroup[] {
  if (items.length === 0) return [];

  // Group by calendar date string (YYYY-MM-DD)
  const groups = new Map<string, HistoryItem[]>();

  for (const item of items) {
    const dateKey = toDateKey(item.completedAt);
    const bucket = groups.get(dateKey);
    if (bucket) {
      bucket.push(item);
    } else {
      groups.set(dateKey, [item]);
    }
  }

  // Sort keys descending (most recent first)
  const sortedKeys = Array.from(groups.keys()).sort((a, b) =>
    b.localeCompare(a)
  );

  return sortedKeys.map((key) => {
    const sectionItems = groups.get(key)!;

    // Sort items within the section most recent first
    sectionItems.sort(
      (a, b) => b.completedAt.getTime() - a.completedAt.getTime()
    );

    return {
      label: toDateLabel(new Date(key + 'T12:00:00')),
      items: sectionItems,
    };
  });
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

function toDateKey(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function toDateLabel(date: Date): string {
  if (isToday(date)) return 'Today';
  if (isYesterday(date)) return 'Yesterday';
  return format(date, 'MMM d');
}
