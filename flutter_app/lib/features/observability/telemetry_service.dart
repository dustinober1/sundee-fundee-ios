import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class TelemetryService {
  const TelemetryService._();

  static Future<void> configure() async {
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;

    await crashlytics.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = crashlytics.recordFlutterFatalError;

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
          crashlytics.recordError(error, stackTrace, fatal: true);
          return true;
        };

    await FirebaseAnalytics.instance.logAppOpen();
    if (!kReleaseMode) {
      await crashlytics.setCustomKey('build_mode', 'debug');
    }
  }
}
