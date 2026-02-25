import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sundee_fundee_flutter/firebase_options.dart';

const bool _firebaseEnabled = bool.fromEnvironment(
  'ENABLE_FIREBASE',
  defaultValue: false,
);
const bool _useEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

class VerificationAccount {
  const VerificationAccount({required this.email, required this.password});

  final String email;
  final String password;
}

class FirebaseEmulatorTestHarness {
  static const VerificationAccount verificationAccount = VerificationAccount(
    email: String.fromEnvironment(
      'VERIFICATION_ACCOUNT_EMAIL',
      defaultValue: 'elizabethober@me.com',
    ),
    password: String.fromEnvironment(
      'VERIFICATION_ACCOUNT_PASSWORD',
      defaultValue: 'SundeeFundee!234',
    ),
  );

  static const String _configuredHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '',
  );

  static String get _resolvedHost {
    if (_configuredHost.isNotEmpty) {
      return _configuredHost;
    }
    return kIsWeb ? 'localhost' : '127.0.0.1';
  }

  static const int _authPort = int.fromEnvironment(
    'FIREBASE_AUTH_EMULATOR_PORT',
    defaultValue: 9099,
  );
  static const int _firestorePort = int.fromEnvironment(
    'FIRESTORE_EMULATOR_PORT',
    defaultValue: 8080,
  );

  static Future<void> initializeHarness() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    if (!_firebaseEnabled) {
      throw StateError(
        'ENABLE_FIREBASE=true is required for critical access integration checks.',
      );
    }
    if (!_useEmulators) {
      throw StateError(
        'USE_FIREBASE_EMULATORS=true is required to avoid live backend integration runs.',
      );
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseAuth.instance.useAuthEmulator(_resolvedHost, _authPort);
    FirebaseFirestore.instance
        .useFirestoreEmulator(_resolvedHost, _firestorePort);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  static Future<UserCredential> seedVerificationAccount() async {
    final VerificationAccount account = verificationAccount;
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') {
        rethrow;
      }
      return FirebaseAuth.instance.signInWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );
    }
  }

  static Future<void> checkpoint({
    required String name,
    required bool condition,
  }) async {
    if (!condition) {
      throw StateError('checkpoint failed: $name');
    }
  }
}
