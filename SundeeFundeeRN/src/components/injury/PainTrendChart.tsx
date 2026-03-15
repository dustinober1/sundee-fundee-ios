/**
 * PainTrendChart.tsx — Pain trend sparkline chart for injury profile.
 *
 * Uses react-native-gifted-charts LineChart.
 * Shows pain level (1-10) over time with a trend indicator.
 *
 * Art Deco styling: navy line, cream background, orange data points.
 *
 * Props:
 *   painLogs: PainLogRecord[]  — sorted newest-first from InjuryRepo
 *   trendResult: TrendResult   — from analyzeTrend(domainLogs)
 */

import React from 'react';
import { View, Text, StyleSheet, useWindowDimensions } from 'react-native';
import { LineChart } from 'react-native-gifted-charts';
import type { PainLogRecord } from '@/src/repositories/InjuryRepo';
import type { TrendResult } from '@/src/domain/injury/pain-trend-analyzer';
import * as colors from '@/src/theme/colors';

// ─── Props ────────────────────────────────────────────────────────────────────

interface PainTrendChartProps {
  painLogs: PainLogRecord[];
  trendResult: TrendResult;
}

// ─── Trend indicator helpers ──────────────────────────────────────────────────

/**
 * Returns a human-readable trend direction label.
 */
export function trendDirectionLabel(result: TrendResult): string {
  if (result.readingCount === 0) return 'No data';
  if (result.readingCount < 2) return 'Tracking...';
  return result.isImproving ? 'Improving' : 'Worsening or Stable';
}

/**
 * Returns the color for the trend indicator.
 */
export function trendIndicatorColor(result: TrendResult): string {
  if (result.readingCount < 2) return colors.GREY;
  return result.isImproving ? '#2A9D4A' : colors.ORANGE_DARK;
}

// ─── Chart data helpers ───────────────────────────────────────────────────────

interface GiftedDataPoint {
  value: number;
  label?: string;
  dataPointColor?: string;
  dataPointRadius?: number;
}

/**
 * Converts PainLogRecord[] (newest-first) to gifted-charts format (oldest-first for display).
 * Adds date labels at even intervals.
 */
export function toChartData(logs: PainLogRecord[]): GiftedDataPoint[] {
  // Display oldest → newest
  const ordered = [...logs].reverse();
  const MAX_LABELS = 5;
  const step = ordered.length <= MAX_LABELS ? 1 : Math.ceil(ordered.length / MAX_LABELS);

  return ordered.map((log, i) => {
    const date = new Date(log.date);
    const label =
      i % step === 0
        ? date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        : undefined;
    return {
      value: log.painLevel,
      label,
      dataPointColor: colors.ORANGE,
      dataPointRadius: 4,
    };
  });
}

// ─── Component ────────────────────────────────────────────────────────────────

export function PainTrendChart({
  painLogs,
  trendResult,
}: PainTrendChartProps): React.JSX.Element {
  const { width } = useWindowDimensions();
  const chartWidth = Math.max(width - 64, 200);

  const trendLabel = trendDirectionLabel(trendResult);
  const trendColor = trendIndicatorColor(trendResult);
  const trendArrow = trendResult.readingCount >= 2
    ? trendResult.isImproving ? ' ↓' : ' ↑'
    : '';

  if (painLogs.length === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.titleRow}>
          <Text style={styles.chartTitle}>Pain Trend</Text>
        </View>
        <View style={styles.emptyInner}>
          <Text style={styles.emptyText}>No pain logs yet</Text>
          <Text style={styles.emptySubtext}>Log your pain level to track progress.</Text>
        </View>
      </View>
    );
  }

  const chartData = toChartData(painLogs);
  const latestPain = trendResult.latestPainLevel;

  return (
    <View style={styles.container}>
      <View style={styles.titleRow}>
        <Text style={styles.chartTitle}>Pain Trend</Text>
        <View style={[styles.trendBadge, { backgroundColor: trendColor + '22', borderColor: trendColor }]}>
          <Text style={[styles.trendText, { color: trendColor }]}>
            {trendLabel}{trendArrow}
          </Text>
        </View>
      </View>

      {latestPain !== null && (
        <Text style={styles.latestPain}>
          Latest: <Text style={styles.latestPainValue}>{latestPain}/10</Text>
        </Text>
      )}

      <LineChart
        data={chartData}
        width={chartWidth}
        height={160}
        // Line styling: navy line for pain
        color={colors.NAVY}
        thickness={2.5}
        // Area fill
        areaChart
        startFillColor={colors.NAVY}
        startOpacity={0.12}
        endFillColor={colors.NAVY}
        endOpacity={0.02}
        // Data points
        dataPointsColor={colors.ORANGE}
        dataPointsRadius={4}
        // Axes
        yAxisColor={colors.NAVY_MEDIUM}
        xAxisColor={colors.NAVY_MEDIUM}
        yAxisTextStyle={{ color: colors.NAVY_MEDIUM, fontSize: 11 }}
        xAxisLabelTextStyle={{ color: colors.NAVY_MEDIUM, fontSize: 10 }}
        // Grid
        showVerticalLines={false}
        rulesColor="#E8E4D6"
        rulesType="solid"
        // Y axis range: pain is 1-10
        minValue={0}
        maxValue={10}
        noOfSections={5}
        // Curved line
        curved
        backgroundColor="transparent"
        // Pointer
        focusEnabled
        showDataPointOnFocus
        showStripOnFocus
        stripColor={colors.NAVY}
        stripOpacity={0.15}
        focusedDataPointColor={colors.NAVY_DARK}
        focusedDataPointRadius={6}
      />
      <Text style={styles.yAxisLabel}>Pain Level (1-10)</Text>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E4D6',
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  chartTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
  trendBadge: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  trendText: {
    fontSize: 12,
    fontWeight: '700',
  },
  latestPain: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    marginBottom: 10,
  },
  latestPainValue: {
    fontWeight: '700',
    color: colors.NAVY,
  },
  emptyInner: {
    height: 100,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  emptyText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.NAVY_MEDIUM,
  },
  emptySubtext: {
    fontSize: 13,
    color: colors.GREY,
    textAlign: 'center',
  },
  yAxisLabel: {
    fontSize: 11,
    color: colors.NAVY_MEDIUM,
    marginTop: 4,
    textAlign: 'right',
  },
});
