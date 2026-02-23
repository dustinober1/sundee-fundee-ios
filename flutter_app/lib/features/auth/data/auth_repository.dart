import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_state.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/user_model.dart';
import 'guest_mode_store.dart';

class AuthRepository {
  AuthRepository({
    required GuestModeStore guestModeStore,
    required bool firebaseEnabled,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _guestModeStore = guestModeStore,
        _firebaseEnabled = firebaseEnabled,
        _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final GuestModeStore _guestModeStore;
  final bool _firebaseEnabled;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn? _googleSignIn;
  bool _googleSignInInitialized = false;

  Stream<AuthSession> authStateChanges() {
    if (!_firebaseEnabled) {
      return Stream.fromFuture(_guestModeStore.isGuestModeEnabled()).map(
        (guestEnabled) => AuthSession(
          status: guestEnabled ? AuthStatus.guest : AuthStatus.unauthenticated,
        ),
      );
    }

    final FirebaseAuth auth = _requireAuth();

    return Rx.combineLatest2(
      auth.authStateChanges(),
      Stream.fromFuture(_guestModeStore.isGuestModeEnabled()).concatWith([
        _guestModeStore.watchGuestModeChanges(),
      ]),
      (User? user, bool guestEnabled) => (user, guestEnabled),
    ).switchMap((data) {
      final user = data.$1;
      final guestEnabled = data.$2;

      if (user == null) {
        return Stream.value(
          AuthSession(
            status:
                guestEnabled ? AuthStatus.guest : AuthStatus.unauthenticated,
          ),
        );
      }

      // Watch the user document for changes (like onboardingComplete)
      return _usersCollection.doc(user.uid).snapshots().map((userDoc) {
        final bool onboardingComplete =
            userDoc.data()?['onboardingComplete'] as bool? ?? false;

        return AuthSession(
          status: onboardingComplete
              ? AuthStatus.authenticated
              : AuthStatus.needsOnboarding,
          user: user,
        );
      });
    });
  }

  Stream<UserModel?> watchUserProfile(String userId) {
    if (!_firebaseEnabled) {
      return Stream.value(null);
    }

    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromJson(doc.data()!);
    });
  }

  Future<UserCredential> signInWithApple() async {
    _assertFirebaseEnabled('signInWithApple');

    if (kIsWeb) {
      final AppleAuthProvider appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      final UserCredential userCredential =
          await _requireAuth().signInWithPopup(appleProvider);
      await _guestModeStore.setGuestModeEnabled(false);
      await _ensureUserDocument(userCredential.user);
      return userCredential;
    }

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final String? identityToken = appleCredential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('Apple Sign-In did not return an identity token.');
    }

    final OAuthCredential credential = OAuthProvider('apple.com').credential(
      idToken: identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final UserCredential userCredential =
        await _requireAuth().signInWithCredential(credential);
    await _guestModeStore.setGuestModeEnabled(false);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    _assertFirebaseEnabled('signInWithGoogle');

    if (kIsWeb) {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await _requireAuth().signInWithPopup(googleProvider);
      await _guestModeStore.setGuestModeEnabled(false);
      await _ensureUserDocument(userCredential.user);
      return userCredential;
    }

    final GoogleSignIn googleSignIn = _requireGoogleSignIn();
    await googleSignIn.initialize();
    _googleSignInInitialized = true;
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    
    final String? idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final UserCredential userCredential =
        await _requireAuth().signInWithCredential(credential);
    await _guestModeStore.setGuestModeEnabled(false);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _assertFirebaseEnabled('signInWithEmailPassword');

    final UserCredential userCredential = await _requireAuth()
        .signInWithEmailAndPassword(email: email, password: password);

    await _guestModeStore.setGuestModeEnabled(false);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> createUserWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _assertFirebaseEnabled('createUserWithEmailPassword');

    final UserCredential userCredential = await _requireAuth()
        .createUserWithEmailAndPassword(email: email, password: password);

    await _guestModeStore.setGuestModeEnabled(false);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<void> completeOnboarding({
    required String name,
    required Gender gender,
    required bool cycleTrackingEnabled,
  }) async {
    _assertFirebaseEnabled('completeOnboarding');

    final User? user = _requireAuth().currentUser;
    if (user == null) {
      throw StateError('No authenticated user found for onboarding.');
    }

    await _usersCollection.doc(user.uid).set(<String, dynamic>{
      'displayName': name,
      'genderRaw': gender.name,
      'cycleTrackingEnabled': cycleTrackingEnabled,
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update the Auth profile so the name is available in the User object immediately
    await user.updateDisplayName(name);
  }

  Future<void> continueAsGuest() async {
    if (_firebaseEnabled) {
      await _requireAuth().signOut();
    }
    await _guestModeStore.setGuestModeEnabled(true);
  }

  Future<void> signOut() async {
    await _guestModeStore.setGuestModeEnabled(false);

    if (!_firebaseEnabled) {
      return;
    }

    // Only sign out of Google if the plugin was actually initialized
    // during this session; calling signOut before init crashes on web.
    if (_googleSignInInitialized) {
      await _requireGoogleSignIn().signOut();
    }

    await _requireAuth().signOut();
  }

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) {
      throw StateError('Unable to create profile document: user is null.');
    }

    final DocumentReference<Map<String, dynamic>> ref = _usersCollection.doc(
      user.uid,
    );

    await ref.set(<String, dynamic>{
      'id': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'providerId': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'onboardingComplete': false,
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _requireFirestore().collection('users');
  }

  FirebaseAuth _requireAuth() {
    final FirebaseAuth? auth = _auth;
    if (auth == null) {
      throw StateError('FirebaseAuth is not available.');
    }
    return auth;
  }

  FirebaseFirestore _requireFirestore() {
    final FirebaseFirestore? firestore = _firestore;
    if (firestore == null) {
      throw StateError('FirebaseFirestore is not available.');
    }
    return firestore;
  }

  GoogleSignIn _requireGoogleSignIn() {
    final GoogleSignIn? googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw StateError('GoogleSignIn is not available.');
    }
    return googleSignIn;
  }

  void _assertFirebaseEnabled(String methodName) {
    if (!_firebaseEnabled) {
      throw StateError(
        '$methodName requires ENABLE_FIREBASE=true and initialized Firebase bindings.',
      );
    }
  }
}
