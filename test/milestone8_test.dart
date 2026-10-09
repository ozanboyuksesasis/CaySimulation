import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/harvest_job.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';

void main() {
  late CayGame g;
  setUp(
    () => g = CayGame(
      initialGold: 10000,
      guidedTutorial: false,
      automationEnabled: false,
    ),
  );
  tearDown(() => g.disposeState());
  void place(String id, double x, double y) {
    while (g.progression.level < catalogItem(id).requiredLevel) {
      g.progression.award(
        "fixture-unlock-${g.progression.level}",
        g.progression.xpForNextLevel - g.progression.currentXp,
      );
    }
    g.builder.choose(catalogItem(id));
    g.builder.preview(GridPoint(x, y));
    expect(g.builder.confirm(), isTrue, reason: g.builder.feedback);
  }

  Worker hire(String id, [EquipmentType equipment = EquipmentType.teaShears]) {
    if (id == 'havva' && g.progression.level < 2) {
      g.progression.award('havva-fixture-unlock', 100);
    }
    expect(g.workforce.hire(id).success, isTrue);
    final w = g.workforce.byId(id)!;
    if (equipment != EquipmentType.none) {
      if (equipment == EquipmentType.teaHarvesterMotor) {
        g.progression.award('motor-test-unlock', 1250);
      }
      expect(g.workforce.buyEquipment(equipment).success, isTrue);
      expect(g.workforce.equip(w, equipment).success, isTrue);
    }
    return w;
  }

  void until(bool Function() condition) {
    for (var i = 0; i < 3000 && !condition(); i++) {
      g.simulation.advance(const Duration(milliseconds: 100));
    }
    expect(condition(), isTrue, reason: 'Oyun işlemi zamanında tamamlanmalı.');
  }

  test('M8 başlangıcı yalnız ev, 10000 altın, boş işgücü ve ekipman', () {
    expect(g.economy.balance, 10000);
    expect(g.workforce.workers, isEmpty);
    expect(g.playerInventory.equipment, isEmpty);
    expect(g.playerInventory.placeables, isEmpty);
    expect(g.settlement.structures.single.item.buildType, BuildType.house);
    expect(g.tutorial!.step, TutorialStep.welcome);
  });
  for (final id in ['turhan', 'havva']) {
    test('$id işe alım 1000, gerçek yürünebilir konum, benzersiz sahiplik', () {
      final w = hire(id, EquipmentType.none);
      expect(g.economy.balance, 9000);
      expect(w.name, id == 'turhan' ? 'Turhan' : 'Havva');
      expect(g.pathfinder.walkable(tileAt(w.gridPosition)), isTrue);
      expect(w.equipment, EquipmentType.none);
      expect(g.workforce.hire(id).success, isFalse);
      expect(g.economy.balance, 9000);
      expect(g.workforce.workers.length, 1);
      expect(g.playerInventory.placeables, isEmpty);
    });
  }
  test('Yetersiz altın işe alımı ve ekipman alımını değiştirmez', () {
    g.economy.spend(9900);
    expect(g.workforce.hire('havva').success, isFalse);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isFalse);
    expect(g.workforce.workers, isEmpty);
    expect(g.playerInventory.equipment, isEmpty);
    expect(g.economy.balance, 100);
  });
  for (final item in equipmentCatalog) {
    test('${item.name} satın alma ve otomatik takmama', () {
      final w = hire('havva', EquipmentType.none);
      final gold = g.economy.balance;
      if (item.requiredLevel == 6) {
        g.progression.award('motor-test-unlock', 1250);
      }
      expect(g.workforce.buyEquipment(item.type).success, isTrue);
      expect(g.economy.balance, gold - item.cost);
      expect(g.playerInventory.equipmentQuantity(item.type), 1);
      expect(w.equipment, EquipmentType.none);
    });
    test('${item.name} gerçek iş süresi ve sabit 25 kg ürün', () {
      final w = hire('turhan', item.type);
      place('field', 5, 5);
      final f = g.plantation.fields.single;
      g.plantation.plant(f);
      g.simulation.advance(PlantationConfig.growthDuration);
      final job = g.jobs.requestHarvest(f)!;
      until(() => w.state == WorkerState.working);
      expect(job.harvestDuration, item.duration);
      final remaining = job.harvestDuration - job.worked;
      g.simulation.advance(remaining - const Duration(microseconds: 1));
      expect(f.harvestedStockKg, 0);
      expect(g.workforce.equip(w, EquipmentType.none).success, isFalse);
      g.simulation.advance(const Duration(microseconds: 1));
      expect(f.harvestedStockKg, 25);
      expect(job.status, JobStatus.completed);
      expect(g.inventory.freshTeaKg, 0);
    });
  }
  test('Ekipman değişimi ve çıkarma sahiplik sayısını korur', () {
    final a = hire('turhan');
    final b = hire('havva', EquipmentType.none);
    expect(g.workforce.equip(b, EquipmentType.teaShears).success, isFalse);
    g.progression.award('motor-test-unlock', 1250);
    g.workforce.buyEquipment(EquipmentType.teaHarvesterMotor);
    expect(
      g.workforce.equip(a, EquipmentType.teaHarvesterMotor).success,
      isTrue,
    );
    expect(g.playerInventory.equipmentQuantity(EquipmentType.teaShears), 1);
    expect(
      g.playerInventory.equipmentQuantity(EquipmentType.teaHarvesterMotor),
      0,
    );
    expect(g.workforce.equip(b, EquipmentType.teaShears).success, isTrue);
    expect(g.workforce.equip(a, EquipmentType.none).success, isTrue);
    expect(
      g.playerInventory.equipmentQuantity(EquipmentType.teaHarvesterMotor),
      1,
    );
    expect(g.playerInventory.takeEquipment(EquipmentType.teaShears), isFalse);
    expect(g.playerInventory.equipmentQuantity(EquipmentType.teaShears), 0);
    expect(
      jsonDecode(jsonEncode(g.workforce.toJson()))['workers'],
      hasLength(2),
    );
  });
  test('Ekipmansız işçi için imkansız hasat işi oluşturulmaz', () {
    hire('turhan', EquipmentType.none);
    place('field', 5, 5);
    final f = g.plantation.fields.single;
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(g.jobs.requestHarvest(f), isNull);
    expect(g.jobs.jobs, isEmpty);
    expect(g.jobs.requestFailure, 'Hasat yapabilecek ekipmanlı işçi yok.');
  });
  test('İki işçi eşzamanlı, üçüncü iş FIFO ve dünya saati tek', () {
    final a = hire('turhan');
    final b = hire('havva');
    place('field', 5, 5);
    place('field', 4, 3);
    place('field', 1, 5);
    for (final f in g.plantation.fields) {
      g.plantation.plant(f);
    }
    g.simulation.advance(PlantationConfig.growthDuration);
    final jobs = g.plantation.fields.map(g.jobs.requestHarvest).toList();
    expect(
      {jobs[0]!.assignedWorkerId, jobs[1]!.assignedWorkerId},
      {a.id, b.id},
    );
    expect(jobs[2]!.status, JobStatus.queued);
    final before = g.plantation.simulationTime;
    g.simulation.advance(const Duration(seconds: 30));
    expect(g.plantation.simulationTime - before, const Duration(seconds: 30));
    expect(jobs.every((j) => j!.status == JobStatus.completed), isTrue);
    expect(g.plantation.fields.map((f) => f.harvestedStockKg), [25, 25, 25]);
  });
  test('İptal ve başarısız yerleşim hedefi ilerletmez, altın harcamaz', () {
    g.tutorial!.begin();
    g.builder.choose(catalogItem('field'));
    expect(g.economy.balance, 10000);
    g.builder.cancel();
    expect(g.tutorial!.step, TutorialStep.firstField);
    g.builder.choose(catalogItem('field'));
    g.builder.preview(const GridPoint(3, 9));
    expect(g.builder.confirm(), isFalse);
    expect(g.tutorial!.step, TutorialStep.firstField);
    expect(g.economy.balance, 10000);
  });
  test(
    'Önceden tamamlanan sahiplik ve ekipman adımları yeniden satın aldırmaz',
    () {
      hire('havva');
      place('field', 5, 5);
      g.tutorial!.begin();
      expect(g.tutorial!.firstWorkerId, 'havva');
      expect(g.tutorial!.step, TutorialStep.plantTea);
      expect(g.tutorial!.message, isNot(contains('Mağaza')));
      g.plantation.plant(g.plantation.fields.single);
      expect(g.tutorial!.step, TutorialStep.waitGrowth);
    },
  );
  test('Yol bağlantısı gerçek yol bulucudan değerlendirilir', () {
    hire('turhan');
    place('field', 1, 5);
    final f = g.plantation.fields.single;
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.jobs.requestHarvest(f);
    until(() => f.harvestedStockKg == 25);
    place('collection_center', 9, 4);
    g.tutorial!.begin();
    expect(g.tutorial!.step, TutorialStep.connectCollectionCenter);
    place('road', 3, 7);
    place('road', 2, 7);
    expect(g.tutorial!.collectionRouteValid, isTrue);
    expect(g.tutorial!.step, TutorialStep.orderTransport);
  });
  for (final workerId in ['turhan', 'havva']) {
    test(
      '$workerId ile tek teslimatta eğitim sonu ve isteğe bağlı dört hasat/üretim',
      () {
        final t = g.tutorial!;
        t.begin();
        expect(t.step, TutorialStep.firstField);
        place('field', 5, 5);
        expect(g.economy.balance, 9500);
        expect(t.step, TutorialStep.firstWorker);
        if (workerId == 'havva') {
          g.progression.award('havva-fixture-unlock', 100);
        }
        expect(g.workforce.hire(workerId).success, isTrue);
        expect(t.step, TutorialStep.buyShears);
        expect(t.message, contains(g.worker.name));
        g.workforce.buyEquipment(EquipmentType.teaShears);
        expect(t.step, TutorialStep.equipWorker);
        g.workforce.equip(g.worker, EquipmentType.teaShears);
        expect(t.step, TutorialStep.plantTea);
        final f = g.plantation.fields.single;
        g.plantation.plant(f);
        expect(t.step, TutorialStep.waitGrowth);
        for (var i = 0; i < 4; i++) {
          until(() => f.state == TeaFieldState.ready);
          if (i == 0) expect(t.step, TutorialStep.orderHarvest);
          g.jobs.requestHarvest(f);
          if (i == 0) expect(t.step, TutorialStep.waitHarvest);
          until(() => f.harvestedStockKg == 25);
          if (i == 0) {
            expect(t.step, TutorialStep.buildCollectionCenter);
            place('collection_center', 9, 4);
            expect(t.step, TutorialStep.orderTransport);
          }
          final transport = g.transport.requestTransport(f)!;
          until(() => transport.status == JobStatus.completed);
          expect(g.collectionCenter.receivedTeaKg, 25);
          if (i == 0) {
            expect(f.harvestCount, 1);
            expect(g.activeFactory, isNull);
            expect(t.step, TutorialStep.deliveryComplete);
            t.finish();
            expect(t.step, TutorialStep.completed);
            expect(t.progression, ProgressionStep.buildFactory);
            g.progression.award('legacy-objective-fixture', 100);
            expect(t.effectiveStep, TutorialStep.completed);
            place('factory', 9, 8);
          }
          expect(t.effectiveStep, TutorialStep.completed);
          final shipment = g.transport.requestFactoryShipment()!;
          until(() => shipment.status == JobStatus.completed);
          expect(g.factory.rawTeaKg, (i + 1) * 25);
          expect(t.factoryInputKg, g.factory.rawTeaKg);
        }
        expect(g.economy.balance, 1500);
        expect(t.effectiveStep, TutorialStep.completed);
        expect(g.factory.startProduction(), isTrue);
        expect(t.effectiveStep, TutorialStep.completed);
        g.simulation.advance(const Duration(seconds: 9));
        expect(g.factory.dryTeaKg, 0);
        g.simulation.advance(const Duration(seconds: 1));
        expect(g.factory.dryTeaKg, 20);
        expect(g.factory.rawTeaKg, 0);
        expect(g.inventory.freshTeaKg, 0);
        expect(t.effectiveStep, TutorialStep.completed);
        expect(t.message, contains('Paketleme Tesisi'));
        t.finish();
        expect(t.step, TutorialStep.completed);
        expect(g.economy.balance, 1500);
        expect(f.harvestCount, 4);
      },
    );
  }
}
