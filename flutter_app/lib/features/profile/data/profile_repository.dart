import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/injury_profile_model.dart';
import '../../../domain/models/user_model.dart';

class ProfileRepository {
  ProfileRepository({required FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  final List<Future<void> Function()> _pendingWrites =
      <Future<void> Function()>[];

  Stream<UserModel?> watchUserProfile(String userId) {
    final FirebaseFirestore? firestore = _firestore;
    if (firestore == null) {
      return Stream<UserModel?>.value(null);
    }

    return firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final Map<String, dynamic> normalized = _normalizeDocData(
        userId: userId,
        raw: doc.data() ?? <String, dynamic>{},
      );
      _ensureDefaultsNonBlocking(
        userId: userId,
        existing: doc.data() ?? <String, dynamic>{},
        normalized: normalized,
      );
      return UserModel.fromJson(normalized);
    });
  }

  Future<void> upsertOnboardingProfile({
    required String userId,
    required String name,
    required Gender gender,
    required bool cycleTrackingEnabled,
  }) async {
    await _performWrite(() async {
      await _users.doc(userId).set(<String, dynamic>{
        'displayName': name,
        'name': name,
        'genderRaw': gender.name,
        'cycleTrackingEnabled': cycleTrackingEnabled,
        'onboardingComplete': true,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveInjuryProfile({
    required String userId,
    required InjuryProfileModel injury,
  }) async {
    await _performWrite(() async {
      final Map<String, dynamic> current = await _readUserData(userId);
      final List<InjuryProfileModel> injuries = List<InjuryProfileModel>.from(
        _normalizedInjuries(current),
      );
      final int existingIndex = injuries.indexWhere(
        (InjuryProfileModel item) => item.id == injury.id,
      );

      if (existingIndex == -1) {
        injuries.add(injury);
      } else {
        injuries[existingIndex] = injury;
      }

      await _users.doc(userId).set(<String, dynamic>{
        'injuryProfiles':
            injuries.map((InjuryProfileModel item) => item.toJson()).toList(),
        'profileUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> resolveInjury({
    required String userId,
    required String injuryId,
    DateTime? resolvedAt,
  }) async {
    await _performWrite(() async {
      final DateTime now = resolvedAt ?? DateTime.now().toUtc();
      final Map<String, dynamic> current = await _readUserData(userId);
      final List<InjuryProfileModel> injuries =
          _normalizedInjuries(current).map((
        InjuryProfileModel item,
      ) {
        if (item.id != injuryId) {
          return item;
        }
        return item.copyWith(
          status: InjuryStatus.resolved,
          resolvedAt: now,
          updatedAt: now,
        );
      }).toList();

      await _users.doc(userId).set(<String, dynamic>{
        'injuryProfiles':
            injuries.map((InjuryProfileModel item) => item.toJson()).toList(),
        'profileUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> clearInjuryProfiles(String userId) async {
    await _performWrite(() async {
      await _users.doc(userId).set(<String, dynamic>{
        'injuryProfiles': <Map<String, dynamic>>[],
        'profileUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> retryPendingWrites() async {
    if (_pendingWrites.isEmpty) {
      return;
    }

    final List<Future<void> Function()> queued =
        List<Future<void> Function()>.from(
      _pendingWrites,
    );
    _pendingWrites.clear();
    for (final Future<void> Function() action in queued) {
      try {
        await action();
      } catch (_) {
        _pendingWrites.add(action);
      }
    }
  }

  int get pendingWriteCount => _pendingWrites.length;

  CollectionReference<Map<String, dynamic>> get _users {
    final FirebaseFirestore? firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firestore is not available for profile operations.');
    }
    return firestore.collection('users');
  }

  Future<void> _performWrite(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _pendingWrites.add(action);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _readUserData(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _users.doc(userId).get();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeDocData({
    required String userId,
    required Map<String, dynamic> raw,
  }) {
    final DateTime now = DateTime.now().toUtc();
    return <String, dynamic>{
      'id': raw['id'] ?? userId,
      'name': raw['name'] ?? raw['displayName'] ?? raw['firstName'] ?? '',
      'displayName': raw['displayName'] ?? raw['name'] ?? '',
      'experienceLevelRaw': raw['experienceLevelRaw'] ?? raw['experienceLevel'],
      'primaryGoalRaw': raw['primaryGoalRaw'] ?? raw['primaryGoal'],
      'genderRaw': raw['genderRaw'] ?? raw['gender'],
      'createdAt':
          raw['createdAt'] ?? raw['updatedAt'] ?? now.toIso8601String(),
      'appleUserID': raw['appleUserID'] ?? raw['appleUserId'] ?? '',
      'cycleTrackingEnabled': raw['cycleTrackingEnabled'] ?? false,
      'onboardingComplete': raw['onboardingComplete'] ?? false,
      'profileUpdatedAt':
          raw['profileUpdatedAt'] ?? raw['updatedAt'] ?? now.toIso8601String(),
      'injuryProfiles': _normalizedInjuries(raw)
          .map((InjuryProfileModel x) => x.toJson())
          .toList(),
    };
  }

  List<InjuryProfileModel> _normalizedInjuries(Map<String, dynamic> raw) {
    final dynamic rawProfiles = raw['injuryProfiles'];
    if (rawProfiles is List) {
      return rawProfiles
          .whereType<Map>()
          .map(
            (Map item) =>
                InjuryProfileModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    final dynamic legacy = raw['injuryProfile'];
    if (legacy is Map) {
      final DateTime now = DateTime.now().toUtc();
      return <InjuryProfileModel>[
        InjuryProfileModel(
          id: legacy['id'] as String? ?? 'legacy-injury',
          location: legacy['location'] as String? ?? '',
          movementLimitations: legacy['movementLimitations'] as String? ?? '',
          recoveryGoal: legacy['recoveryGoal'] as String? ?? '',
          status: (legacy['status'] as String?) == 'resolved'
              ? InjuryStatus.resolved
              : InjuryStatus.active,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    return const <InjuryProfileModel>[];
  }

  void _ensureDefaultsNonBlocking({
    required String userId,
    required Map<String, dynamic> existing,
    required Map<String, dynamic> normalized,
  }) {
    final bool needsDefaults = !existing.containsKey('profileUpdatedAt') ||
        !existing.containsKey('injuryProfiles') ||
        !existing.containsKey('name');
    if (!needsDefaults) {
      return;
    }
    unawaited(
      _performWrite(() async {
        await _users.doc(userId).set(<String, dynamic>{
          'name': normalized['name'],
          'profileUpdatedAt': FieldValue.serverTimestamp(),
          'injuryProfiles': normalized['injuryProfiles'],
        }, SetOptions(merge: true));
      }).catchError((_) {}),
    );
  }
}
