import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundee_fundee_flutter/domain/models/lift_max_model.dart';
import 'package:sundee_fundee_flutter/domain/models/one_rep_max_model.dart';
import 'package:sundee_fundee_flutter/features/maxes/presentation/max_lifts_screen.dart';
import 'package:sundee_fundee_flutter/features/maxes/providers.dart';
import 'package:sundee_fundee_flutter/features/repositories/domain/repository_interfaces.dart';
import 'package:sundee_fundee_flutter/features/repositories/providers.dart';

void main() {
  testWidgets('opens bottom sheet from compact maxes row', (
    WidgetTester tester,
  ) async {
    final FakeLiftRepository repo = FakeLiftRepository(
      initialMaxes: <LiftMaxModel>[
        LiftMaxModel(
          id: 'max-1',
          userId: 'user-1',
          exerciseId: 'back-squat',
          repCount: 1,
          weight: 225,
          withStraps: false,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      ],
    );
    addTearDown(repo.dispose);

    await _pumpScreen(tester: tester, repo: repo);

    // Expand the category
    await tester.tap(find.text('Squat Variations'));
    await tester.pumpAndSettle();

    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('225.0'), findsOneWidget); // The TextField text

    // No more bottom sheet, it's inline
    await tester.enterText(find.byType(TextField).first, '230');
    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();

    expect(repo.savedLiftMaxes, hasLength(1));
    expect(repo.savedLiftMaxes.first.weight, 230);
  });

  testWidgets('saves entered max from inline row', (WidgetTester tester) async {
    final FakeLiftRepository repo = FakeLiftRepository();
    addTearDown(repo.dispose);

    await _pumpScreen(tester: tester, repo: repo);

    // Expand the category
    await tester.tap(find.text('Squat Variations'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '205');
    await tester.tap(find.byIcon(Icons.save).first);
    await tester.pumpAndSettle();

    expect(repo.savedLiftMaxes, hasLength(1));
    final LiftMaxModel saved = repo.savedLiftMaxes.single;
    expect(saved.userId, 'user-1');
    expect(saved.exerciseId, 'back-squat');
    expect(saved.repCount, 1);
    expect(saved.weight, 205);
  });
}

Future<void> _pumpScreen({
  required WidgetTester tester,
  required FakeLiftRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        maxesUserIdProvider.overrideWith((Ref ref) => 'user-1'),
        liftRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: MaxLiftsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class FakeLiftRepository implements LiftRepository {
  FakeLiftRepository({List<LiftMaxModel>? initialMaxes})
    : _maxes = <LiftMaxModel>[...?initialMaxes];

  final List<LiftMaxModel> _maxes;
  final StreamController<List<LiftMaxModel>> _updatesController =
      StreamController<List<LiftMaxModel>>.broadcast();
  final List<LiftMaxModel> savedLiftMaxes = <LiftMaxModel>[];

  @override
  Future<void> saveLiftMax({
    required String userId,
    required LiftMaxModel liftMax,
  }) async {
    savedLiftMaxes.add(liftMax);
    final int existingIndex = _maxes.indexWhere(
      (LiftMaxModel m) =>
          m.exerciseId == liftMax.exerciseId && m.repCount == liftMax.repCount,
    );
    if (existingIndex == -1) {
      _maxes.add(liftMax);
    } else {
      _maxes[existingIndex] = liftMax;
    }
    _updatesController.add(List<LiftMaxModel>.unmodifiable(_maxes));
  }

  @override
  Stream<List<LiftMaxModel>> watchLiftMaxes({required String userId}) async* {
    yield List<LiftMaxModel>.unmodifiable(_maxes);
    yield* _updatesController.stream;
  }

  @override
  Future<void> saveOneRepMax({
    required String userId,
    required OneRepMaxModel oneRepMax,
  }) async {}

  @override
  Stream<List<OneRepMaxModel>> watchOneRepMaxes({required String userId}) {
    return const Stream<List<OneRepMaxModel>>.empty();
  }

  Future<void> dispose() async {
    await _updatesController.close();
  }
}
