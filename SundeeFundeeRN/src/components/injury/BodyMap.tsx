/**
 * BodyMap.tsx — Interactive body diagram for injury location selection.
 *
 * Renders a front-view human body outline as a grid of Pressable regions
 * mapped to BodyLocation type values. Uses expo-haptics for tactile feedback.
 *
 * Props:
 *   onSelectLocation: (location: BodyLocation) => void
 *   highlightedLocations?: BodyLocation[]  — shown in orange/red for active injuries
 *
 * Static helper:
 *   BodyMap.locationLabel(location: BodyLocation): string
 */

import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import * as Haptics from 'expo-haptics';
import type { BodyLocation } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';

// ─── Location label map ───────────────────────────────────────────────────────

const LOCATION_LABELS: Record<BodyLocation, string> = {
  head: 'Head',
  neck: 'Neck',
  leftShoulder: 'Left Shoulder',
  rightShoulder: 'Right Shoulder',
  chest: 'Chest',
  upperBack: 'Upper Back',
  lowerBack: 'Lower Back',
  leftElbow: 'Left Elbow',
  rightElbow: 'Right Elbow',
  leftWrist: 'Left Wrist',
  rightWrist: 'Right Wrist',
  leftHip: 'Left Hip',
  rightHip: 'Right Hip',
  leftKnee: 'Left Knee',
  rightKnee: 'Right Knee',
  leftAnkle: 'Left Ankle',
  rightAnkle: 'Right Ankle',
};

// ─── Body region layout ───────────────────────────────────────────────────────

interface BodyRegion {
  location: BodyLocation;
  row: number;
  col: number;
  colSpan?: number;
  label: string;
}

const BODY_REGIONS: BodyRegion[] = [
  { location: 'head',          row: 0, col: 1, label: 'Head' },
  { location: 'neck',          row: 1, col: 1, label: 'Neck' },
  { location: 'leftShoulder',  row: 2, col: 0, label: 'L. Shoulder' },
  { location: 'chest',         row: 2, col: 1, label: 'Chest' },
  { location: 'rightShoulder', row: 2, col: 2, label: 'R. Shoulder' },
  { location: 'leftElbow',     row: 3, col: 0, label: 'L. Elbow' },
  { location: 'upperBack',     row: 3, col: 1, label: 'Upper Back' },
  { location: 'rightElbow',    row: 3, col: 2, label: 'R. Elbow' },
  { location: 'leftWrist',     row: 4, col: 0, label: 'L. Wrist' },
  { location: 'lowerBack',     row: 4, col: 1, label: 'Lower Back' },
  { location: 'rightWrist',    row: 4, col: 2, label: 'R. Wrist' },
  { location: 'leftHip',       row: 5, col: 0, label: 'L. Hip' },
  { location: 'rightHip',      row: 5, col: 2, label: 'R. Hip' },
  { location: 'leftKnee',      row: 6, col: 0, label: 'L. Knee' },
  { location: 'rightKnee',     row: 6, col: 2, label: 'R. Knee' },
  { location: 'leftAnkle',     row: 7, col: 0, label: 'L. Ankle' },
  { location: 'rightAnkle',    row: 7, col: 2, label: 'R. Ankle' },
];

const ROW_COUNT = 8;
const COL_COUNT = 3;

// ─── Props ────────────────────────────────────────────────────────────────────

interface BodyMapProps {
  onSelectLocation: (location: BodyLocation) => void;
  highlightedLocations?: BodyLocation[];
  selectedLocation?: BodyLocation | null;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function BodyMap({
  onSelectLocation,
  highlightedLocations = [],
  selectedLocation,
}: BodyMapProps): React.JSX.Element {
  function handlePress(location: BodyLocation): void {
    void Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onSelectLocation(location);
  }

  // Build a 2D grid for layout
  const grid: (BodyRegion | null)[][] = Array.from({ length: ROW_COUNT }, () =>
    Array(COL_COUNT).fill(null),
  );
  for (const region of BODY_REGIONS) {
    grid[region.row][region.col] = region;
  }

  return (
    <View style={styles.container} accessibilityLabel="Body map — tap a region to select injury location">
      {/* Column headers */}
      <View style={styles.headerRow}>
        <Text style={styles.headerLabel}>Left</Text>
        <Text style={styles.headerLabel}>Center</Text>
        <Text style={styles.headerLabel}>Right</Text>
      </View>

      {/* Body grid */}
      {grid.map((row, rowIdx) => (
        <View key={rowIdx} style={styles.row}>
          {Array.from({ length: COL_COUNT }, (_, colIdx) => {
            const region = row[colIdx];

            if (!region) {
              // Empty cell placeholder
              return <View key={colIdx} style={styles.cell} />;
            }

            const isHighlighted = highlightedLocations.includes(region.location);
            const isSelected = selectedLocation === region.location;

            return (
              <Pressable
                key={colIdx}
                style={({ pressed }) => [
                  styles.cell,
                  styles.regionCell,
                  isHighlighted && styles.highlightedCell,
                  isSelected && styles.selectedCell,
                  pressed && styles.pressedCell,
                ]}
                onPress={() => handlePress(region.location)}
                accessibilityRole="button"
                accessibilityLabel={region.label}
                accessibilityState={{ selected: isSelected }}
              >
                <Text
                  style={[
                    styles.regionLabel,
                    isHighlighted && styles.highlightedLabel,
                    isSelected && styles.selectedLabel,
                  ]}
                  numberOfLines={2}
                >
                  {region.label}
                </Text>
                {isHighlighted && !isSelected && (
                  <View style={styles.injuryDot} />
                )}
              </Pressable>
            );
          })}
        </View>
      ))}

      <Text style={styles.hint}>Tap a region to select</Text>
    </View>
  );
}

// ─── Static helper ────────────────────────────────────────────────────────────

/**
 * Returns the human-readable label for a BodyLocation.
 * Extracted as a static-style function for testability.
 */
BodyMap.locationLabel = function locationLabel(location: BodyLocation): string {
  return LOCATION_LABELS[location];
};

// ─── Styles ───────────────────────────────────────────────────────────────────

const CELL_HEIGHT = 52;

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 8,
    paddingVertical: 8,
  },
  headerRow: {
    flexDirection: 'row',
    marginBottom: 4,
  },
  headerLabel: {
    flex: 1,
    textAlign: 'center',
    fontSize: 11,
    fontWeight: '600',
    color: colors.NAVY_MEDIUM,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  row: {
    flexDirection: 'row',
    marginBottom: 4,
  },
  cell: {
    flex: 1,
    height: CELL_HEIGHT,
    marginHorizontal: 3,
    borderRadius: 8,
  },
  regionCell: {
    backgroundColor: colors.CREAM_LIGHT,
    borderWidth: 1.5,
    borderColor: colors.GREY_LIGHT,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 4,
  },
  highlightedCell: {
    backgroundColor: colors.ORANGE_LIGHT,
    borderColor: colors.ORANGE,
  },
  selectedCell: {
    backgroundColor: colors.NAVY,
    borderColor: colors.NAVY_DARK,
  },
  pressedCell: {
    opacity: 0.7,
  },
  regionLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.NAVY,
    textAlign: 'center',
    lineHeight: 14,
  },
  highlightedLabel: {
    color: colors.ORANGE_DARK,
  },
  selectedLabel: {
    color: colors.CREAM,
  },
  injuryDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.ORANGE,
    position: 'absolute',
    top: 5,
    right: 5,
  },
  hint: {
    textAlign: 'center',
    fontSize: 12,
    color: colors.GREY,
    marginTop: 8,
  },
});
