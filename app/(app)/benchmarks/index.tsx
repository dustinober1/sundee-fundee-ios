/**
 * app/(app)/benchmarks/index.tsx — Benchmark Catalog screen.
 *
 * Shows all predefined benchmarks grouped by category in a SectionList.
 * Also loads custom benchmarks from the repository and appends as "Custom" section.
 *
 * Navigation:
 *   - Tap row -> benchmarks/[id]
 *   - "Create Custom" FAB -> benchmarks/create
 *
 * Art Deco styling: navy section headers, cream row cards.
 */

import React, { useCallback, useState } from 'react';
import {
  SectionList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  ActivityIndicator,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import {
  getBenchmarkCategoryGroups,
  BENCHMARK_CATALOG,
} from '@/src/domain/benchmarks/benchmark-catalog';
import { getBenchmarkRepo } from '@/src/repositories/BenchmarkRepo';
import type { BenchmarkDefinition } from '@/src/repositories/BenchmarkRepo';
import type { BenchmarkCategoryGroup } from '@/src/domain/benchmarks/benchmark-catalog';
import * as colors from '@/src/theme/colors';

const SCORING_LABEL: Record<string, string> = {
  time: 'Time',
  reps: 'Reps',
  weight: 'Weight',
  distance: 'Distance',
  roundsAndReps: 'Rounds',
};

interface SectionData {
  title: string;
  data: BenchmarkDefinition[];
}

export default function BenchmarkCatalogScreen(): React.JSX.Element {
  const router = useRouter();
  const { user, isGuest } = useSession();
  const [sections, setSections] = useState<SectionData[]>([]);
  const [loading, setLoading] = useState(true);

  const loadBenchmarks = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      // Build predefined sections from catalog
      const groups: BenchmarkCategoryGroup[] = getBenchmarkCategoryGroups();
      const builtSections: SectionData[] = groups.map((g) => ({
        title: g.category,
        data: g.entries,
      }));

      // Load custom benchmarks
      const uid = user?.uid ?? '';
      const custom = await getBenchmarkRepo(isGuest).getCustomBenchmarks(uid);
      if (custom.length > 0) {
        builtSections.push({ title: 'Custom', data: custom });
      }

      setSections(builtSections);
    } catch {
      // Fallback: show predefined catalog only
      const groups = getBenchmarkCategoryGroups();
      setSections(groups.map((g) => ({ title: g.category, data: g.entries })));
    } finally {
      setLoading(false);
    }
  }, [user, isGuest]);

  useFocusEffect(
    useCallback(() => {
      void loadBenchmarks();
    }, [loadBenchmarks]),
  );

  function handleSelectBenchmark(benchmark: BenchmarkDefinition): void {
    router.push({
      pathname: '/(app)/benchmarks/[id]',
      params: {
        id: benchmark.id,
        name: benchmark.name,
        category: benchmark.category,
        description: benchmark.workoutDescription,
        scoringType: benchmark.scoringType,
        isPredefined: benchmark.isPredefined ? '1' : '0',
      },
    });
  }

  function handleCreateCustom(): void {
    router.push('/(app)/benchmarks/create');
  }

  function renderItem({ item }: { item: BenchmarkDefinition }): React.JSX.Element {
    const scoringLabel = SCORING_LABEL[item.scoringType] ?? item.scoringType;
    return (
      <TouchableOpacity
        style={styles.row}
        onPress={() => handleSelectBenchmark(item)}
        activeOpacity={0.75}
        testID={`benchmark-row-${item.id}`}
      >
        <View style={styles.rowContent}>
          <Text style={styles.rowName} numberOfLines={1}>
            {item.name}
          </Text>
          <Text style={styles.rowDescription} numberOfLines={2}>
            {item.workoutDescription}
          </Text>
        </View>
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{scoringLabel}</Text>
        </View>
      </TouchableOpacity>
    );
  }

  function renderSectionHeader({ section }: { section: SectionData }): React.JSX.Element {
    return (
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionHeaderText}>{section.title}</Text>
      </View>
    );
  }

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator color={colors.ORANGE} size="large" />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        renderSectionHeader={renderSectionHeader}
        contentContainerStyle={styles.listContent}
        stickySectionHeadersEnabled
        showsVerticalScrollIndicator={false}
      />

      {/* Create Custom FAB */}
      <TouchableOpacity
        style={styles.fab}
        onPress={handleCreateCustom}
        activeOpacity={0.85}
        testID="create-custom-fab"
      >
        <Text style={styles.fabText}>+ Custom</Text>
      </TouchableOpacity>
    </View>
  );
}

// Suppress unused import lint warning — BENCHMARK_CATALOG is used indirectly via getBenchmarkCategoryGroups
void BENCHMARK_CATALOG;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  listContent: {
    paddingBottom: 100,
  },
  sectionHeader: {
    backgroundColor: colors.NAVY,
    paddingVertical: 8,
    paddingHorizontal: 16,
  },
  sectionHeaderText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.CREAM_LIGHT,
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  rowContent: {
    flex: 1,
    marginRight: 8,
  },
  rowName: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.NAVY,
    marginBottom: 2,
  },
  rowDescription: {
    fontSize: 12,
    color: colors.GREY,
    lineHeight: 16,
  },
  badge: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderRadius: 6,
    paddingVertical: 3,
    paddingHorizontal: 8,
    borderWidth: 1,
    borderColor: colors.ORANGE,
  },
  badgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.ORANGE_DARK,
    letterSpacing: 0.3,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    backgroundColor: colors.ORANGE,
    borderRadius: 28,
    paddingVertical: 14,
    paddingHorizontal: 22,
    shadowColor: colors.ORANGE_DARK,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 6,
  },
  fabText: {
    fontSize: 15,
    fontWeight: '700',
    color: colors.CREAM,
    letterSpacing: 0.5,
  },
});
