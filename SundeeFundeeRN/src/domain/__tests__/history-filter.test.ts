/**
 * Tests for history filtering and date grouping.
 * Covers Plan 04-04 Task 1 behavior.
 */

import { filterHistoryBySource, groupHistoryByDate } from '../history/history-filter';
import type { HistorySourceFilter } from '../history/history-filter';
import type { HistoryItem, HistoryItemSource } from '../history/history-item';
import { getSourceLabel } from '../history/history-item';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function makeItem(
  id: string,
  source: HistoryItemSource,
  completedAt: Date
): HistoryItem {
  return {
    id,
    title: `Workout ${id}`,
    source,
    completedAt,
    exerciseCount: 3,
    durationSeconds: 1800,
    originalID: id,
    isAIWorkout: source.kind === 'aiWorkout',
  };
}

const now = new Date();
const yesterday = new Date(now);
yesterday.setDate(yesterday.getDate() - 1);
const twoDaysAgo = new Date(now);
twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);

const items: HistoryItem[] = [
  makeItem('1', { kind: 'aiWorkout' }, now),
  makeItem('2', { kind: 'program', name: 'GZCLP' }, now),
  makeItem('3', { kind: 'custom' }, yesterday),
  makeItem('4', { kind: 'aiWorkout' }, yesterday),
  makeItem('5', { kind: 'program', name: '531' }, twoDaysAgo),
];

// ---------------------------------------------------------------------------
// getSourceLabel
// ---------------------------------------------------------------------------

describe('getSourceLabel', () => {
  it('returns "AI Workout" for aiWorkout', () => {
    expect(getSourceLabel({ kind: 'aiWorkout' })).toBe('AI Workout');
  });

  it('returns program name for program source', () => {
    expect(getSourceLabel({ kind: 'program', name: 'GZCLP' })).toBe('GZCLP');
  });

  it('returns "Custom Workout" for custom source', () => {
    expect(getSourceLabel({ kind: 'custom' })).toBe('Custom Workout');
  });
});

// ---------------------------------------------------------------------------
// filterHistoryBySource
// ---------------------------------------------------------------------------

describe('filterHistoryBySource', () => {
  it('"all" returns all items unchanged', () => {
    expect(filterHistoryBySource(items, 'all')).toHaveLength(5);
  });

  it('"ai" returns only aiWorkout items', () => {
    const result = filterHistoryBySource(items, 'ai');
    expect(result).toHaveLength(2);
    result.forEach((item) => expect(item.source.kind).toBe('aiWorkout'));
  });

  it('"program" returns only program items', () => {
    const result = filterHistoryBySource(items, 'program');
    expect(result).toHaveLength(2);
    result.forEach((item) => expect(item.source.kind).toBe('program'));
  });

  it('"custom" returns only custom items', () => {
    const result = filterHistoryBySource(items, 'custom');
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe('3');
    result.forEach((item) => expect(item.source.kind).toBe('custom'));
  });

  it('returns empty array when no items match filter', () => {
    const noCustom: HistoryItem[] = [
      makeItem('a', { kind: 'aiWorkout' }, now),
    ];
    expect(filterHistoryBySource(noCustom, 'custom')).toHaveLength(0);
  });

  it('handles empty items array', () => {
    const filters: HistorySourceFilter[] = ['all', 'ai', 'program', 'custom'];
    filters.forEach((f) =>
      expect(filterHistoryBySource([], f)).toHaveLength(0)
    );
  });
});

// ---------------------------------------------------------------------------
// groupHistoryByDate
// ---------------------------------------------------------------------------

describe('groupHistoryByDate', () => {
  it('labels today as "Today"', () => {
    const groups = groupHistoryByDate([makeItem('x', { kind: 'aiWorkout' }, now)]);
    expect(groups[0].label).toBe('Today');
  });

  it('labels yesterday as "Yesterday"', () => {
    const groups = groupHistoryByDate([makeItem('y', { kind: 'custom' }, yesterday)]);
    expect(groups[0].label).toBe('Yesterday');
  });

  it('labels older dates with formatted date string', () => {
    const groups = groupHistoryByDate([makeItem('z', { kind: 'program', name: 'X' }, twoDaysAgo)]);
    expect(groups[0].label).not.toBe('Today');
    expect(groups[0].label).not.toBe('Yesterday');
    // Should be a non-empty string like "Mar 12"
    expect(groups[0].label.length).toBeGreaterThan(0);
  });

  it('groups items by same date into one section', () => {
    const sameDay1 = makeItem('a', { kind: 'aiWorkout' }, now);
    const sameDay2 = makeItem('b', { kind: 'custom' }, now);
    const groups = groupHistoryByDate([sameDay1, sameDay2]);
    expect(groups).toHaveLength(1);
    expect(groups[0].items).toHaveLength(2);
  });

  it('returns sections sorted most recent first', () => {
    const groups = groupHistoryByDate(items);
    const labels = groups.map((g) => g.label);
    expect(labels[0]).toBe('Today');
    expect(labels[1]).toBe('Yesterday');
  });

  it('returns empty array for empty input', () => {
    expect(groupHistoryByDate([])).toHaveLength(0);
  });

  it('items within a section are sorted most recent first', () => {
    const early = new Date(now);
    early.setHours(8, 0, 0, 0);
    const late = new Date(now);
    late.setHours(20, 0, 0, 0);
    const itemEarly = makeItem('early', { kind: 'aiWorkout' }, early);
    const itemLate = makeItem('late', { kind: 'aiWorkout' }, late);
    const groups = groupHistoryByDate([itemEarly, itemLate]);
    expect(groups[0].items[0].id).toBe('late');
    expect(groups[0].items[1].id).toBe('early');
  });
});
