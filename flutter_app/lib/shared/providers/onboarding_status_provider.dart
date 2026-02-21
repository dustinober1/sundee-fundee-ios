import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the user has completed onboarding.
///
/// Defaults to `false`. [main.dart] overrides this with the persisted
/// SharedPreferences value before [runApp], so the router can set the
/// correct [initialLocation] on first build.
class OnboardingStatusNotifier extends Notifier<bool> {
  final bool initialState;

  OnboardingStatusNotifier({this.initialState = false});

  @override
  bool build() => initialState;

  void setComplete() => state = true;
}

final onboardingCompleteProvider =
    NotifierProvider<OnboardingStatusNotifier, bool>(
  () => OnboardingStatusNotifier(),
);
