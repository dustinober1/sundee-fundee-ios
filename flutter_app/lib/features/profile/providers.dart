import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((Ref ref) {
  return ProfileRepository(firestore: ref.watch(firestoreProvider));
});
