import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/workforce_state.dart';
import 'package:cay_simulasyonu/features/progression/progression_state.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/systems/objective_system.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';

import 'balance_harness.dart';

void main() {
  test('Paid connecting roads fund a farther real industrial route', () {
    final r = BalanceRun('E_ROADS');
    addTearDown(r.dispose);
    r.run(minutes: 6);
    expect(r.spending, BalanceRun.minimumCapital + 4 * 25);
    expect(r.firstSale, isNotNull);
    expect(r.game.automation.canShip, true);
    expect(r.game.retail.industrialConnected, true);
    expect(r.game.retail.retailConnected, true);
    r.check();
  });
  test(
    'Equivalent Turhan and Havva starters have identical physical throughput',
    () {
      final t = BalanceRun('F_TURHAN'), h = BalanceRun('F_HAVVA');
      addTearDown(t.dispose);
      addTearDown(h.dispose);
      t.run(minutes: 5);
      h.run(minutes: 5);
      for (final key in [
        'gold',
        'revenue',
        'harvestedRawKg',
        'soldUnits',
        'businessLevel',
        'businessXp',
      ]) {
        expect(t.snapshot()[key], h.snapshot()[key], reason: key);
      }
      expect(t.game.worker.workerLevel, h.game.worker.workerLevel);
      expect(t.game.worker.workerXp, h.game.worker.workerXp);
    },
  );
  test('Both legally hired workers perform work and receive their own XP', () {
    final r = BalanceRun('F_BOTH');
    addTearDown(r.dispose);
    r.run(minutes: 10);
    expect(r.game.workforce.workers.length, 2);
    for (final w in r.game.workforce.workers) {
      expect(
        (w.experience.toJson()['rewardedEvents'] as List).length,
        greaterThan(0),
      );
    }
    r.check();
  });
  test(
    '50ms and 250ms outer ticks preserve physical outcomes and event counts',
    () {
      final a = BalanceRun('E_MINIMUM'), b = BalanceRun('E_MINIMUM');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      a.run(minutes: 5);
      b.run(minutes: 5, stepMs: 50);
      for (final key in [
        'gold',
        'revenue',
        'harvestedRawKg',
        'soldUnits',
        'businessXp',
        'factoryBatches',
        'packagingBatches',
      ]) {
        expect(a.snapshot()[key], b.snapshot()[key], reason: key);
      }
    },
  );
  test(
    'Below-minimum capital is a real dead-end control, not waiting for growth',
    () {
      final r = BalanceRun('E_MINIMUM', initialGold: 11999);
      addTearDown(r.dispose);
      r.run(minutes: 1);
      expect(r.chain, false);
      expect(r.game.plantation.fields, isEmpty);
      expect(r.firstSale, null);
      expect(r.game.economy.balance, 11999);
      expect(r.game.builder.purchaseRestriction!(500, 'field'), isNotNull);
      expect(r.revenue, 0);
    },
  );
  test(
    'Same seed and real domains reproduce complete ledger and checkpoints',
    () {
      final a = BalanceRun('E_MINIMUM', initialGold: 12000),
          b = BalanceRun('E_MINIMUM', initialGold: 12000);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      expect(jsonEncode(a.run(minutes: 5)), jsonEncode(b.run(minutes: 5)));
      expect(a.firstSale, lessThan(300));
      expect(a.spending, 12000);
      expect(a.revenue, greaterThan(0));
      expect(a.game.economy.balance, a.revenue);
      expect(a.game.tutorial!.step, TutorialStep.completed);
      expect(a.game.progression.level, greaterThanOrEqualTo(2));
    },
  );
  test('Sixty-minute stability conserves products, Gold, jobs and worker XP', () {
    final r = BalanceRun('H_STABILITY');
    addTearDown(r.dispose);
    r.run();
    expect(r.invariantChecks, greaterThanOrEqualTo(3600));
    expect(r.firstPositive, isNotNull);
    expect(r.game.economy.balance, greaterThan(r.startingGold));
    expect(r.maxCustomers, lessThanOrEqualTo(5));
    // A single-field recipe needs four harvests; a shelf stockout is not a
    // stuck customer or logistics queue. Bound by a whole replenishment cycle.
    expect(r.seconds - r.lastSaleAt, lessThan(300));
    expect(r.levelTimes.keys, containsAll(['2', '3', '4', '5', '6']));
    final ids = r.game.progression.toJson()['rewardedEvents'] as List;
    expect(ids.toSet().length, ids.length);
    final stock = r.game.retail.shop!.shelf.stockUnits;
    final gold = r.game.economy.balance, xp = r.game.progression.currentXp;
    final soldId =
        (r.game.retail.shop!.toJson()['purchaseAttempts'] as List).last
            as String;
    expect(r.game.retail.shop!.purchase(soldId, r.game.economy), false);
    expect(r.game.economy.balance, gold);
    expect(r.game.progression.currentXp, xp);
    expect(r.game.retail.shop!.shelf.stockUnits, stock);
  }, timeout: const Timeout(Duration(minutes: 5)));
  test('Excess road spending is recoverable without magical Gold', () {
    final r = BalanceRun('D_POOR');
    addTearDown(r.dispose);
    r.run(minutes: 5);
    expect(r.blockedSpending, greaterThan(0));
    expect(r.firstSale, isNotNull);
    expect(r.revenue, r.game.retail.shop!.soldUnits * 150);
    expect(r.game.economy.balance, r.startingGold + r.revenue - r.spending);
  });
  test('Starter Havva is a real one-time choice with no duplicated second-worker XP', () {
    final r = BalanceRun('F_HAVVA');
    addTearDown(r.dispose);
    r.game.tutorial!.begin();
    r.place('field', 5, 5);
    expect(r.game.workforce.hireRestriction(workerCatalog.last), null);
    expect(r.game.workforce.hire('havva').success, true);
    expect(r.game.progression.currentXp, 20);
    expect(r.game.workforce.hire('turhan').success, false);
    expect(r.game.workforce.hire('havva').success, false);
    expect(r.game.workforce.workers.length, 1);
    expect(r.game.progression.currentXp, 20);
  });
  test(
    'Post tutorial objectives lead to revenue instead of mandatory extra hire',
    () {
      final r = BalanceRun('E_MINIMUM');
      addTearDown(r.dispose);
      while (r.game.tutorial!.step != TutorialStep.completed) {
        r.decision();
        r.game.simulation.advance(const Duration(seconds: 1));
      }
      expect(r.game.objectives.current, BusinessObjective.factory);
      expect(r.game.workforce.workers.length, 1);
      r.place('factory', 9, 8);
      expect(r.game.objectives.current, BusinessObjective.packaging);
      r.place('packaging', 12, 5);
      expect(r.game.objectives.current, BusinessObjective.shop);
      r.place('tea_shop', 6, 3);
      expect(r.game.objectives.current, BusinessObjective.firstSale);
      r.game.simulation.advance(const Duration(minutes: 6));
      r.place('field', 1, 5);
      expect(r.game.objectives.current, BusinessObjective.workerUpgrade);
      expect(r.game.tutorial!.category, isNull);
      expect(r.game.tutorial!.targetEntityId, 'turhan');
    },
  );
  test('Motor remains domain locked through level five; overflow supports multiple levels', () {
    final r = BalanceRun('E_MINIMUM');
    addTearDown(r.dispose);
    r.game.tutorial!.begin();
    r.place('field', 5, 5);
    expect(
      r.game.workforce.buyEquipment(EquipmentType.teaHarvesterMotor).success,
      false,
    );
    final p = ProgressionState();
    addTearDown(p.dispose);
    p.award('overflow', 1249);
    expect(p.level, 5);
    expect(p.currentXp, 449);
    p.award('last', 1);
    expect(p.level, 6);
    expect(p.currentXp, 0);
    expect(p.award('last', 10000), false);
    expect(p.level, 6);
  });
  test('Zero-cash shop can relocate for free and continue earning', () {
    final r = BalanceRun('E_MINIMUM', initialGold: 12000);
    addTearDown(r.dispose);
    // Only establish actual tutorial; no product or money fixtures.
    while (r.game.tutorial!.step != TutorialStep.completed) {
      r.decision();
      r.game.simulation.advance(const Duration(seconds: 1));
    }
    r.place('factory', 9, 8);
    r.place('packaging', 12, 5);
    r.place('tea_shop', 6, 3);
    expect(r.game.economy.balance, 0);
    final s = r.game.retail.shop!;
    expect(r.game.builder.startMove(s.id), true);
    r.game.builder.preview(const GridPoint(12, 8));
    expect(r.game.builder.confirm(), true);
    expect(r.game.economy.balance, 0);
    r.game.simulation.advance(const Duration(minutes: 5));
    expect(s.soldUnits, greaterThan(0));
    r.check();
  });
}
