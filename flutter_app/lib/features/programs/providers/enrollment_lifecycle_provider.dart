import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../data/program_repository.dart';

enum EnrollmentLifecycleKind { active, canceled, none }

class EnrollmentLifecycleState {
  const EnrollmentLifecycleState._({
    required this.kind,
    this.enrollment,
    this.latestEvent,
  });

  const EnrollmentLifecycleState.active({
    required EnrolledProgramModel enrollment,
    EnrollmentEventModel? latestEvent,
  }) : this._(
          kind: EnrollmentLifecycleKind.active,
          enrollment: enrollment,
          latestEvent: latestEvent,
        );

  const EnrollmentLifecycleState.canceled({
    EnrollmentEventModel? latestEvent,
  }) : this._(
          kind: EnrollmentLifecycleKind.canceled,
          latestEvent: latestEvent,
        );

  const EnrollmentLifecycleState.none({
    EnrollmentEventModel? latestEvent,
  }) : this._(
          kind: EnrollmentLifecycleKind.none,
          latestEvent: latestEvent,
        );

  final EnrollmentLifecycleKind kind;
  final EnrolledProgramModel? enrollment;
  final EnrollmentEventModel? latestEvent;

  bool get isActive => kind == EnrollmentLifecycleKind.active;
  bool get isCanceled => kind == EnrollmentLifecycleKind.canceled;

  DateTime? get canceledAt {
    final EnrollmentEventModel? event = latestEvent;
    if (event == null) {
      return enrollment?.canceledAt;
    }
    if (event.eventType == EnrollmentEventType.canceled ||
        event.eventType == EnrollmentEventType.autoHealed) {
      return event.occurredAt;
    }
    return enrollment?.canceledAt;
  }
}

final StreamProvider<EnrollmentEventModel?> latestEnrollmentEventProvider =
    StreamProvider<EnrollmentEventModel?>((Ref ref) {
  final String? userId =
      ref.watch(authSessionStreamProvider).asData?.value.user?.uid;
  if (userId == null) {
    return Stream<EnrollmentEventModel?>.value(null);
  }
  final ProgramRepository repository = ref.watch(programRepositoryProvider);
  return repository.watchLatestEnrollmentEvent(userId: userId);
});

final Provider<AsyncValue<EnrollmentLifecycleState>>
    enrollmentLifecycleStateProvider =
    Provider<AsyncValue<EnrollmentLifecycleState>>((Ref ref) {
  final AsyncValue<EnrolledProgramModel?> activeEnrollmentAsync =
      ref.watch(activeEnrollmentProvider);
  final AsyncValue<EnrollmentEventModel?> latestEventAsync =
      ref.watch(latestEnrollmentEventProvider);

  if (activeEnrollmentAsync.hasError) {
    return AsyncValue<EnrollmentLifecycleState>.error(
      activeEnrollmentAsync.error!,
      activeEnrollmentAsync.stackTrace!,
    );
  }
  if (latestEventAsync.hasError) {
    return AsyncValue<EnrollmentLifecycleState>.error(
      latestEventAsync.error!,
      latestEventAsync.stackTrace!,
    );
  }

  final EnrolledProgramModel? activeEnrollment =
      activeEnrollmentAsync.asData?.value;
  final EnrollmentEventModel? latestEvent = latestEventAsync.asData?.value;

  if (activeEnrollment != null) {
    return AsyncValue<EnrollmentLifecycleState>.data(
      EnrollmentLifecycleState.active(
        enrollment: activeEnrollment,
        latestEvent: latestEvent,
      ),
    );
  }

  if (latestEvent != null &&
      (latestEvent.eventType == EnrollmentEventType.canceled ||
          latestEvent.eventType == EnrollmentEventType.autoHealed)) {
    return AsyncValue<EnrollmentLifecycleState>.data(
      EnrollmentLifecycleState.canceled(latestEvent: latestEvent),
    );
  }

  if (activeEnrollmentAsync.isLoading && latestEventAsync.isLoading) {
    return const AsyncValue<EnrollmentLifecycleState>.loading();
  }

  return AsyncValue<EnrollmentLifecycleState>.data(
    EnrollmentLifecycleState.none(latestEvent: latestEvent),
  );
});
