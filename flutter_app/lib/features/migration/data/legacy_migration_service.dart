import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LegacyMigrationService {
  static const MethodChannel _channel = MethodChannel(
    'com.sundeefundee.app/legacy_migration',
  );

  bool get supportsLegacyMigration {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<bool> isMigrationComplete({required String userId}) async {
    if (!supportsLegacyMigration) {
      return true;
    }

    final dynamic result = await _channel.invokeMethod<dynamic>(
      'isMigrationComplete',
      <String, dynamic>{'userId': userId},
    );

    if (result is! bool) {
      throw StateError('isMigrationComplete must return a bool value.');
    }

    return result;
  }

  Future<Map<String, dynamic>> readLegacySnapshot({
    required String userId,
  }) async {
    if (!supportsLegacyMigration) {
      return <String, dynamic>{};
    }

    final dynamic result = await _channel.invokeMethod<dynamic>(
      'readLegacySnapshot',
      <String, dynamic>{'userId': userId},
    );

    if (result is! Map<Object?, Object?>) {
      throw StateError('readLegacySnapshot must return a map payload.');
    }

    return result.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }

  Future<void> markMigrationComplete({required String userId}) async {
    if (!supportsLegacyMigration) {
      return;
    }

    await _channel.invokeMethod<void>(
      'markMigrationComplete',
      <String, dynamic>{'userId': userId},
    );
  }
}
