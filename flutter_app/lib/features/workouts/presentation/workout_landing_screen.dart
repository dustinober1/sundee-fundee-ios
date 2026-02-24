import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../domain/models/program_models.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/providers.dart';
import '../../profile/providers.dart';
import '../../programs/presentation/widgets/injury_adaptation_banner.dart';
import '../../programs/providers/adapted_program_provider.dart';
import '../../programs/providers/enrollment_lifecycle_provider.dart';
import '../../shared/presentation/recoverable_access_banner.dart';
import 'workout_execution_providers.dart';

class WorkoutLandingScreen extends ConsumerStatefulWidget {
  const WorkoutLandingScreen({super.key});

  @override
  ConsumerState<WorkoutLandingScreen> createState() =>
      _WorkoutLandingScreenState();
}

class _WorkoutLandingScreenState extends ConsumerState<WorkoutLandingScreen> {
  bool? _injuryBannerVisibleOverride;

  @override
  Widget build(BuildContext context) {
    // Check if there is an active workout
    final activeWorkoutState = ref.watch(workoutExecutionNotifierProvider);
    final bool isWorkoutActive = activeWorkoutState != null;
    final EnrollmentLifecycleState? rawLifecycleState =
        ref.watch(enrollmentLifecycleStateProvider).asData?.value;
    final EnrollmentLifecycleState? lifecycleState = rawLifecycleState == null
        ? null
        : (rawLifecycleState.isRecoverableFailure ||
                rawLifecycleState.isBlockingFailure
            ? rawLifecycleState.fallbackContentState
            : rawLifecycleState);
    final bool isCanceled = lifecycleState?.isCanceled ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center,
                size: 80, color: AppColors.brandPrimary),
            const SizedBox(height: 32),
            if (isCanceled) ...[
              const Text(
                'No active plan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lifecycleState?.canceledAt == null
                    ? 'Your plan has been canceled. Enroll in a new plan to start sessions.'
                    : 'Canceled on ${lifecycleState!.canceledAt!.toLocal().toString().split('.').first}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (isWorkoutActive) ...[
              const Text(
                'Workout in Progress',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pushNamed('workout'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('RESUME WORKOUT',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: AppColors.brandSecondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else ...[
              const Text(
                'Ready to crush it?',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 32),
              _buildNextSessionInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextSessionInfo(BuildContext context) {
    final lifecycleAsync = ref.watch(enrollmentLifecycleStateProvider);
    final programAsync = ref.watch(injuryAdaptedActiveProgramProvider);
    final InjuryAdaptationContext injuryContext =
        ref.watch(injuryAdaptationContextProvider);
    final bool injuryBannerVisible = _injuryBannerVisibleOverride ?? true;
    final AuthSession? session =
        ref.watch(authSessionStreamProvider).asData?.value;
    final String? userId = session?.user?.uid ??
        (session?.status == AuthStatus.guest ? 'guest' : null);

    return lifecycleAsync.when(
      data: (EnrollmentLifecycleState lifecycleState) {
        if (lifecycleState.isBlockingFailure) {
          return RecoverableAccessBanner(
            title: 'Manual retry required',
            message: lifecycleState.errorMessage ??
                'Workout access is still unavailable.',
            onRetry: () => refreshEnrollmentLifecycleAccess(ref),
          );
        }

        final bool showRecoverableBanner = lifecycleState.isRecoverableFailure;
        final EnrollmentLifecycleState contentState = showRecoverableBanner
            ? lifecycleState.fallbackContentState
            : lifecycleState;
        final EnrolledProgramModel? enrollment = contentState.enrollment;

        Widget content;
        if (contentState.isCanceled) {
          content = const Column(
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No active plan',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Your enrollment was canceled. Enroll in a new plan to start sessions.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        } else if (enrollment == null) {
          content = const Column(
            children: [
              Icon(Icons.info_outline,
                  size: 48, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No active plan',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Head over to the Programs tab to start one!',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          );
        } else {
          content = programAsync.when(
            data: (program) {
              if (program == null) {
                return const Text(
                  'No upcoming session yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                );
              }

              final week = program.weeks.firstWhere(
                (w) => w.week == enrollment.currentWeek,
                orElse: () => program.weeks.last,
              );
              if (week.sessions.isEmpty) {
                return const Text(
                  'No upcoming session yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                );
              }
              final sessionIndex = enrollment.currentDay - 1;
              final session = sessionIndex < week.sessions.length
                  ? week.sessions[sessionIndex]
                  : week.sessions.last;

              final List<String> changelog = _buildAdaptationChangelog(program);

              // Disclaimer gate — disable START SESSION until acknowledged
              final bool startBlocked = injuryContext.hasActiveInjuries &&
                  !injuryContext.disclaimerAcknowledgedForAll;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Injury banner — above the session card
                  if (injuryContext.hasActiveInjuries) ...[
                    InjuryAdaptationBanner(
                      injuryContext: injuryContext,
                      adaptationChangelog: changelog,
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
                    const SizedBox(height: 16),
                  ],
                  // Session card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: double.infinity,
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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            program.name,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Week ${enrollment.currentWeek}, Day ${enrollment.currentDay}',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.sessionName,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: startBlocked
                                ? null
                                : () => context.pushNamed('workout'),
                            icon: const Icon(Icons.flash_on),
                            label: const Text('START SESSION',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.brandPrimary,
                              disabledBackgroundColor:
                                  Colors.white.withValues(alpha: 0.4),
                              disabledForegroundColor:
                                  AppColors.brandPrimary.withValues(alpha: 0.4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          if (startBlocked) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Acknowledge the injury disclaimer to start your workout.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, st) => const Text(
              'No upcoming session yet',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!showRecoverableBanner) {
          return content;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RecoverableAccessBanner(
              message: lifecycleState.errorMessage ??
                  'We are retrying access in the background.',
              retryAttempt: lifecycleState.retryAttempt,
              maxRetries: lifecycleState.maxRetries,
              onRetry: () => refreshEnrollmentLifecycleAccess(ref),
            ),
            const SizedBox(height: 8),
            content,
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => RecoverableAccessBanner(
        title: 'Manual retry required',
        message: 'Could not load workout access state.',
        onRetry: () => refreshEnrollmentLifecycleAccess(ref),
      ),
    );
  }

  /// Builds a deduplicated list of changelog entries from the adapted program.
  List<String> _buildAdaptationChangelog(ProgramV2? program) {
    if (program == null) return const [];
    final Set<String> seen = <String>{};
    final List<String> entries = <String>[];
    int maxRecoveryPrepCount = 0;

    for (final week in program.weeks) {
      for (final session in week.sessions) {
        for (final exercise in session.exercises) {
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
}
