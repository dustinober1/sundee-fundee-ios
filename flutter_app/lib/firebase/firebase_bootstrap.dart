import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

const bool firebaseEnabled = bool.fromEnvironment(
  'ENABLE_FIREBASE',
  defaultValue: false,
);

Future<void> initializeFirebase() async {
  if (!firebaseEnabled) {
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
