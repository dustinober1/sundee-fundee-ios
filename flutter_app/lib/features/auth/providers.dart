import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/user_model.dart';
import 'data/auth_repository.dart';
import 'data/guest_mode_store.dart';
import 'domain/auth_state.dart';

const bool firebaseAuthEnabled = bool.fromEnvironment(
  'ENABLE_FIREBASE',
  defaultValue: false,
);

final guestModeStoreProvider = Provider<GuestModeStore>((Ref ref) {
  return GuestModeStore();
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn?>((Ref ref) {
  if (!firebaseAuthEnabled) {
    return null;
  }
  return GoogleSignIn.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((Ref ref) {
  return AuthRepository(
    guestModeStore: ref.watch(guestModeStoreProvider),
    firebaseEnabled: firebaseAuthEnabled,
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authSessionStreamProvider = StreamProvider<AuthSession>((Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final userProfileStreamProvider = StreamProvider<UserModel?>((Ref ref) {
  final session = ref.watch(authSessionStreamProvider).asData?.value;
  final userId = session?.user?.uid;
  if (userId == null) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).watchUserProfile(userId);
});
