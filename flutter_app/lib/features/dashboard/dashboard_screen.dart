import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/offline_banner.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboard-screen'),
      appBar: AppBar(title: const Text('Dashboard')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OfflineBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to Sundee Fundee',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('nav-programs'),
                    onPressed: () => context.go('/programs'),
                    child: const Text('Programs'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('nav-progress'),
                    onPressed: () => context.go('/progress'),
                    child: const Text('Progress'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
