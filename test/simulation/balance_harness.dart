import 'dart:math';

import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/tutorial_system.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:cay_simulasyonu/features/buildings/factory_config.dart';
import 'package:cay_simulasyonu/features/economy/business_config.dart';
import 'package:cay_simulasyonu/features/workers/workforce_state.dart';

/// Existing composition root without load/render, fake products, XP or income.
class BalanceRun {
  static int get minimumCapital =>
      [
        'field',
        'collection_center',
        'factory',
        'packaging',
        'tea_shop',
      ].fold<int>(0, (sum, id) => sum + catalogItem(id).goldCost) +
      WorkerOffer.cost +
      equipmentDefinition(EquipmentType.teaShears).cost +
      PlantationConfig.plantingCost;
  BalanceRun(this.scenario, {this.seed = 10101, int? initialGold})
    : game = CayGame(initialGold: initialGold),
      random = Random(seed) {
    startingGold = game.economy.balance;
    previousGold = startingGold;
    game.economy.addListener(ledger);
    game.progression.addListener(levels);
    game.tutorial!.begin();
  }
  final String scenario;
  final int seed;
  final CayGame game;
  final Random random;
  late final int startingGold;
  late int previousGold;
  int spending = 0,
      revenue = 0,
      blockedSpending = 0,
      maxCustomers = 0,
      invariantChecks = 0;
  String action = 'simulation';
  final transactions = <Map<String, Object?>>[],
      actions = <Map<String, Object?>>[],
      checkpoints = <Map<String, Object?>>[];
  final levelTimes = <String, double>{'1': 0}, unlockTimes = <String, double>{};
  final workerBusy = <String, double>{}, workerOwned = <String, double>{};
  double truckBusy = 0,
      factoryBusy = 0,
      packagingBusy = 0,
      truckOwned = 0,
      factoryOwned = 0,
      packagingOwned = 0,
      shelfEmpty = 0,
      shopOwned = 0,
      lastSaleAt = 0;
  double? firstSale,
      firstPositive,
      earned500,
      earned1000,
      secondAffordable,
      secondBuilt,
      tutorialFinished,
      interventionTime;
  int? interventionRevenue, interventionCost;
  int lastSales = 0, nextDecisionMs = 0;
  double maxActiveJobAge = 0;
  bool workforceChanged = false, mistakeDone = false, upgraded = false;
  double get seconds => game.plantation.simulationTime.inMicroseconds / 1e6;
  void ledger() {
    final diff = game.economy.balance - previousGold;
    previousGold = game.economy.balance;
    if (diff == 0) return;
    if (diff < 0) {
      spending -= diff;
    } else {
      revenue += diff;
      if (revenue != (game.retail.shop?.revenue ?? 0)) {
        throw StateError('Non-customer income');
      }
      firstSale ??= seconds;
      if (revenue >= 500) earned500 ??= seconds;
      if (revenue >= 1000) earned1000 ??= seconds;
      if (revenue > spending) firstPositive ??= seconds;
    }
    transactions.add({
      'seconds': seconds,
      'kind': diff < 0 ? 'spending' : 'revenue',
      'amount': diff.abs(),
      'reason': action,
      'balance': previousGold,
    });
  }

  void levels() {
    for (var l = 2; l <= game.progression.level; l++) {
      levelTimes.putIfAbsent('$l', () => seconds);
    }
    for (final i in buildCatalog) {
      if (game.unlocks.allows(i.requiredLevel)) {
        unlockTimes.putIfAbsent(i.id, () => seconds);
      }
    }
    for (final i in equipmentCatalog) {
      if (game.unlocks.allows(i.requiredLevel)) {
        unlockTimes.putIfAbsent(i.type.name, () => seconds);
      }
    }
    if (game.progression.level >= 2) {
      unlockTimes.putIfAbsent('havva', () => seconds);
    }
  }

  T doing<T>(String name, T Function() operation) {
    action = name;
    final result = operation();
    action = 'customerPurchaseCompleted';
    return result;
  }

