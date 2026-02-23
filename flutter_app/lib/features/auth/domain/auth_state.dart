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
  const AuthSession({required this.status, this.user});

  final AuthStatus status;
  final User? user;
}
