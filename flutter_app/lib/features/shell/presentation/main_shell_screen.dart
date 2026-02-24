import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../../cycle/presentation/cycle_tracking_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../maxes/presentation/max_lifts_screen.dart';
import '../../programs/presentation/programs_screen.dart';
import '../../programs/providers/enrollment_lifecycle_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../workouts/presentation/workout_landing_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshEnrollmentLifecycleAccess(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileStreamProvider).asData?.value;
    final bool showCycleTab = userProfile?.cycleTrackingEnabled ?? false;

    final List<String> titles = [
      'Dashboard',
      'Workout',
      'Programs',
      'Maxes',
      if (showCycleTab) 'Cycle',
      'Settings',
    ];

    final List<Widget> screens = [
      const DashboardScreen(),
      const WorkoutLandingScreen(),
      const ProgramsScreen(),
      const MaxLiftsScreen(),
      if (showCycleTab) const CycleTrackingScreen(),
      const SettingsScreen(),
    ];

    final List<NavigationDestination> destinations = [
      const NavigationDestination(
          icon: Icon(Icons.home_outlined), label: 'Home'),
      const NavigationDestination(
        icon: Icon(Icons.fitness_center),
        label: 'Workout',
      ),
      const NavigationDestination(
        icon: Icon(Icons.list_alt),
        label: 'Programs',
      ),
      const NavigationDestination(
        icon: Icon(Icons.show_chart),
        label: 'Maxes',
      ),
      if (showCycleTab)
        const NavigationDestination(
          icon: Icon(Icons.monitor_heart_outlined),
          label: 'Cycle',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];

    // Ensure _selectedIndex is not out of bounds after filtering
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(title: Text(titles[_selectedIndex])),
      body: SafeArea(
        child: screens[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
