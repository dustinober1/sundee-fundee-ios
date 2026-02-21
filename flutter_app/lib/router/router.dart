import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/programs/programs_screen.dart';
import '../features/programs/program_detail_screen.dart';
import '../features/workout/workout_screen.dart';
import '../features/progress/progress_screen.dart';
import '../shared/providers/onboarding_status_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  return GoRouter(
    initialLocation: onboardingComplete ? '/dashboard' : '/onboarding',
    redirect: (context, state) {
      final isComplete = ref.read(onboardingCompleteProvider);
      final isOnboarding = state.uri.path == '/onboarding';
      if (isComplete && isOnboarding) return '/dashboard';
      if (!isComplete && !isOnboarding) return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/programs',
        builder: (context, state) => const ProgramsScreen(),
      ),
      GoRoute(
        path: '/programs/:id',
        builder: (context, state) => ProgramDetailScreen(
          programId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/workout/:programId',
        builder: (context, state) => WorkoutScreen(
          programId: state.pathParameters['programId']!,
        ),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
    ],
  );
});
