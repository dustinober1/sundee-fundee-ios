import 'parity_gates/navigation_parity_test.dart' as navigation;
import 'parity_gates/onboarding_parity_test.dart' as onboarding;
import 'parity_gates/workout_parity_test.dart' as workout;
import 'parity_gates/offline_parity_test.dart' as offline;

void main() {
  navigation.main(); // PLAT-01: launch + navigate on all platforms
  onboarding.main(); // QUAL-01: onboarding flow parity
  workout.main(); // QUAL-01: workout flow parity
  offline.main(); // QUAL-02: offline scenarios parity
}