  bool place(String id, int x, int y) => doing('place:$id@$x,$y', () {
    game.builder.choose(catalogItem(id));
    game.builder.preview(GridPoint(x.toDouble(), y.toDouble()));
    final success = game.builder.confirm();
    if (success) {
      actions.add({'seconds': seconds, 'action': 'place:$id', 'x': x, 'y': y});
    }
    game.builder.cancel();
    return success;
  });
  void hire(String id) => doing('hire:$id', () => game.workforce.hire(id));
  void shears(Worker w) {
    if (w.canHarvest) return;
    if (game.playerInventory.equipmentQuantity(EquipmentType.teaShears) == 0) {
      doing(
        'equipment:shears',
        () => game.workforce.buyEquipment(EquipmentType.teaShears),
      );
    }
    game.workforce.equip(w, EquipmentType.teaShears);
  }

  bool get chain =>
      game.activeFactory != null &&
      game.retail.packaging != null &&
      game.retail.shop != null;
  bool get aggressive =>
      scenario == 'C_AGGRESSIVE' || scenario.startsWith('F_');
  void decision() {
    final g = game;
    switch (g.tutorial!.step) {
      case TutorialStep.firstField:
        place('field', 5, 5);
        return;
      case TutorialStep.firstWorker:
        hire(scenario == 'F_HAVVA' ? 'havva' : 'turhan');
        return;
      case TutorialStep.buyShears:
        doing(
          'equipment:shears',
          () => g.workforce.buyEquipment(EquipmentType.teaShears),
        );
        return;
      case TutorialStep.equipWorker:
        g.workforce.equip(g.worker, EquipmentType.teaShears);
        return;
      case TutorialStep.plantTea:
        doing(
          'plant:first',
          () => g.plantation.plant(g.plantation.fields.first),
        );
        return;
      case TutorialStep.buildCollectionCenter:
        place('collection_center', 9, 4);
        return;
      case TutorialStep.deliveryComplete:
        g.tutorial!.finish();
        tutorialFinished = seconds;
        return;
      case TutorialStep.completed:
        break;
      default:
        return;
    }
    if (scenario == 'D_POOR' && !mistakeDone) {
      for (var y = 19; y >= 13; y--) {
        for (var x = 0; x < 20; x++) {
          if (!place('road', x, y)) blockedSpending++;
        }
      }
      final old = g.economy.balance;
      hire('havva');
      doing(
        'premature:motor',
        () => g.workforce.buyEquipment(EquipmentType.teaHarvesterMotor),
      );
      place('well', 0, 11);
      if (old == g.economy.balance) blockedSpending++;
      mistakeDone = true;
    }
    if (scenario == 'D_POOR' && seconds < 180) return;
    if (scenario == 'E_ROADS' && g.activeFactory == null) {
      for (var x = 13; x <= 16; x++) {
        if (!g.settlement.roads.contains((x: x, y: 7))) place('road', x, 7);
      }
    }
    if (g.activeFactory == null) {
      place('factory', scenario == 'E_ROADS' ? 13 : 9, 8);
      return;
    }
    if (g.retail.packaging == null) {
      place('packaging', scenario == 'E_ROADS' ? 16 : 12, 5);
      return;
    }
    if (g.retail.shop == null) {
      place('tea_shop', 6, 3);
      return;
    }
    if (secondAffordable == null &&
        g.economy.balance >= 750 &&
        g.progression.level >= 2 &&
        g.tutorialRules!.acquisition(750, 'field') == null) {
      secondAffordable = seconds;
    }
    final expand =
        aggressive ||
        (scenario == 'A_NORMAL' && revenue >= 500) ||
        (scenario == 'B_CONSERVATIVE' && seconds >= 1800);
    final desired = aggressive ? 4 : 2;
    if (expand && g.plantation.fields.length < desired) {
      const sites = [(5, 8), (3, 5), (12, 8)];
      final (x, y) = sites[g.plantation.fields.length - 1];
      if (g.economy.balance >= 750 && place('field', x, y)) {
        secondBuilt ??= seconds;
      }
      return;
    }
    for (final f in g.plantation.fields) {
      if (f.state == TeaFieldState.empty) {
        doing('plant:${f.id}', () => g.plantation.plant(f));
        return;
      }
    }
    final wantsHavva =
        (aggressive && scenario != 'F_TURHAN' && scenario != 'F_HAVVA') ||
        (scenario == 'A_NORMAL' && revenue >= 3000);
    if (wantsHavva && g.workforce.byId('havva') == null) {
      hire('havva');
      return;
    }
    final havva = g.workforce.byId('havva');
    if (havva != null && !havva.canHarvest) {
      shears(havva);
      return;
    }
    if (scenario == 'G_MOTOR' &&
        g.progression.level >= 6 &&
        !upgraded &&
        g.worker.state == WorkerState.idle) {
      final old = g.economy.balance;
      final result = doing(
        'equipment:motor',
        () => g.workforce.buyEquipment(EquipmentType.teaHarvesterMotor),
      );
      if (result.success &&
          g.workforce
              .equip(g.worker, EquipmentType.teaHarvesterMotor)
              .success) {
        upgraded = true;
        interventionTime = seconds;
        interventionRevenue = revenue;
        interventionCost = old - g.economy.balance;
      }
    }
    if (scenario.startsWith('U_') && seconds >= 600 && !upgraded) {
      final kind = scenario.substring(2);
      final id = switch (kind) {
        'growth' => g.plantation.fields.first.id,
        'collectionCapacity' => g.collectionCenter.id,
        'truckCapacity' || 'truckSpeed' => g.vehicle.id,
        'factorySpeed' => g.factory.id,
        'packagingSpeed' => g.retail.packaging!.id,
        'shelfCapacity' => g.retail.shop!.id,
        _ => g.worker.id,
      };
      final old = g.economy.balance;
      final message = doing(
        'upgrade:$kind',
        () => kind == 'workerHarvest' || kind == 'workerMovement'
            ? g.upgrades.developWorker(id, harvest: kind == 'workerHarvest')
            : g.upgrades.buy(id, kind),
      );
      if (message.contains('geliştirildi') || message.contains('kullanıldı')) {
        upgraded = true;
        interventionTime = seconds;
        interventionRevenue = revenue;
        interventionCost = old - g.economy.balance;
      }
    }
    if ((scenario == 'A_NORMAL' || scenario == 'C_AGGRESSIVE') &&
        revenue >= 6000) {
      for (final w in g.workforce.workers) {
        if (w.developmentPoints > 0) {
          g.upgrades.developWorker(w.id, harvest: true);
        }
      }
      if (!upgraded) {
        final message = doing(
          'upgrade:truckSpeed',
          () => g.upgrades.buy(g.vehicle.id, 'truckSpeed'),
        );
        upgraded = message.contains('geliştirildi');
      }
    }
  }

