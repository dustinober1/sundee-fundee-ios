/**
 * MuscleGroupGrid — 2-column grid of muscle group cards for exercise browsing.
 *
 * Tapping a card calls onSelectMuscleGroup with the selected group name.
 * Art Deco styling: CREAM_LIGHT cards, NAVY text, ORANGE border on selection.
 */

import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  FlatList,
} from 'react-native';
import { MUSCLE_GROUPS } from '../../domain/exercises/exercise-types';
import type { MuscleGroup } from '../../domain/exercises/exercise-types';
import {
  CREAM_LIGHT,
  NAVY,
  ORANGE,
  NAVY_MEDIUM,
  GREY_LIGHT,
} from '../../theme/colors';

// ─── Muscle group icon map ────────────────────────────────────────────────────

const MUSCLE_GROUP_ICONS: Record<MuscleGroup, string> = {
  Chest: '🏋',
  Back: '🔙',
  Legs: '🦵',
  Shoulders: '💪',
  Arms: '💪',
  Core: '⚡',
  'Full Body': '🌟',
};

// ─── Props ────────────────────────────────────────────────────────────────────

interface MuscleGroupGridProps {
  selectedGroup?: MuscleGroup | null;
  onSelectMuscleGroup: (group: MuscleGroup) => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function MuscleGroupGrid({
  selectedGroup,
  onSelectMuscleGroup,
}: MuscleGroupGridProps): React.JSX.Element {
  return (
    <FlatList
      data={MUSCLE_GROUPS}
      keyExtractor={(item) => item}
      numColumns={2}
      contentContainerStyle={styles.container}
      renderItem={({ item }) => {
        const isSelected = selectedGroup === item;
        return (
          <TouchableOpacity
            style={[styles.card, isSelected && styles.cardSelected]}
            onPress={() => onSelectMuscleGroup(item)}
            accessibilityRole="button"
            accessibilityLabel={item}
            accessibilityState={{ selected: isSelected }}
          >
            <Text style={styles.icon}>{MUSCLE_GROUP_ICONS[item]}</Text>
            <Text style={[styles.label, isSelected && styles.labelSelected]}>{item}</Text>
          </TouchableOpacity>
        );
      }}
    />
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    padding: 12,
    gap: 12,
  },
  card: {
    flex: 1,
    margin: 6,
    paddingVertical: 20,
    paddingHorizontal: 12,
    backgroundColor: CREAM_LIGHT,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: GREY_LIGHT,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  cardSelected: {
    borderColor: ORANGE,
    borderWidth: 2,
  },
  icon: {
    fontSize: 28,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: NAVY,
    textAlign: 'center',
  },
  labelSelected: {
    color: NAVY_MEDIUM,
  },
});
