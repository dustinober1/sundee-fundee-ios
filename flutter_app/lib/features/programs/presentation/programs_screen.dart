import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../domain/calculations/cycle_calculations.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/cycle_models.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../cycle/providers.dart';
import '../../profile/providers.dart';
import '../../repositories/domain/sync_status_model.dart';
import '../../shared/presentation/recoverable_access_banner.dart';
import '../../shared/presentation/sync_status_badge.dart';
import '../data/program_repository.dart';
import '../providers/adapted_program_provider.dart';
import '../providers/enrollment_lifecycle_provider.dart';
import 'widgets/cycle_adjustment_explainer.dart';
import 'widgets/injury_adaptation_banner.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  String? _writeError;
  bool? _cycleAdjustmentDetailsOverride;
  bool? _injuryBannerVisibleOverride;
  final ScrollController _catalogScrollController = ScrollController();

  @override
  void dispose() {
    _catalogScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProgramV2>> programsAsync =
        ref.watch(programsProvider);
    final AsyncValue<EnrollmentLifecycleState> lifecycleAsync =
        ref.watch(enrollmentLifecycleStateProvider);
    final AsyncValue<ProgramV2?> adaptedActiveProgramAsync = ref.watch(
      injuryAdaptedActiveProgramProvider,
    );
    final AuthSession? session =
        ref.watch(authSessionStreamProvider).asData?.value;
    final CycleStatusResult? cycleStatus = ref.watch(cycleStatusProvider);
    final ProgramAdaptationContext adaptationContext = ref.watch(
      programAdaptationContextProvider,
    );
    final InjuryAdaptationContext injuryContext = ref.watch(
      injuryAdaptationContextProvider,
    );
    final SyncStatusModel syncStatus = ref.watch(cycleSyncStatusProvider);
    final bool detailsVisible = _cycleAdjustmentDetailsOverride ??
        ref.watch(cycleAdjustmentDetailsVisibleProvider);
    final bool injuryBannerVisible = _injuryBannerVisibleOverride ?? true;

    final String? userId = session?.user?.uid ??
        (session?.status == AuthStatus.guest ? 'guest' : null);

    return programsAsync.when(
      data: (List<ProgramV2> programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No programs available.'));
        }

        return lifecycleAsync.when(
          data: (EnrollmentLifecycleState lifecycleState) {
            final bool showRecoverableBanner =
                lifecycleState.isRecoverableFailure;
            final EnrollmentLifecycleState contentState =
                lifecycleState.isRecoverableFailure ||
                        lifecycleState.isBlockingFailure
                    ? lifecycleState.fallbackContentState
                    : lifecycleState;

            if (lifecycleState.isBlockingFailure) {
              return _BlockingAccessState(
                message: lifecycleState.errorMessage ??
                    'Access is still unavailable. Retry to continue.',
                onRetry: () => refreshEnrollmentLifecycleAccess(ref),
              );
            }

            final RecoverableAccessBanner? recoverableBanner =
                showRecoverableBanner
                    ? RecoverableAccessBanner(
                        message: lifecycleState.errorMessage ??
                            'We are retrying access in the background.',
                        retryAttempt: lifecycleState.retryAttempt,
                        maxRetries: lifecycleState.maxRetries,
                        onRetry: () => refreshEnrollmentLifecycleAccess(ref),
                      )
                    : null;

            if (contentState.kind == EnrollmentLifecycleKind.validEmpty) {
              return _ProgramsCatalogList(
                controller: _catalogScrollController,
                programs: programs,
                userId: userId,
                onEnrollRequested: userId == null
                    ? null
                    : (ProgramV2 program) => _handleCatalogEnrollment(
                          userId: userId,
                          program: program,
                        ),
                leadingChildren: <Widget>[
                  if (recoverableBanner != null) ...<Widget>[
                    recoverableBanner,
                    const SizedBox(height: 12),
                  ],
                  if (_writeError != null) ...<Widget>[
                    _NoticeCard(
                      title: 'Sync warning',
                      body: _writeError!,
                      icon: Icons.sync_problem_outlined,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }

            if (contentState.kind == EnrollmentLifecycleKind.canceled) {
              return _ProgramsCatalogList(
                controller: _catalogScrollController,
                programs: programs,
                userId: userId,
                onEnrollRequested: userId == null
                    ? null
                    : (ProgramV2 program) => _handleCatalogEnrollment(
                          userId: userId,
                          program: program,
                        ),
                leadingChildren: <Widget>[
                  if (recoverableBanner != null) ...<Widget>[
                    recoverableBanner,
                    const SizedBox(height: 12),
                  ],
                  if (_writeError != null) ...<Widget>[
                    _NoticeCard(
                      title: 'Sync warning',
                      body: _writeError!,
                      icon: Icons.sync_problem_outlined,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _NoActivePlanCard(
                    canceledAt: contentState.canceledAt,
                    onBrowsePlans: _scrollToPlanCatalog,
                    onEnrollInNewPlan: userId == null
                        ? null
                        : () => _showEnrollInNewPlanDialog(
                              programs: programs,
                              userId: userId,
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available plans',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }

            final EnrolledProgramModel enrollment = contentState.enrollment!;

            ProgramV2? activeProgram;
            for (final ProgramV2 program in programs) {
              if (program.id == enrollment.programId) {
                activeProgram = program;
                break;
              }
            }

            if (activeProgram == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const <Widget>[
                  _NoticeCard(
                    title: 'Incomplete data',
                    body:
                        'Your active enrollment references a program that is not currently available.',
                    icon: Icons.warning_amber_outlined,
                  ),
                ],
              );
            }
            final ProgramV2 selectedProgram =
                adaptedActiveProgramAsync.asData?.value ?? activeProgram;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: <Widget>[
                if (recoverableBanner != null) recoverableBanner,
                _CycleContextCard(cycleStatus: cycleStatus),
                if (adaptationContext.isAdapted) ...<Widget>[
                  const SizedBox(height: 12),
                  CycleAdjustmentExplainer(
                    phase: adaptationContext.phase,
                    confidence: adaptationContext.confidence,
                    visible: detailsVisible,
                    showRecalculationBadge: true,
                    onToggleVisibility: () {
                      _setCycleAdjustmentVisibility(
                        userId: userId,
                        visible: !detailsVisible,
                      );
                    },
                  ),
                ],
                if (injuryContext.hasActiveInjuries) ...<Widget>[
                  const SizedBox(height: 12),
                  InjuryAdaptationBanner(
                    injuryContext: injuryContext,
                    adaptationChangelog: _buildAdaptationChangelog(
                      selectedProgram,
                    ),
                    visible: injuryBannerVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _injuryBannerVisibleOverride = !injuryBannerVisible;
                      });
                    },
                    onAcknowledgeDisclaimer: (String injuryId) async {
                      if (userId == null || userId == 'guest') return;
                      await ref
                          .read(profileRepositoryProvider)
                          .acknowledgeInjuryDisclaimer(
                            userId: userId,
                            injuryId: injuryId,
                          );
                    },
                  ),
                ],
                if (_writeError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _NoticeCard(
                    title: 'Sync warning',
                    body: _writeError!,
                    icon: Icons.sync_problem_outlined,
                    color: Colors.orange.shade700,
                  ),
                ],
                const SizedBox(height: 12),
                _LastSyncedRow(
                  lastSyncedAt: enrollment.lastSyncedAt,
                  syncStatus: syncStatus,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: userId == null
                        ? null
                        : () => _handleCancelEnrollment(
                              userId: userId,
                              enrollmentId: enrollment.id,
                            ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
                if (_hasIncompleteData(
                    selectedProgram, enrollment)) ...<Widget>[
                  const SizedBox(height: 12),
                  const _NoticeCard(
                    title: 'Incomplete data',
                    body:
                        'Some program details are missing. We are showing the available sections only.',
                    icon: Icons.info_outline,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  selectedProgram.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                // Hard gate: hide week list until disclaimer acknowledged
                if (injuryContext.hasActiveInjuries &&
                    !injuryContext.disclaimerAcknowledgedForAll)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Acknowledge the injury disclaimer above to view your adapted plan.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  )
                else
                  ...selectedProgram.weeks.map((ProgramWeek week) {
                    final bool isCompleted =
                        enrollment.completedWeeks.contains(week.week);
                    final bool isCurrent = enrollment.currentWeek == week.week;
                    final double progress = _progressForWeek(
                      week: week,
                      enrollment: enrollment,
                      isCompleted: isCompleted,
                      isCurrent: isCurrent,
                    );
                    final String statusLabel = isCompleted
                        ? 'Completed'
                        : isCurrent
                            ? 'In Progress'
                            : 'Upcoming';

                    return _WeekCard(
                      week: week,
                      statusLabel: statusLabel,
                      progress: progress,
                      intensityLabel:
                          _intensityLabel(week.week, week.isTestWeek ?? false),
                      adjustmentLabel:
                          adaptationContext.isAdapted ? 'Cycle-adjusted' : null,
                      showCompleteAction:
                          isCurrent && !isCompleted && userId != null,
                      canJump: userId != null,
                      onJumpToWeek: userId == null
                          ? null
                          : () => _handleJumpToWeek(
                                userId: userId,
                                enrollmentId: enrollment.id,
                                week: week.week,
                              ),
                      onMarkWeekComplete: userId == null
                          ? null
                          : () => _handleMarkWeekComplete(
                                userId: userId,
                                enrollment: enrollment,
                                durationWeeks: selectedProgram.durationWeeks,
                              ),
                    );
                  }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, StackTrace stack) => _BlockingAccessState(
            message: 'Could not load program access state. Retry to continue.',
            onRetry: () => refreshEnrollmentLifecycleAccess(ref),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) =>
          const Center(child: Text('Could not load programs right now.')),
    );
  }

  Future<void> _handleJumpToWeek({
    required String userId,
    required String enrollmentId,
    required int week,
  }) async {
    try {
      await ref.read(programRepositoryProvider).jumpToWeek(
            userId: userId,
            enrollmentId: enrollmentId,
            week: week,
          );
      if (mounted) {
        setState(() {
          _writeError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _writeError = 'Could not save changes. Please retry.';
        });
      }
    }
  }

  Future<void> _handleMarkWeekComplete({
    required String userId,
    required EnrolledProgramModel enrollment,
    required int durationWeeks,
  }) async {
    try {
      await ref.read(programRepositoryProvider).markWeekComplete(
            userId: userId,
            enrollment: enrollment,
            programDurationWeeks: durationWeeks,
          );
      if (mounted) {
        setState(() {
          _writeError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _writeError = 'Could not save changes. Please retry.';
        });
      }
    }
  }

  Future<void> _handleCancelEnrollment({
    required String userId,
    required String enrollmentId,
  }) async {
    final bool firstConfirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Cancel your plan?'),
              content: const Text(
                'You will lose access to active plan actions immediately.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('KEEP PLAN'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('CONTINUE'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!firstConfirmation) {
      return;
    }
    if (!mounted) {
      return;
    }

    final bool finalConfirmation = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('This cannot be undone'),
              content: const Text(
                'Confirm cancellation now. You can enroll in a new plan afterward.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('GO BACK'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('CANCEL PLAN'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!finalConfirmation) {
      return;
    }

    try {
      await ref.read(programRepositoryProvider).cancelEnrollment(
            userId: userId,
            enrollmentId: enrollmentId,
          );
      if (mounted) {
        setState(() {
          _writeError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _writeError = 'Could not cancel plan. Please retry.';
        });
      }
    }
  }

  Future<void> _showEnrollInNewPlanDialog({
    required List<ProgramV2> programs,
    required String userId,
  }) async {
    final ProgramV2? selectedProgram = await showModalBottomSheet<ProgramV2>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text('Enroll in new plan'),
                subtitle: Text('Choose a plan to start from week 1/day 1.'),
              ),
              ...programs.map((ProgramV2 program) {
                return ListTile(
                  title: Text(program.name),
                  subtitle: Text(program.description),
                  onTap: () => Navigator.of(context).pop(program),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedProgram == null) {
      return;
    }

    await _handleCatalogEnrollment(
      userId: userId,
      program: selectedProgram,
    );
  }

  Future<void> _handleCatalogEnrollment({
    required String userId,
    required ProgramV2 program,
  }) async {
    final ProgramRepository repository = ref.read(programRepositoryProvider);

    final EnrolledProgramModel? canceledEnrollment =
        await repository.findLatestCanceledEnrollmentForProgram(
      userId: userId,
      programId: program.id,
    );

    bool restorePriorEnrollment = false;
    if (canceledEnrollment != null) {
      if (!mounted) {
        return;
      }
      final _ReEnrollmentChoice? choice =
          await _promptReEnrollmentChoice(programName: program.name);
      if (choice == null) {
        return;
      }
      restorePriorEnrollment = choice == _ReEnrollmentChoice.restorePrior;
    }

    try {
      await repository.reEnroll(
        userId: userId,
        programId: program.id,
        restorePriorEnrollment: restorePriorEnrollment,
      );
      if (mounted) {
        setState(() {
          _writeError = null;
        });
      }
    } catch (error) {
      final String fallbackError = error is StateError
          ? error.message.toString()
          : 'Could not enroll in a new plan. Please retry.';
      if (mounted) {
        setState(() {
          _writeError = fallbackError;
        });
      }
    }
  }

  Future<_ReEnrollmentChoice?> _promptReEnrollmentChoice({
    required String programName,
  }) {
    return showDialog<_ReEnrollmentChoice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Re-enroll in $programName?'),
          content: const Text(
            'Choose how to continue. Both options restart at week 1/day 1.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ReEnrollmentChoice.restorePrior),
              child: const Text('Restore prior enrollment'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ReEnrollmentChoice.startNew),
              child: const Text('Start new enrollment'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToPlanCatalog() {
    if (!_catalogScrollController.hasClients) {
      return;
    }

    _catalogScrollController.animateTo(
      280,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Builds a deduplicated list of human-readable changelog entries from the
  /// adapted program. Used to populate the [InjuryAdaptationBanner].
  List<String> _buildAdaptationChangelog(ProgramV2 program) {
    final Set<String> seen = <String>{};
    final List<String> entries = <String>[];

    int maxRecoveryPrepCount = 0;

    for (final ProgramWeek week in program.weeks) {
      for (final ProgramSession session in week.sessions) {
        // Replaced exercises
        for (final ProgramExercise exercise in session.exercises) {
          if (exercise.injuryReplacedOriginal != null) {
            final String reason = exercise.injuryReplacementReason != null
                ? ' (${exercise.injuryReplacementReason})'
                : '';
            final String entry =
                '${exercise.injuryReplacedOriginal} → ${exercise.exercise}$reason';
            if (seen.add(entry)) {
              entries.add(entry);
            }
          }
        }
        // Track max recovery prep count across sessions
        if (session.recoveryPrepExercises.isNotEmpty) {
          maxRecoveryPrepCount =
              session.recoveryPrepExercises.length > maxRecoveryPrepCount
                  ? session.recoveryPrepExercises.length
                  : maxRecoveryPrepCount;
        }
      }
    }

    if (maxRecoveryPrepCount > 0) {
      entries.add(
        'Recovery prep block added ($maxRecoveryPrepCount exercise${maxRecoveryPrepCount == 1 ? '' : 's'})',
      );
    }

    return entries;
  }

  Future<void> _setCycleAdjustmentVisibility({
    required String? userId,
    required bool visible,
  }) async {
    if (mounted) {
      setState(() {
        _cycleAdjustmentDetailsOverride = visible;
      });
    }

    if (userId == null || userId == 'guest') {
      return;
    }

    final CycleAdaptationPreferencesModel existing =
        ref.read(cycleAdaptationPreferencesProvider).asData?.value ??
            defaultCycleAdaptationPreferences(userId);
    final CycleAdaptationPreferencesModel updated =
        CycleAdaptationPreferencesModel(
      id: existing.id,
      userId: userId,
      enabled: existing.enabled,
      readinessScore: existing.readinessScore,
      autoApplyDuringWorkout: existing.autoApplyDuringWorkout,
      showAdjustmentDetails: visible,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(cycleControllerProvider.notifier)
        .saveCycleAdaptationPreferences(updated);
  }
}

enum _ReEnrollmentChoice { restorePrior, startNew }

class _ProgramsCatalogList extends StatelessWidget {
  const _ProgramsCatalogList({
    this.controller,
    required this.programs,
    required this.userId,
    required this.onEnrollRequested,
    this.leadingChildren = const <Widget>[],
  });

  final ScrollController? controller;
  final List<ProgramV2> programs;
  final String? userId;
  final Future<void> Function(ProgramV2 program)? onEnrollRequested;
  final List<Widget> leadingChildren;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      children: <Widget>[
        ...leadingChildren,
        ...programs.map(
          (ProgramV2 program) => _ProgramCatalogCard(
            program: program,
            userId: userId,
            onEnrollRequested: onEnrollRequested,
          ),
        ),
      ],
    );
  }
}

class _ProgramCatalogCard extends StatelessWidget {
  const _ProgramCatalogCard({
    required this.program,
    required this.userId,
    required this.onEnrollRequested,
  });

  final ProgramV2 program;
  final String? userId;
  final Future<void> Function(ProgramV2 program)? onEnrollRequested;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              program.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onEnrollRequested == null
                    ? null
                    : () => onEnrollRequested!(program),
                child: const Text('Enroll in Program'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActivePlanCard extends StatelessWidget {
  const _NoActivePlanCard({
    required this.canceledAt,
    required this.onBrowsePlans,
    required this.onEnrollInNewPlan,
  });

  final DateTime? canceledAt;
  final VoidCallback onBrowsePlans;
  final VoidCallback? onEnrollInNewPlan;

  @override
  Widget build(BuildContext context) {
    final String? canceledDate = canceledAt == null
        ? null
        : DateFormat.yMMMd().add_jm().format(canceledAt!.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No active plan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your plan has been canceled. Browse available plans or enroll in a new plan anytime.',
            ),
            if (canceledDate != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.event_note_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Canceled on $canceledDate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onBrowsePlans,
                  child: const Text('Browse plans'),
                ),
                ElevatedButton(
                  onPressed: onEnrollInNewPlan,
                  child: const Text('Enroll in new plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleContextCard extends StatelessWidget {
  const _CycleContextCard({required this.cycleStatus});

  final CycleStatusResult? cycleStatus;

  @override
  Widget build(BuildContext context) {
    final String message;
    final IconData icon;

    if (cycleStatus == null) {
      message = 'Cycle data unavailable. Recommendations may be limited.';
      icon = Icons.info_outline;
    } else if (cycleStatus!.currentPhase == CyclePhase.menstrual) {
      message = 'Sharkweek active. Keep intensity conservative this week.';
      icon = Icons.water_drop_outlined;
    } else {
      message =
          'Cycle context: ${cycleStatus!.currentPhase.name} phase. Train to the day.';
      icon = Icons.insights_outlined;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.brandPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockingAccessState extends StatelessWidget {
  const _BlockingAccessState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _NoticeCard(
          title: 'Access unavailable',
          body: message,
          icon: Icons.lock_outline,
          color: Colors.red.shade700,
        ),
        const SizedBox(height: 8),
        RecoverableAccessBanner(
          message: 'Retry after checking your connection and session state.',
          onRetry: onRetry,
          title: 'Manual retry required',
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.body,
    required this.icon,
    this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ?? AppColors.textSecondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: resolvedColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastSyncedRow extends StatelessWidget {
  const _LastSyncedRow({
    required this.lastSyncedAt,
    required this.syncStatus,
  });

  final DateTime? lastSyncedAt;
  final SyncStatusModel syncStatus;

  @override
  Widget build(BuildContext context) {
    final String value = lastSyncedAt == null
        ? 'Not yet synced'
        : DateFormat.yMMMd().add_jm().format(lastSyncedAt!.toLocal());
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          'Last synced: $value',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        SyncStatusBadge(status: syncStatus),
      ],
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.statusLabel,
    required this.progress,
    required this.intensityLabel,
    required this.adjustmentLabel,
    required this.showCompleteAction,
    required this.canJump,
    required this.onJumpToWeek,
    required this.onMarkWeekComplete,
  });

  final ProgramWeek week;
  final String statusLabel;
  final double progress;
  final String intensityLabel;
  final String? adjustmentLabel;
  final bool showCompleteAction;
  final bool canJump;
  final VoidCallback? onJumpToWeek;
  final VoidCallback? onMarkWeekComplete;

  @override
  Widget build(BuildContext context) {
    final String note = week.sessions.isEmpty
        ? 'No session details yet.'
        : week.sessions.first.focus;
    final int percent = (progress * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Week ${week.week}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _ChipLabel(label: statusLabel),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _ChipLabel(label: '${week.sessions.length} workouts'),
                _ChipLabel(label: intensityLabel),
                if (adjustmentLabel != null)
                  _ChipLabel(label: adjustmentLabel!),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                OutlinedButton(
                  onPressed: canJump ? onJumpToWeek : null,
                  child: const Text('Jump to Week'),
                ),
                const SizedBox(width: 8),
                if (showCompleteAction)
                  ElevatedButton(
                    onPressed: onMarkWeekComplete,
                    child: const Text('Mark Week Complete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

double _progressForWeek({
  required ProgramWeek week,
  required EnrolledProgramModel enrollment,
  required bool isCompleted,
  required bool isCurrent,
}) {
  if (isCompleted) return 1;
  if (!isCurrent || week.sessions.isEmpty) return 0;

  final int currentDay = enrollment.currentDay.clamp(1, week.sessions.length);
  return currentDay / week.sessions.length;
}

String _intensityLabel(int weekNumber, bool isTestWeek) {
  if (isTestWeek) return 'Peak';
  if (weekNumber <= 4) return 'Build';
  if (weekNumber <= 8) return 'Push';
  return 'Peak';
}

bool _hasIncompleteData(ProgramV2 program, EnrolledProgramModel enrollment) {
  if (program.weeks.isEmpty) return true;
  if (enrollment.currentWeek > program.durationWeeks) return true;
  return program.weeks.any((ProgramWeek week) => week.sessions.isEmpty);
}
