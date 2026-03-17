/**
 * injuries/index.tsx — Injury list screen.
 *
 * Shows all active injury profiles with recovery phase badges and injury dates.
 * Supports swipe-to-delete and navigation to injury detail or body-map creation.
 *
 * Data flow:
 *   getInjuryRepo(isGuest).getInjuries(uid) → InjuryProfileRecord[] → display
 */

import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { useFocusEffect, useRouter } from 'expo-router';
import { useSession } from '@/src/auth/AuthContext';
import { getInjuryRepo, recordToInjuryProfile, type InjuryProfileRecord } from '@/src/repositories/InjuryRepo';
import { BodyMap } from '@/src/components/injury/BodyMap';
import type { RecoveryPhase } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';

// ─── Recovery phase display helpers ──────────────────────────────────────────

/**
 * Returns a human-readable label for a RecoveryPhase.
 */
export function recoveryPhaseLabel(phase: RecoveryPhase): string {
  switch (phase) {
    case 'acute': return 'Acute';
    case 'rehab': return 'Rehab';
    case 'lightLoad': return 'Light Load';
    case 'returnToPlay': return 'Return to Play';
    case 'resolved': return 'Resolved';
  }
}

/**
 * Returns the badge background color for a RecoveryPhase.
 */
export function recoveryPhaseColor(phase: RecoveryPhase): string {
  switch (phase) {
    case 'acute': return colors.RED;
    case 'rehab': return colors.ORANGE;
    case 'lightLoad': return '#E6A817';
    case 'returnToPlay': return colors.NAVY_MEDIUM;
    case 'resolved': return colors.GREY;
  }
}

// ─── InjuryRow ────────────────────────────────────────────────────────────────

interface InjuryRowProps {
  record: InjuryProfileRecord;
  onPress: (record: InjuryProfileRecord) => void;
  onDelete: (record: InjuryProfileRecord) => void;
}

function InjuryRow({ record, onPress, onDelete }: InjuryRowProps): React.JSX.Element {
  const injuryDate = new Date(record.injuryDate);
  const dateLabel = injuryDate.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <TouchableOpacity
      style={styles.row}
      onPress={() => onPress(record)}
      activeOpacity={0.75}
    >
      <View style={styles.rowContent}>
        <Text style={styles.locationLabel}>
          {BodyMap.locationLabel(record.bodyLocation)}
        </Text>
        <Text style={styles.dateLabel}>{dateLabel}</Text>
      </View>

      <View style={styles.rowRight}>
        <View style={[styles.phaseBadge, { backgroundColor: recoveryPhaseColor(record.recoveryPhase) }]}>
          <Text style={styles.phaseText}>{recoveryPhaseLabel(record.recoveryPhase)}</Text>
        </View>
        <TouchableOpacity
          style={styles.deleteBtn}
          onPress={() => onDelete(record)}
          accessibilityLabel={`Delete injury: ${BodyMap.locationLabel(record.bodyLocation)}`}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        >
          <Text style={styles.deleteBtnText}>Delete</Text>
        </TouchableOpacity>
      </View>
    </TouchableOpacity>
  );
}

// ─── InjuryListScreen ─────────────────────────────────────────────────────────

