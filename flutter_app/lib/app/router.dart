import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/loading_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/providers.dart';
import '../features/shell/presentation/main_shell_screen.dart';
import '../features/workouts/presentation/workout_execution_screen.dart';
import '../features/workouts/presentation/workout_summary_screen.dart';
import '../features/admin/presentation/admin_programs_screen.dart';
import '../features/settings/presentation/legal_screen.dart';

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final AsyncValue<AuthSession> authSessionAsync = ref.watch(
    authSessionStreamProvider,
  );

  final AuthStatus authStatus = authSessionAsync.when(
    data: (AuthSession session) => session.status,
    error: (Object error, StackTrace stackTrace) => AuthStatus.unauthenticated,
    loading: () => AuthStatus.loading,
  );

  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const SignInScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/workout',
        name: 'workout',
        builder: (context, state) => const WorkoutExecutionScreen(),
      ),
      GoRoute(
        path: '/workout-summary/:id',
        name: 'workout_summary',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WorkoutSummaryScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/admin/programs',
        builder: (context, state) => const AdminProgramsScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final tabIndex = extra?['tabIndex'] as int? ?? 0;
          return LegalScreen(initialTabIndex: tabIndex);
        },
      ),
      GoRoute(path: '/', builder: (context, state) => const MainShellScreen()),
    ],
    redirect: (context, state) {
      final String location = state.matchedLocation;

      switch (authStatus) {
        case AuthStatus.loading:
          return location == '/loading' ? null : '/loading';
        case AuthStatus.unauthenticated:
          if (location == '/legal') return null;
          return location == '/auth' ? null : '/auth';
        case AuthStatus.needsOnboarding:
          return location == '/onboarding' ? null : '/onboarding';
        case AuthStatus.authenticated:
        case AuthStatus.guest:
          if (location == '/auth' ||
              location == '/loading' ||
              location == '/onboarding') {
            return '/';
          }
          return null;
      }
    },
  );
});
