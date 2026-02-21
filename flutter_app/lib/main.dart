import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'shared/providers/onboarding_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
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
