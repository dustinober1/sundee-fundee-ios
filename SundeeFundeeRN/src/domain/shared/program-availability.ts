/**
 * ProgramAvailability
 * Ported from SundeeFundee/Domain/ProgramAvailability.swift
 *
 * Date-based program availability determination.
 * Uses date-fns for date arithmetic (matching plan decision to use date-fns).
 * Pure functions — no side effects, no storage access.
 */

import { startOfDay, parseISO, isValid } from 'date-fns';
import { format } from 'date-fns';
import type { Program } from '../types';

// ---------------------------------------------------------------------------
// ProgramAvailabilityStatus — discriminated union matching Swift enum
// ---------------------------------------------------------------------------

export type ProgramAvailabilityStatus =
  | { kind: 'upcoming'; startDate: Date }
  | { kind: 'active' }
  | { kind: 'past' };

// ---------------------------------------------------------------------------
// Pure functions
// ---------------------------------------------------------------------------

/**
 * Parse a date string in 'yyyy-MM-dd' format.
 * Returns null for invalid or empty strings.
 * Matches Swift ProgramAvailability.parseDate(_:).
 */
export function parseProgramDate(dateString: string): Date | null {
  if (!dateString) return null;
  const parsed = parseISO(dateString);
  return isValid(parsed) ? parsed : null;
}

/**
 * Format a date for display (e.g., "Sat, Mar 14").
 * Matches Swift ProgramAvailability.formattedStartDate(_:).
 */
export function formatProgramStartDate(date: Date): string {
  return format(date, 'EEE, MMM d');
}

/**
 * Determine if a program is upcoming, active, or past.
 * Matches Swift ProgramAvailability.status(for:now:).
 *
 * @param program - Program with optional startDate and endDate strings ('yyyy-MM-dd')
 * @param now     - Reference date (defaults to current date)
 */
export function getProgramAvailability(
  program: Program,
  now: Date = new Date(),
): ProgramAvailabilityStatus {
  const today = startOfDay(now);

  if (program.startDate) {
    const start = parseProgramDate(program.startDate);
    if (start != null) {
      const startDay = startOfDay(start);
      if (startDay > today) {
        return { kind: 'upcoming', startDate: start };
      }
    }
  }

  if (program.endDate) {
    const end = parseProgramDate(program.endDate);
    if (end != null) {
      const endDay = startOfDay(end);
      if (endDay < today) {
        return { kind: 'past' };
      }
    }
  }

  return { kind: 'active' };
}

/**
 * Sort programs: active first, upcoming second, past last.
 * Matches Swift ProgramAvailability.sortedPrograms(_:now:).
 */
export function sortedPrograms(programs: Program[], now: Date = new Date()): Program[] {
  function sortOrder(status: ProgramAvailabilityStatus): number {
    switch (status.kind) {
      case 'active': return 0;
      case 'upcoming': return 1;
      case 'past': return 2;
    }
  }

  return [...programs].sort((a, b) => {
    const statusA = getProgramAvailability(a, now);
    const statusB = getProgramAvailability(b, now);
    return sortOrder(statusA) - sortOrder(statusB);
  });
}

/**
 * Find the next upcoming program (earliest start date).
 * Matches Swift ProgramAvailability.nextUpcomingProgram(from:now:).
 */
export function nextUpcomingProgram(programs: Program[], now: Date = new Date()): Program | undefined {
  const upcoming = programs.filter((p) => {
    const status = getProgramAvailability(p, now);
    return status.kind === 'upcoming';
  });

  if (upcoming.length === 0) return undefined;

  return upcoming.sort((a, b) => {
    const dateA = parseProgramDate(a.startDate ?? '') ?? new Date(8640000000000000);
    const dateB = parseProgramDate(b.startDate ?? '') ?? new Date(8640000000000000);
    return dateA.getTime() - dateB.getTime();
  })[0];
}