  void check() {
    final g = game,
        f = game.activeFactory,
        p = game.retail.packaging,
        s = game.retail.shop;
    final harvested = g.plantation.fields.fold<int>(
          0,
          (sum, f) => sum + f.harvestCount * f.yieldAmount,
        ),
        raw = g.transport.totalRawTeaKg,
        batches = f?.completedBatchCount ?? 0;
    if (harvested != raw + batches * FactoryConfig.inputKg) {
      throw StateError('Raw mass $scenario @$seconds');
    }
    if (g.retail.processedKg +
            (s?.soldUnits ?? 0) * ProductType.packagedTea1Kg.kgPerUnit !=
        batches * FactoryConfig.outputKg) {
      throw StateError('Dry mass $scenario @$seconds');
    }
    if (g.economy.balance != startingGold + revenue - spending ||
        revenue !=
            (s?.soldUnits ?? 0) * RetailEconomyConfig.packagedTea1KgPrice) {
      throw StateError('Gold ledger');
    }
    if ([
      g.economy.balance,
      raw,
      g.vehicle.cargoKg,
      f?.rawTeaKg ?? 0,
      f?.dryTeaKg ?? 0,
      p?.inputKg ?? 0,
      p?.output.quantityUnits ?? 0,
      s?.shelf.stockUnits ?? 0,
    ].any((v) => v < 0)) {
      throw StateError('Negative');
    }
    if (g.retail.customers.length > 5 ||
        g.vehicle.cargoKg > g.vehicle.capacityKg ||
        (s?.shelf.stockUnits ?? 0) > (s?.shelf.capacityUnits ?? 10)) {
      throw StateError('Capacity');
    }
    final fields = g.jobs.jobs
        .where((j) => j.isActive)
        .map((j) => j.fieldId)
        .toList();
    if (fields.toSet().length != fields.length) {
      throw StateError('Duplicate harvest');
    }
    final sources = g.transport.jobs
        .where((j) => j.isActive)
        .map((j) => '${j.sourceType}:${j.sourceId}')
        .toList();
    for (final j in [
      ...g.jobs.jobs,
      ...g.transport.jobs,
    ].where((j) => j.isActive)) {
      maxActiveJobAge = max(
        maxActiveJobAge,
        seconds - j.createdAt.inMicroseconds / 1e6,
      );
    }
    if (maxActiveJobAge > 300) throw StateError('Reachable job stalled >300s');
    if (sources.toSet().length != sources.length) {
      throw StateError('Duplicate transport');
    }
    for (final w in g.workforce.workers) {
      if (w.developmentPoints < 0 ||
          w.movementSpeed <= 0 ||
          (w.canHarvest && w.harvestDuration <= Duration.zero)) {
        throw StateError('Worker stats');
      }
      final done = g.jobs.jobs
          .where(
            (j) => j.status.name == 'completed' && j.assignedWorkerId == w.id,
          )
          .length;
      if ((w.experience.toJson()['rewardedEvents'] as List).length != done) {
        throw StateError('Wrong worker XP');
      }
    }
    maxCustomers = max(maxCustomers, g.retail.customers.length);
    invariantChecks++;
  }

