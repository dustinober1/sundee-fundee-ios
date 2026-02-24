import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/models/program_models.dart';
import '../../auth/providers.dart';
import '../data/program_repository.dart';

const int kEnrollmentLifecycleMaxAutoRetries = 3;

enum EnrollmentLifecycleKind {
  active,
  canceled,
  validEmpty,
  recoverableFailure,
  blockingFailure,
}

class EnrollmentLifecycleState {
  const EnrollmentLifecycleState._({
    required this.kind,
    this.enrollment,
    this.latestEvent,
    this.errorMessage,
    this.retryAttempt,
    this.maxRetries,
    this.recoverable = false,
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

  const EnrollmentLifecycleState.validEmpty({
    EnrollmentEventModel? latestEvent,
  }) : this._(
          kind: EnrollmentLifecycleKind.validEmpty,
          latestEvent: latestEvent,
        );

  const EnrollmentLifecycleState.recoverableFailure({
    required String errorMessage,
    required int retryAttempt,
    required int maxRetries,
    EnrolledProgramModel? enrollment,
    EnrollmentEventModel? latestEvent,
  }) : this._(
          kind: EnrollmentLifecycleKind.recoverableFailure,
          enrollment: enrollment,
          latestEvent: latestEvent,
          errorMessage: errorMessage,
          retryAttempt: retryAttempt,
          maxRetries: maxRetries,
          recoverable: true,
        );

  const EnrollmentLifecycleState.blockingFailure({
    required String errorMessage,
    EnrolledProgramModel? enrollment,
    EnrollmentEventModel? latestEvent,
    bool recoverable = false,
  }) : this._(
          kind: EnrollmentLifecycleKind.blockingFailure,
          enrollment: enrollment,
          latestEvent: latestEvent,
          errorMessage: errorMessage,
          recoverable: recoverable,
        );

  final EnrollmentLifecycleKind kind;
  final EnrolledProgramModel? enrollment;
  final EnrollmentEventModel? latestEvent;
  final String? errorMessage;
  final int? retryAttempt;
  final int? maxRetries;
  final bool recoverable;

  bool get isActive => kind == EnrollmentLifecycleKind.active;
  bool get isCanceled => kind == EnrollmentLifecycleKind.canceled;
  bool get isValidEmpty => kind == EnrollmentLifecycleKind.validEmpty;
  bool get isRecoverableFailure =>
      kind == EnrollmentLifecycleKind.recoverableFailure;
  bool get isBlockingFailure => kind == EnrollmentLifecycleKind.blockingFailure;

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

  EnrollmentLifecycleState get fallbackContentState {
    if (enrollment != null) {
      return EnrollmentLifecycleState.active(
        enrollment: enrollment!,
        latestEvent: latestEvent,
      );
    }
    if (isCanceled) {
      return EnrollmentLifecycleState.canceled(latestEvent: latestEvent);
    }
    if (latestEvent != null &&
        (latestEvent!.eventType == EnrollmentEventType.canceled ||
            latestEvent!.eventType == EnrollmentEventType.autoHealed)) {
      return EnrollmentLifecycleState.canceled(latestEvent: latestEvent);
    }
    return EnrollmentLifecycleState.validEmpty(latestEvent: latestEvent);
  }
}

bool _isRecoverableEnrollmentReadError(Object error) {
  if (error is TimeoutException) {
    return true;
  }
  if (error is FirebaseException) {
    return error.code == 'permission-denied' ||
        error.code == 'unauthenticated' ||
        error.code == 'unavailable' ||
        error.code == 'deadline-exceeded';
  }
  return false;
}

String _recoveryMessageForError(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Access is temporarily unavailable. Check your session and retry.';
    }
    if (error.code == 'unauthenticated') {
      return 'Sign-in state expired. Refresh and retry.';
    }
    if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
      return 'Connection issue detected. We will retry automatically.';
    }
  }
  if (error is TimeoutException) {
    return 'Connection timeout detected. We will retry automatically.';
  }
  return 'We could not load plan access right now.';
}

