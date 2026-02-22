import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_state.dart';
import 'guest_mode_store.dart';

class AuthRepository {
  AuthRepository({
    required GuestModeStore guestModeStore,
    required bool firebaseEnabled,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _guestModeStore = guestModeStore,
       _firebaseEnabled = firebaseEnabled,
       _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final GuestModeStore _guestModeStore;
  final bool _firebaseEnabled;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn? _googleSignIn;

  Stream<AuthSession> authStateChanges() async* {
    final bool guestEnabled = await _guestModeStore.isGuestModeEnabled();

    if (!_firebaseEnabled) {
      yield AuthSession(
        status: guestEnabled ? AuthStatus.guest : AuthStatus.unauthenticated,
      );
      return;
    }

    final FirebaseAuth auth = _requireAuth();
    yield await _buildSession(auth.currentUser, guestEnabled: guestEnabled);

    await for (final User? user in auth.authStateChanges()) {
      final bool currentGuestState = await _guestModeStore.isGuestModeEnabled();
      yield await _buildSession(user, guestEnabled: currentGuestState);
    }
  }

  Future<UserCredential> signInWithApple() async {
    _assertFirebaseEnabled('signInWithApple');

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

    final UserCredential userCredential = await _requireAuth()
        .signInWithCredential(credential);
    await _guestModeStore.setGuestModeEnabled(false);
    await _ensureUserDocument(userCredential.user);
    return userCredential;
  }

  Future<UserCredential> signInWithGoogle() async {
    _assertFirebaseEnabled('signInWithGoogle');

    final GoogleSignIn googleSignIn = _requireGoogleSignIn();
    await googleSignIn.initialize();
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final UserCredential userCredential = await _requireAuth()
        .signInWithCredential(credential);
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

  Future<void> completeOnboarding({required String name}) async {
    _assertFirebaseEnabled('completeOnboarding');

    final User? user = _requireAuth().currentUser;
    if (user == null) {
      throw StateError('No authenticated user found for onboarding.');
    }

    await _usersCollection.doc(user.uid).set(<String, dynamic>{
      'displayName': name,
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

    // Google Sign-In signOut may fail if the plugin was never initialized
    // (e.g., user signed in via email/Apple or used guest mode).
    try {
      await _requireGoogleSignIn().signOut();
    } on StateError catch (_) {
      // GoogleSignIn was not initialized — safe to ignore.
    }

    await _requireAuth().signOut();
  }

  Future<AuthSession> _buildSession(
    User? user, {
    required bool guestEnabled,
  }) async {
    if (user == null) {
      return AuthSession(
        status: guestEnabled ? AuthStatus.guest : AuthStatus.unauthenticated,
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _usersCollection.doc(user.uid).get();
    final bool onboardingComplete =
        userDoc.data()?['onboardingComplete'] as bool? ?? false;

    return AuthSession(
      status: onboardingComplete
          ? AuthStatus.authenticated
          : AuthStatus.needsOnboarding,
      user: user,
    );
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