  void sample(double dt) {
    final g = game;
    for (final w in g.workforce.workers) {
      workerOwned[w.id] = (workerOwned[w.id] ?? 0) + dt;
      if (w.state != WorkerState.idle) {
        workerBusy[w.id] = (workerBusy[w.id] ?? 0) + dt;
      }
    }
    if (g.activeCollectionCenter != null) {
      truckOwned += dt;
      if (g.vehicle.state.name != 'idle') truckBusy += dt;
    }
    if (g.activeFactory != null) {
      factoryOwned += dt;
      if (g.factory.processingInputKg > 0) factoryBusy += dt;
    }
    if (g.retail.packaging != null) {
      packagingOwned += dt;
      if (g.retail.packaging!.processing) packagingBusy += dt;
    }
    if (g.retail.shop != null) {
      shopOwned += dt;
      if (g.retail.shop!.shelf.stockUnits == 0) shelfEmpty += dt;
      if (g.retail.shop!.soldUnits != lastSales) {
        lastSales = g.retail.shop!.soldUnits;
        lastSaleAt = seconds;
      }
    }
  }

  String get bottleneck {
    final g = game;
    if (!chain) return 'Gelir zinciri henüz kurulmadı';
    if ((g.retail.packaging?.output.quantityUnits ?? 0) > 20 &&
        (g.retail.shop?.shelf.stockUnits ?? 0) > 0) {
      return 'Müşteri talebi';
    }
    if (truckOwned > 0 && truckBusy / truckOwned > .85) return 'Kamyon';
    if (g.plantation.fields.any((f) => f.state == TeaFieldState.ready)) {
      return 'Hasat kapasitesi';
    }
    return 'Tarla büyümesi / hammadde';
  }

