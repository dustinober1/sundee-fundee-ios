import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/programs/programs_screen.dart';
import '../features/workout/workout_screen.dart';
import '../features/progress/progress_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
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
