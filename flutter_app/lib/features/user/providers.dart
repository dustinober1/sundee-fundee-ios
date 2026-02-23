import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/user_model.dart';
import '../auth/providers.dart';
import '../repositories/providers.dart';

final userProvider = StreamProvider<UserModel?>((Ref ref) {
  final authSession = ref.watch(authSessionStreamProvider);

  return authSession.when(
    data: (session) {
      if (session.user == null) {
        return Stream.value(null);
      }
      return ref
          .watch(userRepositoryProvider)
          .watchUser(userId: session.user!.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
