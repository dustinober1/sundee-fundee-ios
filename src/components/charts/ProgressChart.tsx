/**
 * ProgressChart.tsx — Line chart wrapper for 1RM and volume progress visualization.
 *
 * Uses react-native-gifted-charts LineChart.
 * Art Deco theming: ORANGE line, CREAM_LIGHT area, NAVY axis labels.
 *
 * Handles empty data with a "No data yet" message.
 * Fills available container width responsively.
 */

import React from 'react';
import { View, Text, StyleSheet, useWindowDimensions } from 'react-native';
import { LineChart } from 'react-native-gifted-charts';
import type { ChartDataPoint } from '@/src/domain/progress/progress-data';
import * as colors from '@/src/theme/colors';

interface ProgressChartProps {
  data: ChartDataPoint[];
  /** Optional label for the y-axis unit (e.g. "lbs", "volume"). */
  yLabel?: string;
  /** Optional title shown above chart. */
  title?: string;
}

interface GiftedLineDataPoint {
  value: number;
  label?: string;
  dataPointColor?: string;
  dataPointRadius?: number;
}

/**
 * Converts ChartDataPoint[] to gifted-charts format.
 * Shows abbreviated date labels (e.g. "Mar 5") at even intervals when many points.
 */
function toGiftedData(points: ChartDataPoint[]): GiftedLineDataPoint[] {
  const MAX_LABELS = 5;
  const step = points.length <= MAX_LABELS ? 1 : Math.ceil(points.length / MAX_LABELS);

  return points.map((p, i) => {
    const label =
      i % step === 0 ? formatDateLabel(p.date) : undefined;
    return {
      value: p.value,
      label,
      dataPointColor: colors.ORANGE,
      dataPointRadius: 4,
    };
  });
}

function formatDateLabel(dateStr: string): string {
  // dateStr is YYYY-MM-DD
  const date = new Date(dateStr + 'T12:00:00');
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function ProgressChart({
  data,
  yLabel,
  title,
}: ProgressChartProps): React.JSX.Element {
  const { width } = useWindowDimensions();
  const chartWidth = Math.max(width - 48, 200);

  if (data.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        {title !== undefined && <Text style={styles.chartTitle}>{title}</Text>}
        <View style={styles.emptyInner}>
          <Text style={styles.emptyText}>No data yet</Text>
          <Text style={styles.emptySubtext}>Complete workouts to see progress here.</Text>
        </View>
      </View>
    );
  }

  const giftedData = toGiftedData(data);
  const maxValue = Math.max(...data.map((p) => p.value));
  const yAxisMax = Math.ceil(maxValue * 1.1);

  return (
    <View style={styles.container}>
      {title !== undefined && <Text style={styles.chartTitle}>{title}</Text>}

      <LineChart
        data={giftedData}
        width={chartWidth}
        height={180}
        // Line styling
        color={colors.ORANGE}
        thickness={2.5}
        // Area fill
        areaChart
        startFillColor={colors.ORANGE}
        startOpacity={0.18}
        endFillColor={colors.ORANGE}
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
        // Y axis range
        maxValue={yAxisMax}
        // Curved line
        curved
        // No built-in background (we provide our own)
        backgroundColor="transparent"
        // Pointer
        focusEnabled
        showDataPointOnFocus
        showStripOnFocus
        stripColor={colors.ORANGE}
        stripOpacity={0.2}
        focusedDataPointColor={colors.ORANGE_DARK}
        focusedDataPointRadius={6}
      />

      {yLabel !== undefined && (
        <Text style={styles.yLabel}>{yLabel}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E4D6',
  },
  emptyContainer: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8E4D6',
  },
  chartTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
    marginBottom: 12,
  },
  emptyInner: {
    height: 120,
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
  yLabel: {
    fontSize: 11,
    color: colors.NAVY_MEDIUM,
    marginTop: 6,
    textAlign: 'right',
  },
});
