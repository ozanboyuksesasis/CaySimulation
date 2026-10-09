import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/systems/retail_system.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/systems/objective_system.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/buildings/packaging_facility.dart';
import 'package:cay_simulasyonu/features/buildings/tea_shop.dart';
import 'package:cay_simulasyonu/features/buildings/tea_factory.dart';
import 'package:cay_simulasyonu/features/economy/economy_state.dart';
import 'package:cay_simulasyonu/features/progression/progression_state.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';

void main() {
  late TeaFactory f;
  late PackagingFacility p;
  late TeaShop s;
  late EconomyState gold;
  setUp(() {
    f = TeaFactory(
      id: 'f',
      gridPosition: const GridPoint(2, 2),
      footprint: const Footprint(2, 2),
      deliveryInteractionTile: (x: 2, y: 1),
    );
    p = PackagingFacility(
      id: 'p',
      gridPosition: const GridPoint(5, 2),
      footprint: const Footprint(2, 2),
    );
    s = TeaShop(
      id: 's',
      gridPosition: const GridPoint(8, 2),
      footprint: const Footprint(2, 2),
    );
    gold = EconomyState(initialBalance: 0);
  });
  tearDown(() {
    f.dispose();
    p.dispose();
    s.dispose();
    gold.dispose();
  });
  void dryBatch() {
    f.receiveRawTea(100);
    expect(f.startProduction(), true);
    f.advance(const Duration(seconds: 10));
  }

  test('Only customer sales create gold; timed packaging conserves 20 kg', () {
    dryBatch();
    expect(f.dryTeaKg, 20);
    expect(gold.balance, 0);
    expect(p.startFrom(f), true);
    expect(f.dryTeaKg, 0);
    expect(p.inputKg, 20);
    expect(p.startFrom(f), false);
    p.advance(const Duration(seconds: 7));
    expect(p.output.quantityUnits, 0);
    expect(p.inputKg, 20);
    p.advance(const Duration(seconds: 1));
    expect(p.inputKg, 0);
    expect(p.output.quantityUnits, 20);
    expect(gold.balance, 0);
    s.restock(p);
    expect(s.shelf.stockUnits, 10);
    expect(p.output.quantityUnits, 10);
    expect(gold.balance, 0);
    expect(s.purchase('a', gold), true);
    expect(gold.balance, 150);
    expect(s.shelf.stockUnits, 9);
    expect(s.purchase('a', gold), false);
    expect(gold.balance, 150);
  });
  test('20 packages yield exactly 3000 only from 20 unique buyers', () {
    dryBatch();
    p.startFrom(f);
    p.advance(const Duration(seconds: 8));
    for (var i = 0; i < 20; i++) {
      s.restock(p);
      expect(s.purchase('buyer$i', gold), true);
    }
    expect(gold.balance, 3000);
    expect(s.soldUnits, 20);
    expect(p.output.quantityUnits + s.shelf.stockUnits, 0);
    expect(s.purchase('empty', gold), false);
    expect(gold.balance, 3000);
  });
  test('Empty shelf and replayed failed visitor never earn money', () {
    expect(s.purchase('empty', gold), false);
    p.output.add(20);
    s.restock(p);
    expect(s.purchase('empty', gold), false);
    expect(s.shelf.stockUnits, 10);
    expect(gold.balance, 0);
  });
  test('Full packaging output waits without consuming dry stock', () {
    p.output.add(100);
    dryBatch();
    expect(p.startFrom(f), false);
    expect(f.dryTeaKg, 20);
    expect(() => p.output.add(1), throwsArgumentError);
    expect(() => s.shelf.remove(1), throwsArgumentError);
  });
  test('Transport connectivity is required for internal transfer', () {
    final roads = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {},
      allowed: {},
    );
    final r =
        RetailSystem(
            economy: gold,
            pedestrians: GridPathfinder(columns: 20, rows: 20, blocked: {}),
            roads: roads,
            factory: () => f,
          )
          ..packaging = p
          ..shop = s;
    dryBatch();
    r.tick();
    expect(f.dryTeaKg, 20);
    roads.updateTopology(
      blocked: {},
      allowed: {for (var x = 0; x < 12; x++) (x: x, y: 1)},
    );
    r.tick();
    expect(p.inputKg, 20);
    expect(f.dryTeaKg, 0);
    p.advance(const Duration(seconds: 8));
    r.tick();
    expect(p.output.quantityUnits, 10);
    expect(s.shelf.stockUnits, 10);
    expect(r.processedKg, 20);
  });
  test('Customer walks, waits, buys once and leaves; cap stays bounded', () {
    final r = RetailSystem(
      economy: gold,
      pedestrians: GridPathfinder(
        columns: 20,
        rows: 20,
        blocked: GridPathfinder.footprintTiles(
          s.gridPosition,
          s.footprint,
        ).toSet(),
      ),
      roads: GridPathfinder(columns: 20, rows: 20, blocked: {}, allowed: {}),
      factory: () => f,
    )..shop = s;
    s.shelf.add(10);
    r.advance(const Duration(seconds: 10), automatic: true);
    expect(r.customers.length, 1);
    expect(gold.balance, 0);
    final first = r.customers.single;
    final original = first.gridPosition;
    r.advance(const Duration(milliseconds: 100), automatic: true);
    expect(first.gridPosition, isNot(original));
    for (var i = 0; i < 600; i++) {
      r.advance(const Duration(milliseconds: 100), automatic: true);
      expect(r.customers.length, lessThanOrEqualTo(5));
      for (final c in r.customers) {
        expect(r.pedestrians.walkable(tileAt(c.gridPosition)), true);
      }
    }
    expect(gold.balance, greaterThan(0));
    expect(r.customers.any((c) => c.id == first.id), false);
    expect(gold.balance, s.soldUnits * 150);
  });
  test('Unreachable shop spawns no customer and no income', () {
    final finder = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {
        for (var x = 0; x < 20; x++)
          for (var y = 0; y < 20; y++) (x: x, y: y),
      },
    );
    final r = RetailSystem(
      economy: gold,
      pedestrians: finder,
      roads: finder,
      factory: () => f,
    )..shop = s;
    for (var i = 0; i < 10; i++) {
      r.advance(const Duration(seconds: 10), automatic: true);
    }
    expect(r.customers, isEmpty);
    expect(gold.balance, 0);
  });
  test('XP deduplicates first and repeat sale/production rewards', () {
    final xp = BusinessProgression();
    addTearDown(xp.dispose);
    xp.record(BusinessActivity.sale, 'a');
    expect(xp.currentXp, 22);
    xp.record(BusinessActivity.sale, 'a');
    expect(xp.currentXp, 22);
    xp.record(BusinessActivity.sale, 'b');
    expect(xp.currentXp, 24);
    xp.record(BusinessActivity.packaging, '1');
    expect(xp.currentXp, 39);
    xp.record(BusinessActivity.production, '1');
    expect(xp.currentXp, 54);
  });
  test('Worker points and derived speed preserve equipment configuration', () {
    final w = Worker(
      id: 't',
      name: 'Turhan',
      gridPosition: const GridPoint(0, 0),
      equipment: EquipmentType.teaShears,
    );
    addTearDown(w.dispose);
    for (var i = 0; i < 5; i++) {
      w.rewardHarvest('$i');
    }
    expect(w.workerLevel, 2);
    expect(w.developmentPoints, 1);
    expect(w.workerXpForNextLevel, 100);
    w.rewardHarvest('4');
    expect(w.developmentPoints, 1);
    expect(w.develop(harvest: true), true);
    expect(w.developmentPoints, 0);
    expect(w.develop(harvest: false), false);
    expect(w.harvestDuration.inMilliseconds, lessThan(4902));
    expect(
      equipmentDefinition(EquipmentType.teaShears).duration,
      const Duration(seconds: 5),
    );
    for (var i = 5; i < 15; i++) {
      w.rewardHarvest('$i');
    }
    expect(w.workerLevel, 3);
    expect(w.develop(harvest: false), true);
    expect(w.movementSpeed, closeTo(2.04, .001));
  });

  test('Long route respects five-customer cap', () {
    final finder = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {
        for (var x = 1; x < 20; x += 2)
          for (var y = 0; y < 20; y++)
            if (y != (x % 4 == 1 ? 19 : 0)) (x: x, y: y),
      },
    );
    s.gridPosition = const GridPoint(18, 18);
    final r = RetailSystem(
      economy: gold,
      pedestrians: finder,
      roads: finder,
      factory: () => f,
    )..shop = s;
    for (var i = 0; i < 700; i++) {
      r.advance(const Duration(milliseconds: 100), automatic: true);
      expect(r.customers.length, lessThanOrEqualTo(5));
    }
    expect(r.customers.length, 5);
    expect(gold.balance, 0);
  });
  test('Automation off creates no new visitors or packaging but active work finishes', () {
    final finder = GridPathfinder(columns: 20, rows: 20, blocked: {});
    final r =
        RetailSystem(
            economy: gold,
            pedestrians: finder,
            roads: finder,
            factory: () => f,
          )
          ..shop = s
          ..packaging = p;
    dryBatch();
    r.advance(const Duration(seconds: 60), automatic: false);
    expect(r.customers, isEmpty);
    expect(p.processing, false);
    expect(f.dryTeaKg, 20);
    p.startFrom(f);
    r.advance(const Duration(seconds: 8), automatic: false);
    expect(p.output.quantityUnits, 20);
    expect(gold.balance, 0);
  });
  group('Real automated revenue chain', () {
    late CayGame g;
    setUp(() => g = CayGame());
    tearDown(() => g.disposeState());
    void place(String id, int x, int y) {
      g.builder.choose(catalogItem(id));
      g.builder.preview(GridPoint(x.toDouble(), y.toDouble()));
      expect(g.builder.confirm(), true, reason: g.builder.feedback);
    }

    void until(bool Function() test) {
      for (var i = 0; i < 10000 && !test(); i++) {
        g.simulation.advance(const Duration(milliseconds: 100));
      }
      expect(test(), true);
    }

    void onboard() {
      g.tutorial!.begin();
      place('field', 5, 5);
      g.workforce.hire('turhan');
      g.workforce.buyEquipment(EquipmentType.teaShears);
      g.workforce.equip(g.worker, EquipmentType.teaShears);
      g.plantation.plant(g.plantation.fields.single);
      until(() => g.tutorial!.step == TutorialStep.buildCollectionCenter);
      place('collection_center', 9, 4);
      until(() => g.tutorial!.step == TutorialStep.deliveryComplete);
      g.tutorial!.finish();
    }

    test('Extra planting cannot spend the protected revenue-chain capital', () {
      onboard();
      place('field', 0, 0);
      g.economy.spend(g.economy.balance - 7500);
      final extra = g.plantation.fields.last;
      expect(g.plantation.plant(extra).name, 'restricted');
      expect(g.economy.balance, 7500);
      expect(extra.state.name, 'empty');
    });
    test(
      'Moving retail preserves stock; customer activity protects its location',
      () {
        onboard();
        place('factory', 9, 8);
        place('packaging', 12, 5);
        place('tea_shop', 6, 3);
        final p = g.retail.packaging!, s = g.retail.shop!;
        p.output.add(20);
        s.restock(p);
        expect(g.builder.startMove(p.id), true);
        g.builder.cancel();
        expect(p.output.quantityUnits, 10);
        expect(g.builder.startMove(s.id), true);
        g.builder.preview(const GridPoint(12, 8));
        expect(g.builder.confirm(), true, reason: g.builder.feedback);
        expect(s.shelf.stockUnits, 10);
        expect([s.gridPosition.x, s.gridPosition.y], [12, 8]);
        g.simulation.advance(const Duration(seconds: 10));
        expect(g.retail.customers, isNotEmpty);
        expect(g.canMove(s.id), false);
      },
    );
    test(
      'All infrastructure upgrades preserve stocks and change derived stats',
      () {
        onboard();
        place('factory', 9, 8);
        place('packaging', 12, 5);
        place('tea_shop', 6, 3);
        g.automation.enabled = false;
        until(
          () => g.vehicle.assignedJobId == null && g.jobs.currentJob == null,
        );
        g.progression.award('fixture', 1000);
        g.economy.earn(20000);
        final field = g.plantation.fields.single;
        final upgrades = [
          (field.id, 'growth'),
          (g.collectionCenter.id, 'collectionCapacity'),
          (g.factory.id, 'factorySpeed'),
          (g.retail.packaging!.id, 'packagingSpeed'),
          (g.retail.shop!.id, 'shelfCapacity'),
          (g.vehicle.id, 'truckSpeed'),
        ];
        g.factory.receiveRawTea(99);
        g.retail.packaging!.output.add(20);
        g.retail.shop!.restock(g.retail.packaging!);
        for (final (id, kind) in upgrades) {
          expect(g.upgrades.buy(id, kind), contains('geliştirildi'));
          expect(
            g.upgrades.options(id).firstWhere((o) => o.id == kind).level,
            2,
          );
        }
        expect(g.collectionCenter.capacityKg, 1500);
        expect(g.retail.shop!.shelf.capacityUnits, 15);
        expect(g.retail.shop!.shelf.stockUnits, 10);
        expect(g.factory.rawTeaKg, 99);
        expect(
          g.factory.productionDuration,
          lessThan(const Duration(seconds: 10)),
        );
        expect(
          g.retail.packaging!.duration,
          lessThan(const Duration(seconds: 8)),
        );
        expect(g.vehicle.movementSpeed, greaterThan(2.5));
      },
    );
    test('Starting capital and unlocks provide genuine first sale without extra grants', () {
      expect(g.economy.balance, 15000);
      onboard();
      expect(g.progression.level, 2);
      expect(g.workforce.workers.length, 1);
      expect(g.economy.balance, 10500);
      expect(g.objectives.current, BusinessObjective.factory);
      place('factory', 9, 8);
      place('packaging', 12, 5);
      place('tea_shop', 6, 3);
      final before = g.economy.balance;
      expect(before, 3000);
      until(() => g.retail.shop!.soldUnits > 0);
      expect(g.economy.balance, before + g.retail.shop!.soldUnits * 150);
      expect(g.factory.completedBatchCount, greaterThanOrEqualTo(1));
      expect(g.retail.packaging!.completedBatches, greaterThanOrEqualTo(1));
      final madeDry = g.factory.completedBatchCount * 20;
      expect(g.retail.processedKg + g.retail.shop!.soldUnits, madeDry);
      expect(g.plantation.fields.single.harvestCount, greaterThanOrEqualTo(4));
    });
    test(
      'Optional spending cannot consume the missing revenue chain budget',
      () {
        onboard();
        g.economy.spend(2500); // 8,000; full missing chain costs 7,500.
        expect(g.workforce.hire('havva').success, false);
        expect(g.economy.balance, 8000);
        place('factory', 9, 8);
        place('packaging', 12, 5);
        place('tea_shop', 6, 3);
        expect(g.economy.balance, 500);
      },
    );
    test(
      'Infrastructure upgrades enforce gates, charge once and cap at three',
      () {
        onboard();
        place('factory', 9, 8);
        place('packaging', 12, 5);
        place('tea_shop', 6, 3);
        g.automation.enabled = false;
        until(() => g.vehicle.assignedJobId == null);
        expect(
          g.upgrades.buy(g.vehicle.id, 'truckCapacity'),
          contains('Seviye 4'),
        );
        g.progression.award('upgrade-fixture', 1000);
        g.economy.earn(10000);
        until(() => g.vehicle.state.name == 'idle');
        final before = g.economy.balance;
        g.upgrades.buy(g.vehicle.id, 'truckCapacity');
        expect(g.vehicle.capacityKg, 125);
        expect(g.economy.balance, before - 750);
        g.upgrades.buy(g.vehicle.id, 'truckCapacity');
        expect(g.vehicle.capacityKg, 150);
        expect(g.economy.balance, before - 2250);
        expect(
          g.upgrades.buy(g.vehicle.id, 'truckCapacity'),
          contains('En yüksek'),
        );
        expect(g.economy.balance, before - 2250);
      },
    );
  });
}
