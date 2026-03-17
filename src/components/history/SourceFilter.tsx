/**
 * SourceFilter.tsx — Filter chip row for workout history source filtering.
 *
 * Renders a horizontal scrollable row of filter chips:
 * All, AI, Program, Custom.
 *
 * Active chip: ORANGE background, CREAM text.
 * Inactive chip: CREAM_LIGHT background, NAVY text.
 */

import React from 'react';
import { ScrollView, TouchableOpacity, Text, StyleSheet, View } from 'react-native';
import type { HistorySourceFilter } from '@/src/domain/history/history-filter';
import * as colors from '@/src/theme/colors';

interface SourceFilterProps {
  activeFilter: HistorySourceFilter;
  onFilterChange: (filter: HistorySourceFilter) => void;
}

interface FilterOption {
  value: HistorySourceFilter;
  label: string;
}

const FILTER_OPTIONS: FilterOption[] = [
  { value: 'all', label: 'All' },
  { value: 'ai', label: 'AI' },
  { value: 'program', label: 'Program' },
  { value: 'custom', label: 'Custom' },
];

export function SourceFilter({ activeFilter, onFilterChange }: SourceFilterProps): React.JSX.Element {
  return (
    <View style={styles.container}>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {FILTER_OPTIONS.map((option) => {
          const isActive = option.value === activeFilter;
          return (
            <TouchableOpacity
              key={option.value}
              style={[styles.chip, isActive ? styles.chipActive : styles.chipInactive]}
              onPress={() => onFilterChange(option.value)}
              activeOpacity={0.7}
            >
              <Text style={[styles.chipText, isActive ? styles.chipTextActive : styles.chipTextInactive]}>
                {option.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingVertical: 10,
    backgroundColor: colors.CREAM,
    borderBottomWidth: 1,
    borderBottomColor: colors.CREAM_LIGHT,
  },
  scrollContent: {
    paddingHorizontal: 16,
    gap: 8,
    flexDirection: 'row',
  },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 7,
    borderRadius: 20,
    borderWidth: 1,
  },
  chipActive: {
    backgroundColor: colors.ORANGE,
    borderColor: colors.ORANGE,
  },
  chipInactive: {
    backgroundColor: colors.CREAM_LIGHT,
    borderColor: colors.NAVY_MEDIUM,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.3,
  },
  chipTextActive: {
    color: colors.CREAM,
  },
  chipTextInactive: {
    color: colors.NAVY,
  },
});
