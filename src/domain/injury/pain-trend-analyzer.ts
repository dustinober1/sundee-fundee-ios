/**
 * pain-trend-analyzer.ts
 * Pure pain trend analysis — no framework dependencies.
 * Ported from Swift PainTrendAnalyzer.swift.
 *
 * CRITICAL: The prefix/suffix splitting pattern must match Swift exactly.
 * recent = logs.slice(0, windowSize)         → logs.prefix(windowSize)
 * newerHalf = recent.slice(0, halfSize)       → recent.prefix(halfSize)
 * olderHalf = recent.slice(recent.length - halfSize) → recent.suffix(halfSize)
 */

import { PainLog } from '../types';

export interface TrendResult {
  trailingAverage: number;
  isImproving: boolean;
  latestPainLevel: number | null;
  readingCount: number;
}

/**
 * Computes a pain trend from logs sorted newest-first.
 *
 * @param logs Pain logs for a single injury, sorted newest first.
 * @param windowSize Number of recent readings to consider (default 7).
 */
export function analyzeTrend(logs: PainLog[], windowSize = 7): TrendResult {
  if (logs.length === 0) {
    return {
      trailingAverage: 0,
      isImproving: false,
      latestPainLevel: null,
      readingCount: 0,
    };
  }

  // logs.prefix(windowSize) — take up to windowSize from the start (newest)
  const recent = logs.slice(0, windowSize);
  const average = recent.reduce((sum, l) => sum + l.painLevel, 0) / recent.length;
  const latest = logs[0].painLevel;

  let improving = false;
  if (recent.length >= 2) {
    const halfSize = Math.floor(recent.length / 2);
    // newer half: prefix(halfSize) — first halfSize elements (most recent)
    const newerHalf = recent.slice(0, halfSize);
    // older half: suffix(halfSize) — last halfSize elements (oldest in window)
    const olderHalf = recent.slice(recent.length - halfSize);
    const newerAvg = newerHalf.reduce((sum, l) => sum + l.painLevel, 0) / newerHalf.length;
    const olderAvg = olderHalf.reduce((sum, l) => sum + l.painLevel, 0) / olderHalf.length;
    improving = newerAvg < olderAvg;
  }

  return {
    trailingAverage: average,
    isImproving: improving,
    latestPainLevel: latest,
    readingCount: logs.length,
  };
}

/**
 * Returns true if a pain log has been recorded within the last `hours` hours.
 * Logs must be sorted newest-first.
 */
export function hasRecentLog(logs: PainLog[], hours = 24): boolean {
  if (logs.length === 0) return false;
  const latest = logs[0];
  const ageMs = Date.now() - latest.date.getTime();
  return ageMs < hours * 3600 * 1000;
}

/**
 * Returns the last N pain levels for sparkline display (oldest to newest).
 * Matches Swift PainTrendAnalyzer.sparklineData(logs:count:).
 */
export function sparklineData(logs: PainLog[], count = 7): number[] {
  return logs.slice(0, count).reverse().map(l => l.painLevel);
}