  Map<String, Object?> snapshot() {
    final g = game,
        f = g.activeFactory,
        p = g.retail.packaging,
        s = g.retail.shop;
    double ratio(double a, double b) => b == 0 ? 0 : a / b;
    return {
      'scenario': scenario,
      'seed': seed,
      'seconds': seconds,
      'minutes': seconds / 60,
      'startingGold': startingGold,
      'gold': g.economy.balance,
      'revenue': revenue,
      'rewardGold': 0,
      'spending': spending,
      'netCashFlow': revenue - spending,
      'grossGoldPerMinute': revenue / (seconds / 60),
      'businessLevel': g.progression.level,
      'businessXp': g.progression.currentXp,
      'levelTimes': Map.of(levelTimes),
      'unlockTimes': Map.of(unlockTimes),
      'workers': [
        for (final w in g.workforce.workers)
          {
            'id': w.id,
            'level': w.workerLevel,
            'xp': w.workerXp,
            'nextXp': w.workerXpForNextLevel,
            'equipment': w.equipment.name,
            'points': w.developmentPoints,
            'harvestPoints': w.harvestPoints,
            'movementPoints': w.movementPoints,
            'harvestSeconds': w.harvestDuration.inMicroseconds / 1e6,
            'movementSpeed': w.movementSpeed,
            'utilization': ratio(workerBusy[w.id] ?? 0, workerOwned[w.id] ?? 0),
            'harvests':
                (w.experience.toJson()['rewardedEvents'] as List).length,
          },
      ],
      'fieldCount': g.plantation.fields.length,
      'workerCount': g.workforce.workers.length,
      'fieldLevels': g.plantation.fields.map((f) => f.growthLevel).toList(),
      'harvestedRawKg': g.plantation.fields.fold<int>(
        0,
        (sum, f) => sum + f.harvestCount * f.yieldAmount,
      ),
      'fieldStockKg': g.plantation.fields.fold<int>(
        0,
        (sum, f) => sum + f.harvestedStockKg,
      ),
      'truckKg': g.vehicle.cargoKg,
      'collectionKg': g.activeCollectionCenter?.receivedTeaKg ?? 0,
      'factoryRawKg': f?.rawTeaKg ?? 0,
      'factoryInputKg': f?.processingInputKg ?? 0,
      'factoryBatches': f?.completedBatchCount ?? 0,
      'factoryDryKg': f?.dryTeaKg ?? 0,
      'packagingInputKg': p?.inputKg ?? 0,
      'packagingBatches': p?.completedBatches ?? 0,
      'packagedStockUnits': p?.output.quantityUnits ?? 0,
      'shelfStockUnits': s?.shelf.stockUnits ?? 0,
      'soldUnits': s?.soldUnits ?? 0,
      'customersSpawned': g.retail.customersSpawned,
      'customersArrived': g.retail.customersArrived,
      'customersServed': g.retail.customersServed,
      'customersLost': g.retail.customersLost,
      'activeCustomers': g.retail.customers.length,
      'maxActiveCustomers': maxCustomers,
      'shelfStockoutFraction': ratio(shelfEmpty, shopOwned),
      'truckUtilization': ratio(truckBusy, truckOwned),
      'factoryUtilization': ratio(factoryBusy, factoryOwned),
      'packagingUtilization': ratio(packagingBusy, packagingOwned),
      'harvestQueue': g.jobs.queuedCount,
      'transportQueue': g.transport.queuedCount,
      'harvestJobs': g.jobs.jobs.length,
      'transportJobs': g.transport.jobs.length,
      'firstSaleSeconds': firstSale,
      'firstPositiveNetCashFlowSeconds': firstPositive,
      'earned500Seconds': earned500,
      'earned1000Seconds': earned1000,
      'secondFieldAffordableSeconds': secondAffordable,
      'secondFieldBuiltSeconds': secondBuilt,
      'tutorialCompletedSeconds': tutorialFinished,
      'truckCapacityLevel': g.vehicle.capacityLevel,
      'truckSpeedLevel': g.vehicle.speedLevel,
      'collectionCapacityLevel': g.activeCollectionCenter?.capacityLevel,
      'factorySpeedLevel': f?.speedLevel,
      'packagingSpeedLevel': p?.speedLevel,
      'shelfLevel': s?.shelfLevel,
      'interventionSeconds': interventionTime,
      'interventionCost': interventionCost,
      'interventionRevenue': interventionRevenue,
      'blockedSpending': blockedSpending,
      'mainBottleneck': bottleneck,
      'maxActiveJobAgeSeconds': maxActiveJobAge,
      'invariantChecks': invariantChecks,
      'salesStalledSeconds': s == null ? null : seconds - lastSaleAt,
    };
  }

  Map<String, Object?> run({int minutes = 60, int stepMs = 250}) {
    final stop = minutes * 60000;
    while (game.plantation.simulationTime.inMilliseconds < stop) {
      final ms = game.plantation.simulationTime.inMilliseconds;
      if (ms >= nextDecisionMs) {
        decision();
        nextDecisionMs = ms + 1000 + random.nextInt(5) * 250;
      }
      game.simulation.advance(Duration(milliseconds: stepMs));
      sample(stepMs / 1000);
      final now = game.plantation.simulationTime.inMilliseconds;
      if (now % 1000 == 0) check();
      if ([300000, 900000, 1800000, 3600000].contains(now) || now == stop) {
        checkpoints.add(snapshot());
      }
    }
    check();
    return {
      'scenario': scenario,
      'seed': seed,
      'checkpoints': checkpoints,
      'transactions': transactions,
      'actions': actions,
    };
  }

  void dispose() => game.disposeState();
}
