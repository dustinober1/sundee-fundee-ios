import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/observability/telemetry_service.dart';
import 'firebase/firebase_bootstrap.dart';

Future<void> bootstrap() async {
  await initializeFirebase();
  if (firebaseEnabled) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    await TelemetryService.configure();
  }
  runApp(const ProviderScope(child: SundeeFundeeApp()));
}
