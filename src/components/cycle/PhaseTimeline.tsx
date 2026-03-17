/**
 * PhaseTimeline.tsx — 2-cycle phase forecast timeline.
 *
 * Renders a horizontal color-coded bar showing cycle phase segments
 * for 2 cycles into the future. Uses expo-linear-gradient for smooth
 * transitions between phase color segments.
 *
 * Each segment shows:
 *   - Phase color bar (proportional width)
 *   - Phase name label below
 *   - Date range label
 *
 * A vertical marker highlights the current date position.
 *
 * Props:
 *   boundaries — Array of PhaseBoundary items (from getTimelineBoundaries)
 *   currentDate — The reference date (defaults to new Date())
 */

import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import type { CyclePhase } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';
import { format, differenceInCalendarDays, addDays } from 'date-fns';

// ─── Phase color map ──────────────────────────────────────────────────────────

const PHASE_COLORS: Record<CyclePhase, string> = {
  menstrual: '#E57373',
  follicular: '#81C784',
  ovulation: '#FFB74D',
  luteal: '#BA68C8',
};

function phaseAbbrev(phase: CyclePhase): string {
  switch (phase) {
    case 'menstrual':
      return 'M';
    case 'follicular':
      return 'F';
    case 'ovulation':
      return 'O';
    case 'luteal':
      return 'L';
  }
}

// ─── Timeline boundary type ───────────────────────────────────────────────────

export interface TimelineBoundary {
  phase: CyclePhase;
  startDate: Date;
  endDate: Date;
}

/**
 * Build timeline boundaries for N cycles starting from a given date.
 * Uses CycleSettings to compute phase day ranges per cycle.
 */
export function buildTimelineBoundaries(
  startDate: Date,
  cycleLength: number,
  periodLength: number,
  lutealLength: number,
  cycles: number
): TimelineBoundary[] {
  const boundaries: TimelineBoundary[] = [];
  let cycleStart = startDate;

  for (let c = 0; c < cycles; c++) {
    const ovDay = cycleLength - lutealLength;
    const ovStart = Math.max(periodLength + 2, ovDay - 2);
    const ovEnd = Math.max(ovStart, Math.min(ovDay + 2, cycleLength - lutealLength + 2));
    const follicularEnd = Math.max(periodLength + 1, ovStart - 1);

    const phases: Array<{ phase: CyclePhase; startDay: number; endDay: number }> = [
      { phase: 'menstrual', startDay: 1, endDay: periodLength },
      { phase: 'follicular', startDay: periodLength + 1, endDay: follicularEnd },
      { phase: 'ovulation', startDay: ovStart, endDay: ovEnd },
      { phase: 'luteal', startDay: ovEnd + 1, endDay: cycleLength },
    ];

    for (const { phase, startDay, endDay } of phases) {
      boundaries.push({
        phase,
        startDate: addDays(cycleStart, startDay - 1),
        endDate: addDays(cycleStart, endDay - 1),
      });
    }

    cycleStart = addDays(cycleStart, cycleLength);
  }

  return boundaries;
}

// ─── Component ────────────────────────────────────────────────────────────────

interface PhaseTimelineProps {
  boundaries: TimelineBoundary[];
  currentDate?: Date;
}

const SEGMENT_WIDTH = 72;

export default function PhaseTimeline({
  boundaries,
  currentDate = new Date(),
}: PhaseTimelineProps): React.JSX.Element {
  if (boundaries.length === 0) {
    return <View />;
  }

  const timelineStart = boundaries[0].startDate;
  const timelineEnd = boundaries[boundaries.length - 1].endDate;
  const totalDays = differenceInCalendarDays(timelineEnd, timelineStart) + 1;

  // Current position as fraction of total timeline
  const currentOffset = differenceInCalendarDays(currentDate, timelineStart);
  const totalWidth = boundaries.length * SEGMENT_WIDTH;
  const markerLeft = Math.max(0, Math.min((currentOffset / totalDays) * totalWidth, totalWidth - 2));

  return (
    <View style={styles.container}>
      <Text style={styles.sectionTitle}>2-Cycle Forecast</Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.timelineWrapper}>
          {/* Phase segments */}
          <View style={styles.barRow}>
            {boundaries.map((b, i) => {
              const segmentDays = differenceInCalendarDays(b.endDate, b.startDate) + 1;
              const segmentWidth = Math.max(48, (segmentDays / totalDays) * totalWidth);
              const color = PHASE_COLORS[b.phase];

              return (
                <LinearGradient
                  key={i}
                  colors={[color, color]}
                  style={[styles.segment, { width: segmentWidth }]}
                >
                  <Text style={styles.segmentAbbrev}>{phaseAbbrev(b.phase)}</Text>
                </LinearGradient>
              );
            })}
          </View>

          {/* Date labels below segments */}
          <View style={styles.labelRow}>
            {boundaries.map((b, i) => {
              const segmentDays = differenceInCalendarDays(b.endDate, b.startDate) + 1;
              const segmentWidth = Math.max(48, (segmentDays / totalDays) * totalWidth);
              return (
                <View key={i} style={[styles.labelCell, { width: segmentWidth }]}>
                  <Text style={[styles.phaseNameLabel, { color: PHASE_COLORS[b.phase] }]}>
                    {b.phase.charAt(0).toUpperCase() + b.phase.slice(1)}
                  </Text>
                  <Text style={styles.dateLabel}>
                    {format(b.startDate, 'MMM d')}
                  </Text>
                </View>
              );
            })}
          </View>

          {/* Current day marker */}
          {currentOffset >= 0 && currentOffset <= totalDays && (
            <View
              style={[styles.currentMarker, { left: markerLeft }]}
              pointerEvents="none"
            />
          )}
        </View>
      </ScrollView>
    </View>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  container: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.GREY,
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 10,
  },
  timelineWrapper: {
    position: 'relative',
    paddingBottom: 4,
  },
  barRow: {
    flexDirection: 'row',
    height: 40,
    borderRadius: 8,
    overflow: 'hidden',
  },
  segment: {
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  segmentAbbrev: {
    fontSize: 13,
    fontWeight: '700',
    color: '#fff',
  },
  labelRow: {
    flexDirection: 'row',
    marginTop: 6,
  },
  labelCell: {
    alignItems: 'flex-start',
    paddingLeft: 4,
  },
  phaseNameLabel: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  dateLabel: {
    fontSize: 9,
    color: colors.GREY,
    marginTop: 1,
  },
  currentMarker: {
    position: 'absolute',
    top: 0,
    bottom: 0,
    width: 2,
    backgroundColor: colors.NAVY,
    borderRadius: 1,
  },
});
