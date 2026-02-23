import '../calculations/cycle_calculations.dart';
import '../enums.dart';
import '../models/cycle_models.dart';
import '../models/program_models.dart';

class ProgramScheduler {
  /// Recommends a start date for the program to align Max Attempt weeks (4, 8, 12)
  /// with the user's predicted Ovulation phase.
  ///
  /// Assumptions:
  /// - The program blocks are 4 weeks long.
  /// - Max attempts occur at the end of the block (Week 4, 8, 12).
  /// - Ideally, the Max Attempt day should fall within the Ovulation phase.
  ///
  /// Strategy:
  /// - Align the end of Week 4 (Day 28) with the estimated Ovulation day.
  /// - If the cycle is ~28 days, starting on the Ovulation day of the current cycle
  ///   will align Week 4 (Day 28) with the *next* Ovulation day.
  static DateTime getRecommendedStartDate({
    required ProgramV2 program,
    required CycleSettingsModel settings,
    required DateTime lastPeriodDate,
  }) {
    // 1. Determine when Ovulation happens in the cycle
    final Map<CyclePhase, PhaseBoundary> boundaries =
        CycleCalculations.getPhaseBoundaries(settings: settings);
    final PhaseBoundary? ovulationBounds = boundaries[CyclePhase.ovulation];

    // Default to mid-cycle if not found (e.g. Day 14 for 28 day cycle)
    final int ovulationStartDay = ovulationBounds?.start ??
        (settings.averageCycleLength - settings.lutealPhaseLength - 2);

    // We target the max attempt (End of Week 4 = Day 28) to hit Ovulation Start.
    // So StartDate + 28 days = Next Ovulation Date.
    // StartDate = Next Ovulation Date - 28 days.

    // Let's find the *next* occurrence of Ovulation relative to today (or last period).
    // Actually, simply:
    // Ideally, Start Date = Ovulation Date of CURRENT cycle.
    // Because: StartDate + 28 days (1 block) = Ovulation + 28 days = Next Ovulation.

    final DateTime ovulationDateCurrentCycle = lastPeriodDate.add(
      Duration(days: ovulationStartDay - 1),
    );

    // If that date is in the past, maybe suggest the next one?
    // But logically, the "best" alignment is simply "Start on Ovulation Day".
    // Whether it's this cycle or next depends on when the user wants to start.
    // We will return the Ovulation Date of the *current* cycle as the anchor.
    // The UI can suggest "Next Monday after [Date]" or similar.

    // However, if the user is already past ovulation in current cycle,
    // starting "today" would mean Week 4 lands in Luteal/Menstrual of next cycle.
    // So we might want to suggest the *next* cycle's ovulation date.

    final DateTime now = DateTime.now();
    if (ovulationDateCurrentCycle.isBefore(now)) {
      // Suggest next cycle's ovulation
      return ovulationDateCurrentCycle.add(
        Duration(days: settings.averageCycleLength),
      );
    }

    return ovulationDateCurrentCycle;
  }
}
