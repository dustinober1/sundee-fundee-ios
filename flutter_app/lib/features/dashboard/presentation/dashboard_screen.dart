import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../domain/models/completed_workout_model.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../cycle/providers.dart';
import '../../migration/providers.dart';
import '../../programs/data/program_repository.dart';
import '../../programs/providers/adapted_program_provider.dart';
import '../../programs/providers/enrollment_lifecycle_provider.dart';
import '../../repositories/providers.dart';
import '../../shared/presentation/recoverable_access_banner.dart';
import '../../shared/presentation/sync_status_badge.dart';
import 'cycle_insights_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const String _defaultRecoveryNoticeMessage =
      'We recovered your onboarding profile from training history.';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _recoveryNoticeShownInSession = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession>>(authSessionStreamProvider, (
      AsyncValue<AuthSession>? _,
      AsyncValue<AuthSession> next,
    ) {
      final AuthSession? nextSession = next.asData?.value;
      if (nextSession == null) {
        return;
      }

      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      if (nextSession.status == AuthStatus.unauthenticated ||
          nextSession.status == AuthStatus.guest) {
        _recoveryNoticeShownInSession = false;
      }

      if (nextSession.shouldShowRecoveryNotice &&
          !_recoveryNoticeShownInSession) {
        _recoveryNoticeShownInSession = true;
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              nextSession.recoveryNoticeMessage ??
                  DashboardScreen._defaultRecoveryNoticeMessage,
            ),
          ),
        );
      }

      final String? userId = nextSession.user?.uid;
      if (userId == null) {
        return;
      }

      unawaited(
        ref
            .read(legacyMigrationOrchestratorProvider)
            .migrateIfNeeded(userId: userId)
            .then((_) {})
            .catchError((Object error, StackTrace stackTrace) {
          messenger?.showSnackBar(
            SnackBar(content: Text('Legacy migration failed: $error')),
          );
        }),
      );
    });

    final AuthSession? session =
        ref.watch(authSessionStreamProvider).asData?.value;
    final cycleStatus = ref.watch(cycleStatusProvider);
    final periodLogs = ref.watch(periodLogsProvider).asData?.value ?? const [];
    final cycleControllerState = ref.watch(cycleControllerProvider);
    final syncStatus = ref.watch(cycleSyncStatusProvider);
    final InjuryAdaptationContext injuryContext =
        ref.watch(injuryAdaptationContextProvider);
    final DateTime? lastSyncedAt =
        periodLogs.isEmpty ? null : periodLogs.first.startDate;

    final String stateMessage;
    switch (session?.status) {
      case AuthStatus.guest:
        stateMessage = 'Guest mode active';
      case AuthStatus.authenticated:
        stateMessage = 'Signed in as ${session?.user?.email ?? 'user'}';
      case AuthStatus.needsOnboarding:
      case AuthStatus.resumeOnboarding:
      case AuthStatus.needsInjuryProfile:
        stateMessage = 'Onboarding required';
      case AuthStatus.unauthenticated:
      case AuthStatus.loading:
      case null:
        stateMessage = 'Not signed in';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, ${session?.user?.displayName != null && session!.user!.displayName!.isNotEmpty ? session.user!.displayName : 'User'}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            if (cycleControllerState.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DashboardInfoBanner(
                  icon: Icons.sync_problem_outlined,
                  message: 'Changes could not be saved. Retry.',
                ),
              ),
            if (cycleStatus == null)
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                child: _DashboardInfoBanner(
                  icon: Icons.info_outline,
                  message:
                      'Cycle data unavailable. Recommendations may be limited.',
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Last synced: ${lastSyncedAt == null ? 'No cycle records yet' : DateFormat.yMMMd().format(lastSyncedAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  SyncStatusBadge(status: syncStatus),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Next Workout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            if (injuryContext.hasActiveInjuries) ...<Widget>[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _InjuryActiveIndicator(
                  injuryCount: injuryContext.activeInjuries.length,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _NextWorkoutCard(),
            const SizedBox(height: 32),
            const CycleInsightsChart(),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Workout History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _WorkoutHistoryList(),
            const SizedBox(height: 32),
            Center(
              child: Text(
                stateMessage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardInfoBanner extends StatelessWidget {
  const _DashboardInfoBanner({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight indicator shown on the dashboard when there are active injuries.
/// Tapping it does nothing — it is purely informational. For full details,
/// the user navigates to the Programs tab where the full banner is displayed.
class _InjuryActiveIndicator extends StatelessWidget {
  const _InjuryActiveIndicator({required this.injuryCount});

  final int injuryCount;

  @override
  Widget build(BuildContext context) {
    final String label = injuryCount == 1
        ? '1 active injury — plan adapted'
        : '$injuryCount active injuries — plan adapted';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkoutHistoryList extends ConsumerWidget {
  const _WorkoutHistoryList();

  String _formatProgramId(String id) {
    if (id == 'squad-squat') return '12-Week Squad Squat Peak';
    return id
        .split('-')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionStreamProvider).asData?.value;
    final userId = session?.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view history.'));
    }

    final workoutsAsync =
        ref.watch(workoutRepositoryProvider).watchWorkouts(userId: userId);

    return StreamBuilder(
      stream: workoutsAsync,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final workouts = snapshot.data ?? [];

        if (workouts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              children: [
                Icon(Icons.history_outlined,
                    size: 48, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No workouts completed yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: workouts.map((workout) {
            return Dismissible(
              key: Key(workout.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Workout?'),
                    content: const Text(
                        'This will permanently remove this workout from your history.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('DELETE'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                ref.read(workoutRepositoryProvider).deleteWorkout(
                      userId: userId,
                      workoutId: workout.id,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout deleted')),
                );
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: _WorkoutHistoryTile(
                workout: workout,
                programLabel: _formatProgramId(workout.programId),
                enrollmentEventStream: workout.enrollmentId == null
                    ? null
                    : ref
                        .read(programRepositoryProvider)
                        .watchLatestEnrollmentEvent(
                          userId: userId,
                          enrollmentId: workout.enrollmentId,
                        ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({
    required this.workout,
    required this.programLabel,
    required this.enrollmentEventStream,
  });

  final CompletedWorkoutModel workout;
  final String programLabel;
  final Stream<EnrollmentEventModel?>? enrollmentEventStream;

  bool _isCanceledMarkerEvent(EnrollmentEventModel? event) {
    if (event == null) {
      return false;
    }
    return event.eventType == EnrollmentEventType.canceled ||
        event.eventType == EnrollmentEventType.autoHealed;
  }

  @override
  Widget build(BuildContext context) {
    if (enrollmentEventStream == null) {
      return _buildTile(context, isCanceledPlan: false);
    }

    return StreamBuilder<EnrollmentEventModel?>(
      stream: enrollmentEventStream,
      builder: (BuildContext context,
          AsyncSnapshot<EnrollmentEventModel?> snapshot) {
        return _buildTile(
          context,
          isCanceledPlan: _isCanceledMarkerEvent(snapshot.data),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required bool isCanceledPlan,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.brandPrimary,
            size: 20,
          ),
        ),
        title: Text(
          '$programLabel - W${workout.week}D${workout.day}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${workout.completedAt.toString().split(' ')[0]} • ${workout.duration} mins',
            ),
            if (isCanceledPlan)
              const Text(
                'Canceled plan',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          context.pushNamed(
            'workout_summary',
            pathParameters: {'id': workout.id},
          );
        },
      ),
    );
  }
}

class _NextWorkoutCard extends ConsumerWidget {
  const _NextWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleAsync = ref.watch(enrollmentLifecycleStateProvider);
    final programAsync = ref.watch(injuryAdaptedActiveProgramProvider);
    final ProgramAdaptationContext adaptationContext = ref.watch(
      programAdaptationContextProvider,
    );

    return lifecycleAsync.when(
      data: (EnrollmentLifecycleState lifecycleState) {
        final EnrollmentLifecycleState contentState =
            lifecycleState.isRecoverableFailure ||
                    lifecycleState.isBlockingFailure
                ? lifecycleState.fallbackContentState
                : lifecycleState;

        if (lifecycleState.isBlockingFailure) {
          return _BlockingAccessCard(
            message: lifecycleState.errorMessage ??
                'Could not validate training access.',
            onRetry: () => refreshEnrollmentLifecycleAccess(ref),
          );
        }

        final Widget contentCard = _buildContentCard(
          context: context,
          contentState: contentState,
          programAsync: programAsync,
          adaptationContext: adaptationContext,
        );

        if (!lifecycleState.isRecoverableFailure) {
          return contentCard;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RecoverableAccessBanner(
                message: lifecycleState.errorMessage ??
                    'We are retrying access in the background.',
                retryAttempt: lifecycleState.retryAttempt,
                maxRetries: lifecycleState.maxRetries,
                onRetry: () => refreshEnrollmentLifecycleAccess(ref),
              ),
            ),
            contentCard,
          ],
        );
      },
      loading: () => const _LoadingCard(),
      error: (err, stack) => _BlockingAccessCard(
        message: 'Could not load next workout access state.',
        onRetry: () => refreshEnrollmentLifecycleAccess(ref),
      ),
    );
  }

  Widget _buildContentCard({
    required BuildContext context,
    required EnrollmentLifecycleState contentState,
    required AsyncValue<ProgramV2?> programAsync,
    required ProgramAdaptationContext adaptationContext,
  }) {
    if (contentState.isCanceled) {
      return _NoActiveProgramCard(canceledAt: contentState.canceledAt);
    }

    final EnrolledProgramModel? enrollment = contentState.enrollment;
    if (enrollment == null) {
      return const _NoActiveProgramCard();
    }

    return programAsync.when(
      data: (ProgramV2? program) {
        if (program == null) {
          return const _NoUpcomingSessionCard();
        }

        final ProgramWeek week = program.weeks.firstWhere(
          (ProgramWeek item) => item.week == enrollment.currentWeek,
          orElse: () => program.weeks.last,
        );
        if (week.sessions.isEmpty) {
          return const _NoUpcomingSessionCard();
        }

        final int sessionIndex = enrollment.currentDay - 1;
        final ProgramSession session = sessionIndex < week.sessions.length
            ? week.sessions[sessionIndex]
            : week.sessions.last;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimary,
                  AppColors.brandPrimary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        program.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.fitness_center,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  if (adaptationContext.isAdapted) ...<Widget>[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Text(
                        'Cycle-adjusted',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Week ${enrollment.currentWeek}, Session ${enrollment.currentDay}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Focus: ${session.focus}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.pushNamed('workout');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'START SESSION',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (Object _, StackTrace __) => const _NoUpcomingSessionCard(),
    );
  }
}

class _NoActiveProgramCard extends StatelessWidget {
  const _NoActiveProgramCard({this.canceledAt});

  final DateTime? canceledAt;

  @override
  Widget build(BuildContext context) {
    final String? canceledDate =
        canceledAt == null ? null : DateFormat.yMMMd().format(canceledAt!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.info_outline,
                color: AppColors.textSecondary, size: 32),
            const SizedBox(height: 8),
            const Text(
              'No active plan',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (canceledDate != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Canceled on $canceledDate',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Navigate to programs tab
              },
              child: const Text('BROWSE PLANS'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoUpcomingSessionCard extends StatelessWidget {
  const _NoUpcomingSessionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            const Icon(Icons.info_outline,
                color: AppColors.textSecondary, size: 28),
            const SizedBox(height: 8),
            const Text(
              'No upcoming session yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {},
              child: const Text('REFRESH'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard(this.error);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading next workout: $error'),
      ),
    );
  }
}

class _BlockingAccessCard extends StatelessWidget {
  const _BlockingAccessCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ErrorCard(message),
            const SizedBox(height: 8),
            RecoverableAccessBanner(
              title: 'Manual retry required',
              message: 'Access check is still failing. Retry to continue.',
              onRetry: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
