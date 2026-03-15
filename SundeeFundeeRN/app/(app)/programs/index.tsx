/**
 * app/(app)/programs/index.tsx — Program Catalog.
 *
 * Displays all available strength training programs as a card list
 * with filter chips at the top (All, Strength, Hypertrophy, Power).
 *
 * Data: loaded via getProgramRepo(isGuest).getPrograms() on screen focus.
 * Navigation: tap a card -> programs/[id] (program detail).
 *
 * Art Deco styling: cream cards, navy text, orange accent borders.
 */

import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { useEntitlementContext } from '@/src/entitlements/EntitlementContext';
import { getProgramRepo } from '@/src/repositories/ProgramRepo';
import type { Program, ProgramSession } from '@/src/repositories/ProgramRepo';
import { PaywallModal } from '@/src/components/paywall/PaywallModal';
import { PremiumBadge } from '@/src/components/paywall/PremiumBadge';
import * as colors from '@/src/theme/colors';

// ─── Filter chip types ──────────────────────────────────────────────────────

type FilterCategory = 'All' | 'Strength' | 'Hypertrophy' | 'Power';

const FILTER_CHIPS: FilterCategory[] = ['All', 'Strength', 'Hypertrophy', 'Power'];

// ─── Helper functions ───────────────────────────────────────────────────────

/**
 * Maps a filter chip to one or more WorkoutFocus values for matching.
 * Exported for unit testing.
 */
export function focusValuesForFilter(
  filter: FilterCategory
): string[] {
  switch (filter) {
    case 'Strength':
      return ['strength', 'lower_body', 'upper_body', 'full_body', 'push', 'pull'];
    case 'Hypertrophy':
      return ['upper_body', 'lower_body', 'full_body', 'push', 'pull'];
    case 'Power':
      return ['olympic_lifts', 'conditioning'];
    case 'All':
    default:
      return [];
  }
}

/**
 * Returns whether a program matches the given filter category.
 * Exported for unit testing.
 */
export function programMatchesFilter(program: Program, filter: FilterCategory): boolean {
  if (filter === 'All') return true;
  const matchValues = focusValuesForFilter(filter);
  return program.sessions.some(
    (s: ProgramSession) => s.focusArea && matchValues.includes(s.focusArea)
  );
}

/**
 * Returns a short description snippet for a program card.
 * Exported for unit testing.
 */
export function getProgramDescription(program: Program): string {
  const sessionCount = program.sessions.length;
  const focusAreas = [
    ...new Set(
      program.sessions
        .map((s: ProgramSession) => s.focusArea)
        .filter((f): f is string => !!f)
    ),
  ];
  const focusText = focusAreas.length > 0
    ? focusAreas.map((f) => f.replace('_', ' ')).join(', ')
    : 'mixed';
  return `${sessionCount} session${sessionCount !== 1 ? 's' : ''} · ${focusText}`;
}

// ─── ProgramCard component ──────────────────────────────────────────────────

interface ProgramCardProps {
  program: Program;
  onPress: () => void;
  showPremiumBadge?: boolean;
}

function ProgramCard({ program, onPress, showPremiumBadge = false }: ProgramCardProps): React.JSX.Element {
  const sessionCount = program.sessions.length;
  const description = getProgramDescription(program);

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={onPress}
      accessibilityLabel={`${program.name}, ${description}`}
      accessibilityRole="button"
    >
      <View style={styles.cardAccentBar} />
      <View style={styles.cardContent}>
        <View style={styles.cardTitleRow}>
          <Text style={[styles.cardTitle, styles.cardTitleFlex]} numberOfLines={2}>
            {program.name}
          </Text>
          {showPremiumBadge && <PremiumBadge compact />}
        </View>
        <Text style={styles.cardMeta}>
          {sessionCount} session{sessionCount !== 1 ? 's' : ''}
        </Text>
        <Text style={styles.cardDescription} numberOfLines={2}>
          {description}
        </Text>
      </View>
    </TouchableOpacity>
  );
}

