import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/systems/objective_system.dart';
import 'package:cay_simulasyonu/game/systems/world_status.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/progression/progression_state.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/harvest_job.dart';
import 'package:cay_simulasyonu/features/transport/transport_vehicle.dart';

void main() {
  late CayGame g;
  setUp(() => g = CayGame(initialGold: 10000, guidedTutorial: false));
  tearDown(() => g.disposeState());
  void place(String type, double x, double y) {
    while (g.progression.level < catalogItem(type).requiredLevel) {
      g.progression.award(
        "fixture-unlock-${g.progression.level}",
        g.progression.xpForNextLevel - g.progression.currentXp,
      );
    }
    g.builder.choose(catalogItem(type));
    g.builder.preview(GridPoint(x, y));
    expect(g.builder.confirm(), isTrue, reason: g.builder.feedback);
  }

  Worker hire([String id = 'turhan', bool equip = true]) {
    if (id == 'havva' && g.progression.level < 2) {
      g.progression.award('havva-fixture-unlock', 100);
    }
    expect(g.workforce.hire(id).success, isTrue);
    final worker = g.workforce.byId(id)!;
    if (equip) {
      expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isTrue);
      expect(
        g.workforce.equip(worker, EquipmentType.teaShears).success,
        isTrue,
      );
    }
    return worker;
  }

  TeaField field([double x = 5, double y = 5]) {
    place('field', x, y);
    final field = g.plantation.fields.last;
    g.plantation.plant(field);
    return field;
  }

  void until(bool Function() predicate) {
    for (var n = 0; n < 6000 && !predicate(); n++) {
      g.simulation.advance(const Duration(milliseconds: 100));
    }
    expect(predicate(), isTrue);
  }

  void chain() {
    field();
    hire();
    place('collection_center', 9, 4);
    place('factory', 9, 8);
  }

  test('Normal game starts automated, level one, no free worker', () {
    expect(g.automation.enabled, isTrue);
    expect(g.manualControls, isFalse);
    expect(g.progression.level, 1);
    expect(g.progression.currentXp, 0);
    expect(g.economy.balance, 10000);
    expect(g.workforce.workers, isEmpty);
  });
  test('Ready crop without equipment waits without failed jobs or XP', () {
    final f = field();
    hire('turhan', false);
    g.simulation.advance(const Duration(seconds: 60));
    for (var i = 0; i < 20; i++) {
      g.automation.tick();
    }
    expect(f.state, TeaFieldState.ready);
    expect(g.jobs.jobs, isEmpty);
    expect(g.progression.currentXp, 0);
    expect(g.notifications.message, isNull);
  });
  test('Equipping an owned worker automatically discovers waiting crop', () {
    final f = field();
    final w = hire('havva', false);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.workforce.buyEquipment(EquipmentType.teaShears);
    g.workforce.equip(w, EquipmentType.teaShears);
    g.automation.tick();
    final job = g.jobs.jobs.single;
    for (var i = 0; i < 20; i++) {
      g.automation.tick();
    }
    expect(g.jobs.jobs.single, same(job));
    expect(job.assignedWorkerId, w.id);
    expect(w.state, WorkerState.movingToJob);
    until(() => f.harvestedStockKg == 25);
    expect(w.workerXp, 10);
    expect(g.progression.currentXp, 10);
    expect(g.inventory.freshTeaKg, 0);
  });
  test(
    'Automatic queue serves oldest READY field and keeps one reservation',
    () {
      g.automation.enabled = false;
      final older = field();
      hire();
      g.simulation.advance(const Duration(seconds: 5));
      final newer = field(4, 3);
      g.simulation.advance(PlantationConfig.growthDuration);
      g.automation.enabled = true;
      g.automation.tick();
      expect(g.jobs.jobs.map((j) => j.fieldId), [older.id, newer.id]);
      expect(g.jobs.jobs.last.status, JobStatus.queued);
      for (var n = 0; n < 20; n++) {
        g.automation.tick();
      }
      expect(g.jobs.jobs.length, 2);
      until(() => newer.harvestCount == 1);
      expect(older.harvestedStockKg, 25);
      expect(g.progression.currentXp, 13);
    },
  );
  test('Two equipped workers run simultaneously; third crop waits', () {
    field();
    field(4, 3);
    field(1, 5);
    hire();
    hire('havva');
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(g.jobs.jobs.length, 3);
    expect(g.jobs.queuedCount, 1);
    expect(
      g.jobs.jobs.take(2).map((j) => j.assignedWorkerId).toSet().length,
      2,
    );
    until(() => g.plantation.fields.every((f) => f.harvestCount == 1));
    expect(g.workforce.workers.fold(0, (s, w) => s + w.workerXp), 30);
    expect(g.progression.currentXp, 16);
  });
  test('Nearest reachable worker wins, stable ID breaks equal-path ties', () {
    field();
    final a = hire(), b = hire('havva');
    a.gridPosition = const GridPoint(0.5, 0.5);
    b.gridPosition = const GridPoint(5.5, 7.5);
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(g.jobs.jobs.single.assignedWorkerId, b.id);
    expect(g.jobs.pathFor(b).every(g.pathfinder.walkable), isTrue);
    // Idle workers may take short walks while crops grow.
    expect(g.pathfinder.walkable(tileAt(b.gridPosition)), isTrue);
  });
  test('Unreachable crop does not create failing work on repeated ticks', () {
    final f = field();
    hire();
    g.pathfinder.updateTopology(
      blocked: {
        ...g.settlement.blocked,
        ...g.pathfinder.interactionTiles(f.gridPosition, f.footprint),
      },
    );
    g.simulation.advance(const Duration(seconds: 60));
    for (var i = 0; i < 30; i++) {
      g.automation.tick();
    }
    expect(g.jobs.jobs, isEmpty);
    g.pathfinder.updateTopology(blocked: g.settlement.blocked);
    g.automation.tick();
    expect(g.jobs.jobs.length, 1);
  });
  test('Disable stops discovery; existing harvest finishes safely', () {
    final f = field();
    hire();
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(g.jobs.jobs.length, 1);
    g.automation.enabled = false;
    place('collection_center', 9, 4);
    g.simulation.advance(const Duration(seconds: 60));
    expect(f.harvestedStockKg, 25);
    expect(g.transport.jobs, isEmpty);
    expect(g.progression.currentXp, 10);
    g.automation.enabled = true;
    until(() => g.collectionCenter.receivedTeaKg == 25);
    expect(g.progression.currentXp, 25);
  });
  test(
    'Disconnected road waits, then real road construction enables pickup',
    () {
      final f = field(1, 5);
      hire();
      place('collection_center', 9, 4);
      until(() => f.harvestedStockKg == 25);
      for (var i = 0; i < 20; i++) {
        g.automation.tick();
      }
      expect(g.transport.jobs, isEmpty);
      place('road', 3, 7);
      place('road', 2, 7);
      until(() => g.collectionCenter.receivedTeaKg == 25);
      expect(g.transport.jobs.single.deliveredKg, 25);
    },
  );
  test(
    'Loading and unloading occur only after real timers; mass conserved',
    () {
      final f = field();
      hire();
      place('collection_center', 9, 4);
      until(() => g.vehicle.state == VehicleState.loading);
      final job = g.transport.currentJob!;
      expect(f.harvestedStockKg, 25);
      expect(g.vehicle.cargoKg, 0);
      final mass = g.transport.totalTeaKg;
      g.simulation.advance(const Duration(seconds: 2));
      expect(f.harvestedStockKg, 25);
      until(() => g.vehicle.cargoKg == 25);
      expect(f.harvestedStockKg, 0);
      expect(f.stageDuration, isNotNull);
      expect(g.transport.totalTeaKg, mass);
      until(() => g.vehicle.state == VehicleState.unloading);
      expect(g.collectionCenter.receivedTeaKg, 0);
      until(() => job.status == JobStatus.completed);
      expect(g.collectionCenter.receivedTeaKg, 25);
      expect(g.vehicle.cargoKg, 0);
      expect(g.transport.totalTeaKg, mass);
    },
  );
  test(
    'Full automatic physical chain produces dry tea without commands or income',
    () {
      chain();
      final gold = g.economy.balance;
      until(() => g.factory.completedBatchCount == 1);
      expect(g.factory.dryTeaKg, 20);
      expect(g.economy.balance, gold);
      expect(g.inventory.freshTeaKg, 0);
      expect(
        g.transport.totalRawTeaKg + g.factory.dryTeaKg * 5,
        g.plantation.fields.fold(0, (s, f) => s + f.harvestCount * 25),
      );
      expect(g.progression.level, 2);
      expect(g.progression.currentXp, 134);
      expect(g.worker.workerXp, 40);
      expect(
        g.transport.jobs
            .where(
              (j) => j.isFactoryShipment && j.status == JobStatus.completed,
            )
            .length,
        4,
      );
      expect(g.jobs.jobs.every((j) => j.status != JobStatus.failed), isTrue);
    },
  );
  test(
    'Large and small simulation steps preserve automatic batch accounting',
    () {
      chain();
      g.simulation.advance(const Duration(seconds: 200));
      final snapshot = [
        g.plantation.fields.single.harvestCount,
        g.factory.dryTeaKg,
        g.progression.level,
        g.progression.currentXp,
        g.transport.totalRawTeaKg,
      ];
      g.disposeState();
      g = CayGame(initialGold: 10000, guidedTutorial: false);
      chain();
      for (var i = 0; i < 2000; i++) {
        g.simulation.advance(const Duration(milliseconds: 100));
      }
      expect([
        g.plantation.fields.single.harvestCount,
        g.factory.dryTeaKg,
        g.progression.level,
        g.progression.currentXp,
        g.transport.totalRawTeaKg,
      ], snapshot);
    },
  );
  test(
    'Production automatically repeats eligible batches but preserves remainder',
    () {
      place('collection_center', 9, 4);
      place('factory', 9, 8);
      g.factory.receiveRawTea(250);
      g.automation.tick();
      for (var i = 0; i < 20; i++) {
        g.automation.tick();
      }
      expect(g.factory.rawTeaKg, 150);
      expect(g.factory.processingInputKg, 100);
      g.simulation.advance(const Duration(seconds: 20));
      expect(g.factory.dryTeaKg, 40);
      expect(g.factory.rawTeaKg, 50);
      expect(g.factory.processingInputKg, 0);
      expect(g.progression.currentXp, 60);
    },
  );
  test('Disabled automation never starts production', () {
    place('collection_center', 9, 4);
    place('factory', 9, 8);
    g.automation.enabled = false;
    g.factory.receiveRawTea(100);
    g.simulation.advance(const Duration(seconds: 60));
    expect(g.factory.rawTeaKg, 100);
    expect(g.factory.dryTeaKg, 0);
  });
  test(
    'Repeated completion event cannot award business or worker XP twice',
    () {
      field();
      hire();
      until(() => g.jobs.jobs.any((j) => j.status == JobStatus.completed));
      final job = g.jobs.jobs.single;
      g.jobs.onHarvestCompleted!(job, g.worker);
      g.worker.rewardHarvest(job.id);
      expect(g.progression.currentXp, 10);
      expect(g.worker.workerXp, 10);
    },
  );
  test('XP overflow supports several levels in one grant', () {
    g.progression.award('a', 95);
    g.progression.award('b', 20);
    expect(g.progression.level, 2);
    expect(g.progression.currentXp, 15);
    g.progression.award('c', 360);
    expect(g.progression.level, 4);
    expect(g.progression.currentXp, 0);
    expect(() => g.progression.award('negative', -1), throwsArgumentError);
  });
  test('Delivery and production event replays never award twice', () {
    for (final activity in [
      BusinessActivity.collectionDelivery,
      BusinessActivity.factoryDelivery,
      BusinessActivity.production,
    ]) {
      expect(g.progression.record(activity, 'event-1'), isTrue);
      expect(g.progression.record(activity, 'event-1'), isFalse);
    }
    expect(g.progression.currentXp, 40);
  });
  test('Equal routes choose stable worker ID regardless of hiring order', () {
    field();
    final a = hire(), b = hire('havva');
    a.gridPosition = const GridPoint(5.5, 7.5);
    b.gridPosition = a.gridPosition;
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(g.jobs.jobs.single.assignedWorkerId, 'havva');
  });
  test(
    'World bottleneck labels reflect waiting work without changing stock',
    () {
      final f = field();
      g.simulation.advance(PlantationConfig.growthDuration);
      expect(WorldStatus.field(f, automated: true)!.label, 'İşçi Bekliyor');
      hire();
      until(() => f.harvestedStockKg == 25);
      expect(
        WorldStatus.field(f, automated: true)!.label,
        contains('Nakliye Bekliyor'),
      );
      expect(WorldStatus.field(f, automated: true)!.sack, isTrue);
      expect(f.harvestedStockKg, 25);
      place('collection_center', 9, 4);
      place('factory', 9, 8);
      g.factory.receiveRawTea(75);
      expect(
        WorldStatus.factory(g.factory, automated: true)!.label,
        '75 / 100 kg',
      );
      expect(g.factory.rawTeaKg, 75);
    },
  );
  test(
    'Automatic shipment reserves capacity and remainder is shipped once',
    () {
      place('collection_center', 9, 4);
      place('factory', 9, 8);
      g.collectionCenter.receive(150);
      g.automation.tick();
      for (var i = 0; i < 30; i++) {
        g.automation.tick();
      }
      expect(g.transport.jobs.length, 1);
      expect(g.transport.jobs.first.requestedAmountKg, 100);
      until(
        () =>
            g.transport.jobs
                .where((j) => j.status == JobStatus.completed)
                .length ==
            2,
      );
      expect(g.transport.jobs.map((j) => j.deliveredKg), [100, 50]);
      expect(g.collectionCenter.receivedTeaKg, 0);
      expect(g.vehicle.cargoKg, 0);
      expect(g.transport.totalRawTeaKg + g.factory.dryTeaKg * 5, 150);
    },
  );
  test(
    'Broken factory route preserves cargo; repaired road resumes automatically',
    () {
      place('collection_center', 9, 4);
      place('factory', 9, 8);
      g.collectionCenter.receive(25);
      until(() => g.vehicle.cargoKg == 25);
      final job = g.transport.currentJob!;
      g.vehiclePathfinder.updateTopology(
        blocked: g.settlement.blocked,
        allowed: {tileAt(g.vehicle.gridPosition)},
      );
      until(() => g.vehicle.state == VehicleState.blocked);
      g.simulation.advance(const Duration(seconds: 10));
      expect(g.vehicle.cargoKg, 25);
      expect(g.factory.rawTeaKg, 0);
      expect(g.progression.currentXp, 30);
      expect(g.transport.jobs.length, 1);
      g.vehiclePathfinder.updateTopology(
        blocked: g.settlement.blocked,
        allowed: g.settlement.roads,
      );
      until(() => job.status == JobStatus.completed);
      expect(g.factory.rawTeaKg, 25);
      expect(g.vehicle.cargoKg, 0);
      expect(g.progression.currentXp, 40);
    },
  );
  test('Business curve and motor requirement remain centralized', () {
    expect(
      [for (var i = 1; i <= 5; i++) ProgressionConfig.businessThreshold(i)],
      [100, 150, 225, 325, 450],
    );
    expect(
      equipmentDefinition(EquipmentType.teaHarvesterMotor).requiredLevel,
      6,
    );
    expect(equipmentDefinition(EquipmentType.teaHarvesterMotor).cost, 2500);
    expect(catalogItem('factory').requiredLevel, 2);
    expect(catalogItem('packaging').requiredLevel, 2);
    expect(catalogItem('tea_shop').requiredLevel, 2);
    expect(catalogItem('warehouse').requiredLevel, 3);
  });
  test('Motor is domain locked before six and purchase works at six', () {
    final gold = g.economy.balance;
    expect(
      g.workforce.buyEquipment(EquipmentType.teaHarvesterMotor).success,
      isFalse,
    );
    expect(
      g.playerInventory.equipmentQuantity(EquipmentType.teaHarvesterMotor),
      0,
    );
    expect(g.economy.balance, gold);
    g.progression.award('test-unlock', 1250);
    expect(g.progression.level, 6);
    expect(
      g.workforce.buyEquipment(EquipmentType.teaHarvesterMotor).success,
      isTrue,
    );
    expect(g.economy.balance, gold - 2500);
    expect(g.notifications.message, contains('Çay Motoru'));
  });
  test('Worker experience is independent, speed derived and safely capped', () {
    final a = hire(), b = hire('havva');
    for (var n = 0; n < 10; n++) {
      a.rewardHarvest('test-$n');
    }
    expect(a.workerLevel, 2);
    expect(a.workerXp, 50);
    expect(b.workerLevel, 1);
    expect(a.harvestDuration.inMilliseconds, 4901);
    expect(b.harvestDuration, const Duration(seconds: 5));
    expect(g.progression.currentXp, 0);
    a.experience.award('large', 10000000);
    expect(a.harvestDuration.inMilliseconds, greaterThanOrEqualTo(2500));
    expect(a.toJson()['experience'], isA<Map>());
  });
  for (final name in ['turhan', 'havva']) {
    test(
      'Automatic $name tutorial ends on ONE physical collection delivery',
      () {
        g.tutorial!.begin();
        final f = field();
        hire(name);
        until(() => f.harvestedStockKg == 25);
        expect(g.tutorial!.step, TutorialStep.buildCollectionCenter);
        place('collection_center', 9, 4);
        until(() => g.tutorial!.step == TutorialStep.deliveryComplete);
        expect(f.harvestCount, 1);
        expect(g.activeFactory, isNull);
        expect(g.tutorial!.message, contains('otomatik çalışıyor'));
        g.tutorial!.finish();
        expect(g.tutorial!.step, TutorialStep.completed);
        expect(
          g.objectives.current,
          name == 'turhan'
              ? BusinessObjective.levelTwo
              : BusinessObjective.factory,
        );
        expect(g.economy.balance, 5500);
      },
    );
  }
  test('Factory and motor goals are optional, derived and reward no gold', () {
    expect(g.objectives.current, BusinessObjective.levelTwo);
    g.progression.award('test-level', 100);
    expect(g.objectives.current, BusinessObjective.factory);
    hire();
    hire('havva');
    expect(g.objectives.current, BusinessObjective.factory);
    place('collection_center', 9, 4);
    place('factory', 9, 8);
    expect(g.objectives.current, BusinessObjective.packaging);
    g.factory.receiveRawTea(100);
    g.simulation.advance(const Duration(seconds: 10));
    expect(g.objectives.current, BusinessObjective.packaging);
    g.progression.award('test-six', 1250);
    expect(g.objectives.current, BusinessObjective.packaging);
    expect(g.economy.balance, 1000);
  });
}