EnrollmentLifecycleState _deriveLifecycleState({
  required EnrolledProgramModel? activeEnrollment,
  required EnrollmentEventModel? latestEvent,
}) {
  if (activeEnrollment != null) {
    return EnrollmentLifecycleState.active(
      enrollment: activeEnrollment,
      latestEvent: latestEvent,
    );
  }
  if (latestEvent != null &&
      (latestEvent.eventType == EnrollmentEventType.canceled ||
          latestEvent.eventType == EnrollmentEventType.autoHealed)) {
    return EnrollmentLifecycleState.canceled(latestEvent: latestEvent);
  }
  return EnrollmentLifecycleState.validEmpty(latestEvent: latestEvent);
}

Stream<EnrollmentLifecycleState> _buildLifecycleStream({
  required ProgramRepository repository,
  required String userId,
}) async* {
  int retryAttempt = 0;
  EnrolledProgramModel? lastKnownEnrollment;
  EnrollmentEventModel? lastKnownEvent;

  while (true) {
    try {
      yield* Rx.combineLatest2<EnrolledProgramModel?, EnrollmentEventModel?,
          EnrollmentLifecycleState>(
        repository.watchActiveEnrollment(userId: userId),
        repository.watchLatestEnrollmentEvent(userId: userId),
        (
          EnrolledProgramModel? activeEnrollment,
          EnrollmentEventModel? latestEvent,
        ) {
          retryAttempt = 0;
          lastKnownEnrollment = activeEnrollment;
          lastKnownEvent = latestEvent;
          return _deriveLifecycleState(
            activeEnrollment: activeEnrollment,
            latestEvent: latestEvent,
          );
        },
      );
      return;
    } catch (error) {
      if (!_isRecoverableEnrollmentReadError(error)) {
        debugPrint('Enrollment lifecycle blocking error: $error');
        yield EnrollmentLifecycleState.blockingFailure(
          errorMessage: error.toString(),
          enrollment: lastKnownEnrollment,
          latestEvent: lastKnownEvent,
        );
        return;
      }

      retryAttempt += 1;
      if (retryAttempt > kEnrollmentLifecycleMaxAutoRetries) {
        yield EnrollmentLifecycleState.blockingFailure(
          errorMessage:
              'Access still unavailable after retries. Tap retry to try again.',
          enrollment: lastKnownEnrollment,
          latestEvent: lastKnownEvent,
          recoverable: true,
        );
        return;
      }

      yield EnrollmentLifecycleState.recoverableFailure(
        errorMessage: _recoveryMessageForError(error),
        retryAttempt: retryAttempt,
        maxRetries: kEnrollmentLifecycleMaxAutoRetries,
        enrollment: lastKnownEnrollment,
        latestEvent: lastKnownEvent,
      );

      await Future<void>.delayed(
        Duration(milliseconds: 250 * retryAttempt),
      );
    }
  }
}

class EnrollmentLifecycleRefreshNonce extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}

final NotifierProvider<EnrollmentLifecycleRefreshNonce, int>
    enrollmentLifecycleRefreshNonceProvider =
    NotifierProvider<EnrollmentLifecycleRefreshNonce, int>(
  EnrollmentLifecycleRefreshNonce.new,
);

void refreshEnrollmentLifecycleAccess(WidgetRef ref) {
  ref.read(enrollmentLifecycleRefreshNonceProvider.notifier).bump();
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

final StreamProvider<EnrollmentLifecycleState>
    enrollmentLifecycleStateProvider =
    StreamProvider<EnrollmentLifecycleState>((Ref ref) {
  ref.watch(enrollmentLifecycleRefreshNonceProvider);
  final String? userId =
      ref.watch(authSessionStreamProvider).asData?.value.user?.uid;
  if (userId == null) {
    return Stream<EnrollmentLifecycleState>.value(
      const EnrollmentLifecycleState.validEmpty(),
    );
  }
  final ProgramRepository repository = ref.watch(programRepositoryProvider);
  return _buildLifecycleStream(
    repository: repository,
    userId: userId,
  );
});
