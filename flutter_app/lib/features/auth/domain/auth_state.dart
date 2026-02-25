import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  needsOnboarding,
  resumeOnboarding,
  needsInjuryProfile,
  authenticated,
  guest,
}

class AuthSession {
  const AuthSession({
    required this.status,
    this.user,
    this.shouldShowRecoveryNotice = false,
    this.recoveryNoticeMessage,
  });

  final AuthStatus status;
  final User? user;
  final bool shouldShowRecoveryNotice;
  final String? recoveryNoticeMessage;
}
