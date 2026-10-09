import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_system.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/ui/player_panels.dart';
import 'package:cay_simulasyonu/features/ui/tutorial_coach.dart';
import 'package:cay_simulasyonu/features/ui/field_info_panel.dart';

void main() {
  late CayGame g;
  setUp(() => g = CayGame());
  tearDown(() => g.disposeState());
  bool place(String id, double x, double y) {
    g.builder.choose(catalogItem(id));
    g.builder.preview(GridPoint(x, y));
    return g.builder.confirm();
  }

  void firstField() {
    g.tutorial!.begin();
    expect(place('field', 5, 5), isTrue);
  }

  void readyForPlant() {
    firstField();
    expect(g.workforce.hire('turhan').success, isTrue);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isTrue);
    expect(
      g.workforce.equip(g.worker, EquipmentType.teaShears).success,
      isTrue,
    );
  }

  void until(bool Function() condition) {
    for (var i = 0; i < 3000 && !condition(); i++) {
      g.simulation.advance(const Duration(milliseconds: 100));
    }
    expect(condition(), isTrue);
  }

  void firstDelivery() {
    readyForPlant();
    expect(g.plantation.plant(g.plantation.fields.single), PlantResult.planted);
    until(() => g.tutorial!.step == TutorialStep.buildCollectionCenter);
    expect(place('collection_center', 9, 4), isTrue);
    until(() => g.tutorial!.step == TutorialStep.deliveryComplete);
  }

  void finish() {
    firstDelivery();
    g.tutorial!.finish();
  }

  test('Welcome locks all spending and beginning does not award fake XP', () {
    expect(place('field', 5, 5), isFalse);
    expect(g.workforce.hire('turhan').success, isFalse);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isFalse);
    expect(g.economy.balance, 15000);
    expect(g.progression.currentXp, 0);
    g.tutorial!.begin();
    expect(g.progression.currentXp, 0);
    expect(place('field', 5, 5), isTrue);
    expect(g.progression.currentXp, 10);
  });

  test('Success feedback cannot hide XP earned by the same action', () async {
    firstField();
    final result = g.workforce.hire('turhan');
    g.notifications.show(result.message);
    expect(g.notifications.message, contains('+10 XP'));
    await Future<void>.delayed(Duration.zero);
    g.notifications.show('Yeni işlem');
    expect(g.notifications.message, 'Yeni işlem');
  });
  test('Worker step permits one starter choice, rejects planting, moving and extra purchases', () {
    firstField();
    final f = g.plantation.fields.single;
    final balance = g.economy.balance;
    expect(g.tutorial!.step, TutorialStep.firstWorker);
    expect(g.tutorial!.message, 'Bir işçi işe almamız gerekiyor.');
    expect(g.plantation.plant(f), PlantResult.restricted);
    expect(f.state, TeaFieldState.empty);
    expect(g.builder.startMove(f.id), isFalse);
    expect(place('field', 7, 5), isFalse);
    expect(place('warehouse', 11, 8), isFalse);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isFalse);
    expect(g.economy.balance, balance);
    expect(g.workforce.hire('havva').success, isTrue);
    expect(g.workforce.hire('turhan').success, isFalse);
  });
  test('Only one shears purchase; equip cannot be undone during tutorial', () {
    firstField();
    g.workforce.hire('turhan');
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isTrue);
    final balance = g.economy.balance;
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isFalse);
    expect(
      g.plantation.plant(g.plantation.fields.single),
      PlantResult.restricted,
    );
    expect(
      g.workforce.equip(g.worker, EquipmentType.teaShears).success,
      isTrue,
    );
    expect(g.workforce.equip(g.worker, EquipmentType.none).success, isFalse);
    expect(g.economy.balance, balance);
    expect(g.progression.currentXp, 40);
    expect(g.plantation.plant(g.plantation.fields.single), PlantResult.planted);
    expect(g.progression.currentXp, 50);
  });
  test('First tutorial field must have reachable road access', () {
    g.tutorial!.begin();
    expect(place('field', 0, 0), isFalse);
    expect(g.builder.feedback, contains('başlangıç yolunun'));
    expect(g.economy.balance, 15000);
    expect(g.progression.currentXp, 0);
    expect(place('field', 5, 5), isTrue);
  });
  test('Real teaching and business events reach exactly level two at first delivery', () {
    firstDelivery();
    expect(g.progression.level, 2);
    expect(g.progression.currentXp, 0);
    expect(g.plantation.fields.single.harvestCount, 1);
    expect(g.collectionCenter.receivedTeaKg, 25);
    expect(g.economy.balance, 10500);
    expect(g.activeFactory, isNull);
    for (var i = 0; i < 10; i++) {
      g.tutorial!.evaluate();
    }
    expect(g.progression.currentXp, 0);
    expect(g.notifications.message, contains('Havva'));
  });
  test('Havva is an optional post-tutorial hire at level two', () {
    expect(g.workforce.hire('havva').success, false);
    finish();
    expect(g.tutorial!.step, TutorialStep.completed);
    expect(g.workforce.workers.length, 1);
    expect(g.workforce.hire('havva').success, true);
    expect(g.tutorial!.step, TutorialStep.completed);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, true);
    expect(
      g.workforce
          .equip(g.workforce.byId('havva')!, EquipmentType.teaShears)
          .success,
      true,
    );
    expect(g.economy.balance, 9250);
  });
  test('Revenue chain funds stay reserved after tutorial', () {
    finish();
    g.economy.spend(3000);
    expect(place('field', 0, 0), false);
    expect(g.builder.feedback, contains('7500 Altın'));
    expect(g.economy.balance, 7500);
    expect(place('factory', 9, 8), true);
    expect(g.economy.balance, 3500);
    expect(place('packaging', 12, 5), true);
    expect(place('tea_shop', 6, 3), true);
    expect(g.economy.balance, 0);
  });
  test('Road spending preserves all missing revenue buildings', () {
    readyForPlant();
    g.plantation.plant(g.plantation.fields.single);
    until(() => g.tutorial!.step == TutorialStep.buildCollectionCenter);
    g.economy.spend(2750);
    for (var x = 13; x < 20; x++) {
      expect(place('road', x.toDouble(), 7), true);
    }
    for (var y = 4; y < 7; y++) {
      expect(place('road', 19, y.toDouble()), true);
    }
    expect(place('road', 19, 3), false);
    expect(place('collection_center', 9, 4), true);
    until(() => g.tutorial!.step == TutorialStep.deliveryComplete);
    g.tutorial!.finish();
    expect(g.economy.balance, 7500);
  });
  test('Alternating crops do not starve the more distant equipped worker', () {
    final sandbox = CayGame(guidedTutorial: false);
    addTearDown(sandbox.disposeState);
    sandbox.progression.award('fixture', 100);
    for (final id in ['turhan', 'havva']) {
      sandbox.workforce.hire(id);
      sandbox.workforce.buyEquipment(EquipmentType.teaShears);
      sandbox.workforce.equip(
        sandbox.workforce.byId(id)!,
        EquipmentType.teaShears,
      );
    }
    sandbox.builder.choose(catalogItem('field'));
    sandbox.builder.preview(const GridPoint(5, 5));
    expect(sandbox.builder.confirm(), isTrue);
    final f = sandbox.plantation.fields.single;
    sandbox.plantation.plant(f);
    sandbox.workforce.byId('turhan')!.gridPosition = const GridPoint(5.5, 7.5);
    sandbox.workforce.byId('havva')!.gridPosition = const GridPoint(0.5, 0.5);
    for (var cycle = 0; cycle < 4; cycle++) {
      for (var i = 0; i < 1000 && f.harvestCount <= cycle; i++) {
        sandbox.simulation.advance(const Duration(milliseconds: 100));
      }
      expect(f.harvestCount, cycle + 1);
      f.removeHarvestedStock(25);
    }
    expect(sandbox.jobs.jobs.map((j) => j.assignedWorkerId), [
      'turhan',
      'havva',
      'turhan',
      'havva',
    ]);
    expect(sandbox.workforce.byId('turhan')!.workerXp, 20);
    expect(sandbox.workforce.byId('havva')!.workerXp, 20);
  });
  testWidgets(
    'Inventory action is visible without expanding coach; wrong actions disabled',
    (tester) async {
      g.tutorial!.begin();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [TutorialCoach(game: g)]),
          ),
        ),
      );
      expect(find.text('Envanteri Aç'), findsOneWidget);
      await tester.tap(find.text('Envanteri Aç'));
      await tester.pump();
      expect(g.panels.category, BuildCategory.agriculture);
      g.panels.close();
      expect(place('field', 5, 5), isTrue);
      g.panels.openCatalog(BuildCategory.workers);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerPanels(game: g)),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('acquire-turhan')))
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('acquire-havva')))
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FieldInfoPanel(
              field: g.plantation.fields.single,
              system: g.plantation,
              jobs: g.jobs,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('plant-field')))
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