export default function InjuryListScreen(): React.JSX.Element {
  const { user, isGuest } = useSession();
  const router = useRouter();
  const [injuries, setInjuries] = useState<InjuryProfileRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const loadInjuries = useCallback(async (): Promise<void> => {
    if (!user) return;
    setIsLoading(true);
    try {
      const repo = getInjuryRepo(isGuest);
      const records = await repo.getInjuries(user.uid);
      // Show non-resolved injuries first, then resolved, sorted by date desc
      const sorted = [...records].sort((a, b) => {
        const aResolved = a.recoveryPhase === 'resolved' ? 1 : 0;
        const bResolved = b.recoveryPhase === 'resolved' ? 1 : 0;
        if (aResolved !== bResolved) return aResolved - bResolved;
        return b.injuryDate.localeCompare(a.injuryDate);
      });
      setInjuries(sorted);
    } catch (err) {
      console.error('[InjuryListScreen] Failed to load injuries:', err);
    } finally {
      setIsLoading(false);
    }
  }, [user, isGuest]);

  useFocusEffect(
    useCallback(() => {
      void loadInjuries();
    }, [loadInjuries]),
  );

  function handleRowPress(record: InjuryProfileRecord): void {
    router.push({
      pathname: '/(app)/injuries/[id]',
      params: { id: record.id },
    });
  }

  function handleDelete(record: InjuryProfileRecord): void {
    if (!user) return;
    // Optimistic update
    setInjuries((prev) => prev.filter((r) => r.id !== record.id));
    const repo = getInjuryRepo(isGuest);
    void repo.deleteInjury(user.uid, record.id).catch((err) => {
      console.error('[InjuryListScreen] Delete failed:', err);
      void loadInjuries();
    });
  }

  function handleAddInjury(): void {
    router.push('/(app)/injuries/body-map');
  }

  if (isLoading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={colors.ORANGE} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => router.back()}
          style={styles.backBtn}
          accessibilityLabel="Back"
        >
          <Text style={styles.backBtnText}>Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Injuries</Text>
        <View style={styles.backBtn} />
      </View>

      {injuries.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyIcon}>+</Text>
          <Text style={styles.emptyTitle}>No active injuries</Text>
          <Text style={styles.emptySubtitle}>
            Track an injury to get exercise substitutions and a rehab plan.
          </Text>
          <TouchableOpacity
            style={styles.addButton}
            onPress={handleAddInjury}
            activeOpacity={0.8}
          >
            <Text style={styles.addButtonText}>Add Injury</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
          data={injuries}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <InjuryRow
              record={item}
              onPress={handleRowPress}
              onDelete={handleDelete}
            />
          )}
          contentContainerStyle={styles.listContent}
          ItemSeparatorComponent={() => <View style={styles.separator} />}
        />
      )}

      {/* FAB */}
      {injuries.length > 0 && (
        <TouchableOpacity
          style={styles.fab}
          onPress={handleAddInjury}
          activeOpacity={0.85}
          accessibilityLabel="Add injury"
          accessibilityRole="button"
        >
          <Text style={styles.fabText}>+ Add Injury</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.CREAM,
  },
  centered: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.CREAM,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 56,
    paddingBottom: 12,
    backgroundColor: colors.CREAM,
    borderBottomWidth: 1,
    borderBottomColor: colors.GREY_LIGHT,
  },
  backBtn: {
    width: 60,
  },
  backBtnText: {
    color: colors.ORANGE,
    fontSize: 16,
    fontWeight: '600',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.NAVY,
    letterSpacing: 0.3,
  },
  listContent: {
    padding: 16,
    paddingBottom: 100,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
  },
  rowContent: {
    flex: 1,
    gap: 4,
  },
  locationLabel: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.NAVY,
  },
  dateLabel: {
    fontSize: 13,
    color: colors.NAVY_MEDIUM,
  },
  rowRight: {
    alignItems: 'flex-end',
    gap: 8,
  },
  phaseBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  phaseText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  deleteBtn: {
    paddingVertical: 2,
    paddingHorizontal: 4,
  },
  deleteBtnText: {
    color: colors.RED,
    fontSize: 13,
    fontWeight: '600',
  },
  separator: {
    height: 10,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    gap: 12,
  },
  emptyIcon: {
    fontSize: 48,
    color: colors.GREY,
    fontWeight: '200',
    marginBottom: 8,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.NAVY,
    textAlign: 'center',
  },
  emptySubtitle: {
    fontSize: 15,
    color: colors.NAVY_MEDIUM,
    textAlign: 'center',
    lineHeight: 22,
  },
  addButton: {
    marginTop: 12,
    backgroundColor: colors.ORANGE,
    paddingHorizontal: 28,
    paddingVertical: 12,
    borderRadius: 24,
  },
  addButtonText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  fab: {
    position: 'absolute',
    bottom: 32,
    right: 24,
    backgroundColor: colors.ORANGE,
    paddingHorizontal: 22,
    paddingVertical: 14,
    borderRadius: 28,
    shadowColor: '#000',
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
  fabText: {
    color: colors.CREAM,
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
});
