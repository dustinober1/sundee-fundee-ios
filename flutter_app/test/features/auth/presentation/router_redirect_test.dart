import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/app/router.dart';
import 'package:sundee_fundee_flutter/features/auth/domain/auth_state.dart';

void main() {
  group('authRedirectForLocation', () {
    test('loading redirects all routes to /loading', () {
      expect(
        authRedirectForLocation(authStatus: AuthStatus.loading, location: '/'),
        '/loading',
      );
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.loading,
          location: '/loading',
        ),
        isNull,
      );
    });

    test('unauthenticated redirects to /auth except legal', () {
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/',
        ),
        '/auth',
      );
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/auth',
        ),
        isNull,
      );
      expect(
        authRedirectForLocation(
          authStatus: AuthStatus.unauthenticated,
          location: '/legal',
        ),
        isNull,
      );
    });

    test('needsOnboarding redirects to /onboarding', () {
      for (final AuthStatus status in <AuthStatus>[
        AuthStatus.needsOnboarding,
        AuthStatus.resumeOnboarding,
        AuthStatus.needsInjuryProfile,
      ]) {
        expect(
          authRedirectForLocation(authStatus: status, location: '/'),
          '/onboarding',
        );
        expect(
          authRedirectForLocation(
            authStatus: status,
            location: '/onboarding',
          ),
          isNull,
        );
      }
    });

    test('authenticated and guest routes away from auth/loading/onboarding',
        () {
      for (final AuthStatus status in <AuthStatus>[
        AuthStatus.authenticated,
        AuthStatus.guest,
      ]) {
        expect(
          authRedirectForLocation(authStatus: status, location: '/auth'),
          '/',
        );
        expect(
          authRedirectForLocation(authStatus: status, location: '/loading'),
          '/',
        );
        expect(
          authRedirectForLocation(authStatus: status, location: '/onboarding'),
          '/',
        );
        expect(
          authRedirectForLocation(authStatus: status, location: '/'),
          isNull,
        );
      }
    });
  });
}
