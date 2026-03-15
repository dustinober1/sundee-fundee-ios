/**
 * RepRangePRTable.tsx — Table showing PR for each tracked rep range.
 *
 * Rep ranges: 1RM, 3RM, 5RM, 8RM, 10RM
 * Columns: Rep Range | Best Weight | Date Achieved
 * Null entries show "--" placeholder.
 * Current best 1RM row highlighted with ORANGE accent.
 */

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import type { RepRangePR } from '@/src/domain/progress/progress-data';
import * as colors from '@/src/theme/colors';

interface RepRangePRTableProps {
  prs: RepRangePR[];
}

function formatDate(dateStr: string | null): string {
  if (dateStr === null) return '—';
  const date = new Date(dateStr + (dateStr.includes('T') ? '' : 'T12:00:00'));
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatRepRange(repRange: number): string {
  return repRange === 1 ? '1RM' : `${repRange}RM`;
}

export function RepRangePRTable({ prs }: RepRangePRTableProps): React.JSX.Element {
  // Find the best 1RM to highlight
  const best1RM = prs.find((p) => p.repRange === 1);
  const has1RMPR = best1RM?.weight !== null;

  return (
    <View style={styles.container}>
      {/* Header row */}
      <View style={styles.headerRow}>
        <Text style={[styles.cell, styles.headerCell, styles.repRangeCell]}>Rep Range</Text>
        <Text style={[styles.cell, styles.headerCell, styles.weightCell]}>Best Weight</Text>
        <Text style={[styles.cell, styles.headerCell, styles.dateCell]}>Achieved</Text>
      </View>

      {/* Data rows */}
      {prs.map((pr, idx) => {
        const isHighlighted = pr.repRange === 1 && has1RMPR;
        return (
          <View
            key={pr.repRange}
            style={[
              styles.dataRow,
              idx % 2 === 1 && styles.dataRowAlt,
              isHighlighted && styles.dataRowHighlighted,
            ]}
          >
            <View style={[styles.cell, styles.repRangeCell]}>
              <Text
                style={[
                  styles.repRangeText,
                  isHighlighted && styles.repRangeTextHighlighted,
                ]}
              >
                {formatRepRange(pr.repRange)}
              </Text>
            </View>
            <Text
              style={[
                styles.cell,
                styles.weightCell,
                styles.weightText,
                pr.weight !== null && isHighlighted && styles.weightTextHighlighted,
              ]}
            >
              {pr.weight !== null ? `${pr.weight} lbs` : '—'}
            </Text>
            <Text style={[styles.cell, styles.dateCell, styles.dateText]}>
              {formatDate(pr.date)}
            </Text>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 10,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E0DCD0',
  },
  headerRow: {
    flexDirection: 'row',
    backgroundColor: colors.NAVY,
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  dataRow: {
    flexDirection: 'row',
    paddingVertical: 10,
    paddingHorizontal: 12,
    backgroundColor: colors.CREAM,
    alignItems: 'center',
  },
  dataRowAlt: {
    backgroundColor: colors.CREAM_LIGHT,
  },
  dataRowHighlighted: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderLeftWidth: 3,
    borderLeftColor: colors.ORANGE,
  },
  cell: {
    fontSize: 13,
    color: colors.NAVY,
  },
  headerCell: {
    color: colors.CREAM,
    fontWeight: '700',
    fontSize: 11,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  repRangeCell: {
    width: 80,
  },
  weightCell: {
    flex: 1,
  },
  dateCell: {
    width: 110,
  },
  repRangeText: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.NAVY,
  },
  repRangeTextHighlighted: {
    color: colors.ORANGE_DARK,
  },
  weightText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.NAVY,
  },
  weightTextHighlighted: {
    color: colors.ORANGE_DARK,
    fontWeight: '800',
  },
  dateText: {
    fontSize: 12,
    color: colors.NAVY_MEDIUM,
  },
});