// ─── Main screen ────────────────────────────────────────────────────────────

export default function ProgramCatalogScreen(): React.JSX.Element {
  const { isGuest } = useSession();
  const { isPremium } = useEntitlementContext();
  const router = useRouter();
  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedFilter, setSelectedFilter] = useState<FilterCategory>('All');
  const [showPaywall, setShowPaywall] = useState(false);

  // Load programs on focus (refreshes on navigation return)
  useFocusEffect(
    useCallback(() => {
      let cancelled = false;
      setLoading(true);

      void getProgramRepo(isGuest)
        .getPrograms()
        .then((data) => {
          if (!cancelled) {
            setPrograms(data);
            setLoading(false);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setLoading(false);
          }
        });

      return () => {
        cancelled = true;
      };
    }, [isGuest])
  );

  const filteredPrograms = programs.filter((p) =>
    programMatchesFilter(p, selectedFilter)
  );

  return (
    <View style={styles.container}>
      {/* Filter chips */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.filterScroll}
        contentContainerStyle={styles.filterContent}
      >
        {FILTER_CHIPS.map((chip) => (
          <TouchableOpacity
            key={chip}
            style={[
              styles.filterChip,
              selectedFilter === chip && styles.filterChipActive,
            ]}
            onPress={() => setSelectedFilter(chip)}
            accessibilityLabel={`Filter by ${chip}`}
            accessibilityRole="button"
            accessibilityState={{ selected: selectedFilter === chip }}
          >
            <Text
              style={[
                styles.filterChipText,
                selectedFilter === chip && styles.filterChipTextActive,
              ]}
            >
              {chip}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Program list */}
      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={colors.ORANGE} />
        </View>
      ) : filteredPrograms.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>No programs found.</Text>
        </View>
      ) : (
        <FlatList
          data={filteredPrograms}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <ProgramCard
              program={item}
              showPremiumBadge={!isPremium}
              onPress={() => {
                if (!isPremium) {
                  setShowPaywall(true);
                } else {
                  router.push(`/programs/${item.id}`);
                }
              }}
            />
          )}
          contentContainerStyle={styles.listContent}
        />

        {/* Paywall for non-premium users */}
        <PaywallModal
          visible={showPaywall}
          onDismiss={() => setShowPaywall(false)}
          onSubscribed={() => setShowPaywall(false)}
        />
      )}
    </View>
  );
}

// ─── Styles ─────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  filterScroll: {
    flexGrow: 0,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  filterContent: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 8,
  },
  filterChip: {
    paddingHorizontal: 16,
    paddingVertical: 7,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: colors.NAVY_MEDIUM,
    backgroundColor: 'transparent',
    marginRight: 8,
  },
  filterChipActive: {
    backgroundColor: colors.NAVY,
    borderColor: colors.NAVY,
  },
  filterChipText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.3,
  },
  filterChipTextActive: {
    color: colors.CREAM,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  emptyText: {
    fontSize: 16,
    color: colors.GREY,
    textAlign: 'center',
  },
  listContent: {
    padding: 16,
    gap: 12,
  },
  card: {
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 8,
    overflow: 'hidden',
    flexDirection: 'row',
    shadowColor: colors.NAVY,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
    marginBottom: 12,
  },
  cardAccentBar: {
    width: 4,
    backgroundColor: colors.ORANGE,
  },
  cardContent: {
    flex: 1,
    padding: 16,
  },
  cardTitleRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: 4,
    gap: 8,
  },
  cardTitleFlex: {
    flex: 1,
  },
  cardTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.2,
    marginBottom: 4,
  },
  cardMeta: {
    fontSize: 12,
    color: colors.ORANGE,
    fontWeight: '600',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
    marginBottom: 6,
  },
  cardDescription: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
    lineHeight: 18,
  },
});
