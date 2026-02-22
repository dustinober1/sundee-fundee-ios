import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/user_storage_service.dart';

final firebaseStorageProvider = Provider<FirebaseStorage?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseStorage.instance;
});

final userStorageServiceProvider = Provider<UserStorageService>((Ref ref) {
  final FirebaseStorage? storage = ref.watch(firebaseStorageProvider);
  if (storage == null) {
    throw StateError(
      'UserStorageService requires ENABLE_FIREBASE=true and Firebase Storage.',
    );
  }

  return UserStorageService(storage: storage);
});
