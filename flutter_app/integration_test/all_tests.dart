import 'parity_gates/navigation_parity_test.dart' as navigation;
import 'parity_gates/onboarding_parity_test.dart' as onboarding;
import 'parity_gates/workout_parity_test.dart' as workout;
import 'parity_gates/offline_parity_test.dart' as offline;
import 'parity_gates/recommendations_parity_test.dart' as recommendations;
import 'parity_gates/sync_parity_test.dart' as sync;

void main() {
  navigation.main(); // PLAT-01: launch + navigate on all platforms
  onboarding.main(); // QUAL-01: onboarding flow parity
  workout.main(); // QUAL-01: workout flow parity
  offline.main(); // QUAL-02: offline scenarios parity
  recommendations.main(); // RECO-01, RECO-02, CHRT-01, CHRT-02: recommendations + progress parity
  sync.main(); // SYNC-01, SYNC-02, SYNC-03: sync parity
}
