/**
 * CycleCalendar.tsx — Period logging calendar component.
 *
 * Wraps react-native-calendars Calendar with period range marking.
 * Converts PeriodLog[] to markedDates for visual period ranges.
 *
 * Props:
 *   periodLogs    — Array of domain PeriodLog objects (dates as Date)
 *   onDayPress    — Callback when user taps a date (YYYY-MM-DD string)
 *   pendingStart  — If set, highlights the pending start date (awaiting end tap)
 *
 * Art Deco color tokens applied to calendar theme.
 */

import React from 'react';
import { StyleSheet, View } from 'react-native';
import { Calendar, type DateData } from 'react-native-calendars';
import type { PeriodLog } from '@/src/domain/types/index';
import * as colors from '@/src/theme/colors';
import { addDays, format } from 'date-fns';

/** Period marking color: soft coral used for period ranges */
const PERIOD_COLOR = '#E57373';
const PENDING_COLOR = colors.ORANGE;

/** Convert a Date to YYYY-MM-DD string for calendar keys */
function toDateString(date: Date): string {
  return format(date, 'yyyy-MM-dd');
}

/** Build the markedDates object from period logs */
export function buildMarkedDates(
  periodLogs: PeriodLog[],
  pendingStart?: string
): Record<string, object> {
  const marked: Record<string, object> = {};

  for (const log of periodLogs) {
    const startStr = toDateString(log.startDate);
    // If no end date, treat as single-day period
    const endDate = log.endDate ?? log.startDate;
    const endStr = toDateString(endDate);

    // Walk from start to end, marking each day
    let current = log.startDate;
    while (toDateString(current) <= endStr) {
      const key = toDateString(current);
      const isStart = key === startStr;
      const isEnd = key === endStr;

      marked[key] = {
        color: PERIOD_COLOR,
        textColor: '#fff',
        startingDay: isStart,
        endingDay: isEnd,
      };
      current = addDays(current, 1);
    }
  }

  // Overlay pending start date
  if (pendingStart) {
    marked[pendingStart] = {
      color: PENDING_COLOR,
      textColor: '#fff',
      startingDay: true,
      endingDay: true,
    };
  }

  return marked;
}

interface CycleCalendarProps {
  periodLogs: PeriodLog[];
  onDayPress: (dateString: string) => void;
  pendingStart?: string;
}

export default function CycleCalendar({
  periodLogs,
  onDayPress,
  pendingStart,
}: CycleCalendarProps): React.JSX.Element {
  const markedDates = buildMarkedDates(periodLogs, pendingStart);

  function handleDayPress(day: DateData): void {
    onDayPress(day.dateString);
  }

  return (
    <View style={styles.container}>
      <Calendar
        markingType="period"
        markedDates={markedDates}
        onDayPress={handleDayPress}
        theme={{
          calendarBackground: colors.CREAM,
          backgroundColor: colors.CREAM,
          textSectionTitleColor: colors.NAVY,
          dayTextColor: colors.NAVY,
          todayTextColor: colors.ORANGE,
          selectedDayBackgroundColor: colors.ORANGE,
          selectedDayTextColor: colors.CREAM,
          monthTextColor: colors.NAVY,
          arrowColor: colors.NAVY,
          dotColor: colors.ORANGE,
          textDayFontWeight: '500',
          textMonthFontWeight: '700',
          textDayHeaderFontWeight: '600',
          textDayFontSize: 14,
          textMonthFontSize: 16,
          textDayHeaderFontSize: 12,
        }}
        style={styles.calendar}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderRadius: 12,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: colors.GREY_LIGHT,
    backgroundColor: colors.CREAM,
  },
  calendar: {
    borderRadius: 12,
  },
});
