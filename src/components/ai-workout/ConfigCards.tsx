/**
 * ConfigCards.tsx
 *
 * Reusable horizontal scrollable card-row component for workout configuration.
 * Used by the AI workout config screen to display Time/Focus/Equipment/Energy options.
 *
 * Each option is a tappable ~80×80 card (Uber ride-selection style).
 * Selected card: orange border + slight scale. Unselected: cream background, navy border.
 */

import React from 'react';
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import * as colors from '@/src/theme/colors';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface CardOption {
  label: string;
  value: string;
  icon?: string;
}

export interface ConfigCardsProps {
  title: string;
  options: CardOption[];
  selected: string;
  onSelect: (value: string) => void;
  testID?: string;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function ConfigCards({
  title,
  options,
  selected,
  onSelect,
  testID,
}: ConfigCardsProps): React.JSX.Element {
  return (
    <View style={styles.container} testID={testID}>
      <Text style={styles.title}>{title}</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {options.map((option) => {
          const isSelected = option.value === selected;
          return (
            <TouchableOpacity
              key={option.value}
              style={[styles.card, isSelected && styles.cardSelected]}
              onPress={() => onSelect(option.value)}
              activeOpacity={0.75}
              testID={`card-option-${option.value}`}
            >
              {option.icon ? (
                <Text style={styles.cardIcon}>{option.icon}</Text>
              ) : null}
              <Text
                style={[styles.cardLabel, isSelected && styles.cardLabelSelected]}
                numberOfLines={2}
              >
                {option.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const CARD_SIZE = 80;

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  title: {
    color: colors.NAVY,
    fontSize: 14,
    fontWeight: '600',
    letterSpacing: 0.5,
    marginBottom: 10,
    textTransform: 'uppercase',
  },
  scrollContent: {
    paddingHorizontal: 2,
    gap: 10,
  },
  card: {
    width: CARD_SIZE,
    height: CARD_SIZE,
    backgroundColor: colors.CREAM_LIGHT,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: colors.NAVY_MEDIUM,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 6,
  },
  cardSelected: {
    borderColor: colors.ORANGE,
    borderWidth: 2,
    backgroundColor: colors.ORANGE_LIGHT,
    transform: [{ scale: 1.04 }],
  },
  cardIcon: {
    fontSize: 22,
    marginBottom: 4,
  },
  cardLabel: {
    color: colors.NAVY,
    fontSize: 11,
    fontWeight: '500',
    textAlign: 'center',
    lineHeight: 14,
  },
  cardLabelSelected: {
    color: colors.NAVY_DARK,
    fontWeight: '700',
  },
});
