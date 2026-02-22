import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/domain/auth_state.dart';
import '../auth/providers.dart';
import '../../domain/models/lift_max_model.dart';
import '../repositories/providers.dart';

final maxesUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authSessionStreamProvider).value;
  if (session?.status == AuthStatus.guest) {
    return 'guest';
  }
  return session?.user?.uid;
});

final liftMaxesProvider = StreamProvider<List<LiftMaxModel>>((ref) {
  final userId = ref.watch(maxesUserIdProvider);
  if (userId == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(liftRepositoryProvider);
  return repository.watchLiftMaxes(userId: userId);
});

class MaxesController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> saveMax(LiftMaxModel max) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(liftRepositoryProvider);
      await repository.saveLiftMax(userId: max.userId, liftMax: max);
    });
  }
}

final maxesControllerProvider = AsyncNotifierProvider<MaxesController, void>(() {
  return MaxesController();
});
