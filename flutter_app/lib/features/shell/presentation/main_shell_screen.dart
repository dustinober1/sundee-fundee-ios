import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cycle/presentation/cycle_tracking_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../maxes/presentation/max_lifts_screen.dart';
import '../../programs/presentation/programs_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shared/presentation/placeholder_feature_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Dashboard',
    'Programs',
    'Workout',
    'Maxes',
    'Cycle',
    'Settings',
  ];

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    ProgramsScreen(),
    PlaceholderFeatureScreen(
      title: 'Workout',
      subtitle: 'Workout execution and set-by-set logging will be added next.',
    ),
    MaxLiftsScreen(),
    CycleTrackingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            return _screens[_selectedIndex];
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Maxes',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            label: 'Cycle',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
