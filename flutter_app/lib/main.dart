import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'shared/providers/onboarding_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  runApp(
    ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith(
          () => OnboardingStatusNotifier(initialState: onboardingComplete),
        ),
      ],
      child: const SundeeFundeeApp(),
    ),
  );
}
