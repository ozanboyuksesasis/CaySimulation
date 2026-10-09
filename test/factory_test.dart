import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/world/road_tiles.dart';
import 'package:cay_simulasyonu/features/buildings/tea_factory.dart';
import 'package:cay_simulasyonu/features/buildings/factory_config.dart';
import 'package:cay_simulasyonu/features/transport/transport_job.dart';
import 'package:cay_simulasyonu/features/transport/transport_vehicle.dart';
import 'package:cay_simulasyonu/features/transport/transport_config.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';

void main() {
  late CayGame game;
  setUp(
    () => game = CayGame(
      initialGold: 10000,
      guidedTutorial: false,
      mapMode: GameMapMode.devTest,
    ),
  );
  tearDown(() => game.disposeState());
  void advance(Duration time) => game.simulation.advance(time);
  void until(VehicleState state) {
    for (var i = 0; i < 150 && game.vehicle.state != state; i++) {
      advance(
        game.transport.timeToNextEvent ?? const Duration(microseconds: 1),
      );
    }
    expect(game.vehicle.state, state);
  }

  TransportJob order([int amount = 100]) {
    game.collectionCenter.receive(amount);
    return game.transport.requestFactoryShipment()!;
  }

  TransportJob load([int amount = 100]) {
    final job = order(amount);
    until(VehicleState.loading);
    advance(TransportConfig.loadingDuration);
    return job;
  }

  TransportJob deliver([int amount = 100]) {
    final job = load(amount);
    until(VehicleState.unloading);
    advance(TransportConfig.unloadingDuration);
    return job;
  }

  void prepareField() {
    final field = game.plantation.fields.first;
    game.plantation.plant(field);
    advance(PlantationConfig.growthDuration);
    game.jobs.requestHarvest(field);
    advance(const Duration(seconds: 20));
  }

  test('01 Stoklu alım yeri fabrika sevkiyatı oluşturur', () {
    final job = order();
    expect(job.sourceId, game.collectionCenter.id);
    expect(job.destinationId, game.factory.id);
    expect(job.isFactoryShipment, isTrue);
    expect(job.sourceType, TransportLocation.collectionCenter);
  });
  test('02 Boş alım yerinden sevkiyat oluşturulmaz', () {
    expect(game.transport.requestFactoryShipment(), isNull);
    expect(game.transport.jobs, isEmpty);
  });
  test('03 Aktif sevkiyat çoğaltılmaz', () {
    final first = order();
    expect(game.transport.requestFactoryShipment(), same(first));
    expect(game.transport.jobs.length, 1);
  });
  test('04 Sevkiyat araç kapasitesini aşmaz', () {
    expect(order(500).requestedAmountKg, game.vehicle.capacityKg);
  });
  test('05 150 kg stoktan yalnızca 100 kg sevk edilir', () {
    final job = load(150);
    expect(job.requestedAmountKg, 100);
    expect(job.amountKg, 100);
    expect(game.collectionCenter.receivedTeaKg, 50);
  });
  test('06 Alım yerine yol karolarından akıcı hareket eder', () {
    order();
    expect(game.transport.remainingPath.every(roadTiles.contains), isTrue);
    final start = game.vehicle.gridPosition;
    advance(const Duration(milliseconds: 100));
    final now = game.vehicle.gridPosition;
    expect(
      (start.x - now.x).abs() + (start.y - now.y).abs(),
      closeTo(0.25, 1e-6),
    );
    expect(game.vehicle.state, VehicleState.movingToCollectionCenterForLoading);
  });
  test('07 Üç saniye bitmeden alım yerinin stoğu değişmez', () {
    order();
    until(VehicleState.loading);
    advance(TransportConfig.loadingDuration - const Duration(microseconds: 1));
    expect(game.collectionCenter.receivedTeaKg, 100);
    expect(game.vehicle.cargoKg, 0);
  });
  test('08 Yükleme alım yeri stoğunu kamyona aktarır', () {
    load(50);
    expect(game.collectionCenter.receivedTeaKg, 0);
    expect(game.vehicle.cargoKg, 50);
  });
  test('09 Yüklemede ham çay miktarı dinleyiciler için de korunur', () {
    order();
    game.collectionCenter.addListener(
      () => expect(game.transport.totalRawTeaKg, 100),
    );
    game.vehicle.addListener(() => expect(game.transport.totalRawTeaKg, 100));
    until(VehicleState.loading);
    advance(TransportConfig.loadingDuration);
    expect(game.transport.totalRawTeaKg, 100);
  });
  test('10 Yüklü kamyon fabrikaya fiziksel yoldan gider', () {
    final job = load();
    expect(job.status, JobStatus.movingToDestination);
    expect(game.vehicle.state, VehicleState.movingToFactory);
    expect(
      game.transport.remainingPath.every(game.vehiclePathfinder.walkable),
      isTrue,
    );
    expect(game.transport.remainingPath.every(roadTiles.contains), isTrue);
  });
  test('11 Fabrikanın dış teslim karosunda durur', () {
    load();
    until(VehicleState.unloading);
    expect(tileAt(game.vehicle.gridPosition), factoryDeliveryTile);
    expect(
      game.vehiclePathfinder.interactionTiles(
        game.factory.gridPosition,
        game.factory.footprint,
      ),
      contains(factoryDeliveryTile),
    );
    expect(
      GridPathfinder.footprintTiles(
        game.factory.gridPosition,
        game.factory.footprint,
      ),
      isNot(contains(factoryDeliveryTile)),
    );
  });
  test('12 Teslimat üç saniyeden önce stok eklemez', () {
    load();
    until(VehicleState.unloading);
    advance(
      TransportConfig.unloadingDuration - const Duration(microseconds: 1),
    );
    expect(game.factory.rawTeaKg, 0);
    expect(game.vehicle.cargoKg, 100);
  });
  test('13 Teslimat fabrika yaş çay stoğunu artırır', () {
    deliver(50);
    expect(game.factory.rawTeaKg, 50);
  });
  test('14 Fabrika teslimatında kamyon tamamen boşalır', () {
    deliver();
    expect(game.vehicle.cargoKg, 0);
  });
  test('15 Fabrika boşaltmasında ham çay korunur', () {
    load();
    game.factory.addListener(() => expect(game.transport.totalRawTeaKg, 100));
    until(VehicleState.unloading);
    advance(TransportConfig.unloadingDuration);
    expect(game.transport.totalRawTeaKg, 100);
  });
  test('16 99 kg ile üretim başlatılmaz', () {
    game.factory.receiveRawTea(99);
    expect(game.factory.startProduction(), isFalse);
    expect(game.factory.rawTeaKg, 99);
    expect(game.factory.missingInputKg, 1);
  });
  test('17 100 kg ile üretim başlatılabilir', () {
    game.factory.receiveRawTea(100);
    expect(game.factory.startProduction(), isTrue);
    expect(game.factory.state, FactoryState.processing);
  });
  test('18 Başlangıçta tam 100 kg partiye ayrılır', () {
    game.factory.receiveRawTea(250);
    game.factory.startProduction();
    expect(game.factory.rawTeaKg, 150);
    expect(game.factory.processingInputKg, 100);
    expect(game.transport.totalRawTeaKg, 250);
  });
  test('19 Üretim anında ürün vermez ve çift başlatılamaz', () {
    game.factory.receiveRawTea(250);
    game.factory.startProduction();
    expect(game.factory.dryTeaKg, 0);
    expect(game.factory.startProduction(), isFalse);
    expect(game.factory.rawTeaKg, 150);
    expect(game.factory.processingInputKg, 100);
  });
  test('20 Yapılandırılmış on saniyenin sınırı korunur', () {
    game.factory.receiveRawTea(100);
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration - const Duration(microseconds: 1));
    expect(game.factory.state, FactoryState.processing);
    expect(game.factory.dryTeaKg, 0);
    advance(const Duration(microseconds: 1));
    expect(game.factory.state, FactoryState.idle);
  });
  test('21 Tek proses tam 20 kg kuru çay oluşturur', () {
    game.factory.receiveRawTea(100);
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.factory.dryTeaKg, FactoryConfig.outputKg);
    expect(game.transport.totalRawTeaKg, 0);
  });
  test('22 Tamamlanan partinin girdisi sıfırlanır', () {
    game.factory.receiveRawTea(100);
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.factory.processingInputKg, 0);
  });
  test('23 Üretim tamamlanınca bekliyor olur', () {
    game.factory.receiveRawTea(100);
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.factory.state, FactoryState.idle);
  });
  test('24 250 kg iki ayrı oyuncu emriyle iki parti üretir', () {
    game.factory.receiveRawTea(250);
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.factory.rawTeaKg, 150);
    expect(game.factory.dryTeaKg, 20);
    expect(game.factory.startProduction(), isTrue);
    advance(FactoryConfig.productionDuration);
    expect(game.factory.dryTeaKg, 40);
  });
  test('25 Kalan 50 kg otomatik tüketilmez veya yuvarlanmaz', () {
    game.factory.receiveRawTea(250);
    for (var i = 0; i < 2; i++) {
      game.factory.startProduction();
      advance(FactoryConfig.productionDuration);
    }
    advance(const Duration(days: 1));
    expect(game.factory.rawTeaKg, 50);
    expect(game.factory.startProduction(), isFalse);
    expect(game.factory.dryTeaKg, 40);
  });
  test('26 Sevkiyat ve üretim altın kazandırmaz', () {
    final gold = game.economy.balance;
    deliver();
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.economy.balance, gold);
  });
  test('27 Kuru çay sadece fabrikada kalır, global envanter değişmez', () {
    deliver();
    game.factory.startProduction();
    advance(FactoryConfig.productionDuration);
    expect(game.factory.dryTeaKg, 20);
    expect(game.inventory.freshTeaKg, 0);
    expect(game.collectionCenter.receivedTeaKg, 0);
    expect(game.vehicle.cargoKg, 0);
  });
  test(
    '28 Tarla nakliyesi ve fabrika sevkiyatı aynı FIFO kuyruğunda çalışır',
    () {
      prepareField();
      final first = game.transport.requestTransport(
        game.plantation.fields.first,
      )!;
      final second = order(100);
      expect(second.status, JobStatus.queued);
      expect(game.vehicle.assignedJobId, first.id);
      until(VehicleState.unloading);
      advance(TransportConfig.unloadingDuration);
      expect(first.status, JobStatus.completed);
      expect(game.vehicle.assignedJobId, second.id);
      advance(const Duration(minutes: 1));
      expect(second.status, JobStatus.completed);
      expect(game.factory.rawTeaKg, 100);
      expect(game.collectionCenter.receivedTeaKg, 25);
    },
  );
  test('29 Mehmet hasadı 25 kg tarla stoğu oluşturmaya devam eder', () {
    prepareField();
    expect(game.plantation.fields.first.harvestedStockKg, 25);
    expect(game.worker.state, WorkerState.idle);
  });
  test('30 İşçi kamyon ve fabrika aynı saatte bağımsız ilerler', () {
    final field = game.plantation.fields.first;
    game.plantation.plant(field);
    advance(PlantationConfig.growthDuration);
    game.jobs.requestHarvest(field);
    order();
    game.factory.receiveRawTea(100);
    game.factory.startProduction();
    final workerStart = game.worker.gridPosition;
    final truckStart = game.vehicle.gridPosition;
    final time = game.plantation.simulationTime;
    advance(const Duration(milliseconds: 100));
    expect(game.worker.gridPosition == workerStart, isFalse);
    expect(game.vehicle.gridPosition == truckStart, isFalse);
    expect(game.factory.progress, closeTo(0.01, 1e-6));
    expect(
      game.plantation.simulationTime,
      time + const Duration(milliseconds: 100),
    );
    advance(const Duration(seconds: 30));
    expect(field.harvestedStockKg, 25);
    expect(game.factory.dryTeaKg, 20);
    expect(game.factory.rawTeaKg, 100);
  });
  test('31 Fabrikaya yol yoksa kamyon yükü korunur', () {
    order();
    until(VehicleState.loading);
    game.transport.pathfinder = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {...game.pathfinder.blocked, factoryDeliveryTile},
      allowed: roadTiles,
    );
    advance(TransportConfig.loadingDuration);
    expect(game.vehicle.state, VehicleState.blocked);
    expect(game.vehicle.cargoKg, 100);
    expect(
      game.transport.currentJob!.failureMessage,
      'Çay Fabrikasına ulaşılacak araç yolu bulunamadı.',
    );
    advance(const Duration(minutes: 1));
    expect(game.vehicle.cargoKg, 100);
    expect(game.factory.rawTeaKg, 0);
    game.transport.pathfinder = game.vehiclePathfinder;
    game.transport.retryRoute();
    advance(const Duration(minutes: 1));
    expect(game.factory.rawTeaKg, 100);
  });
  test('32 Yükleme öncesi yol hatası alım yeri stoğunu korur', () {
    game.transport.pathfinder = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {...game.pathfinder.blocked, collectionDeliveryTile},
      allowed: roadTiles,
    );
    final job = order();
    expect(job.status, JobStatus.failed);
    expect(game.collectionCenter.receivedTeaKg, 100);
    expect(game.vehicle.cargoKg, 0);
  });
  test('33 Fabrika tesliminden sonra sıradaki tarla işi alınır', () {
    prepareField();
    final shipment = order();
    final fieldJob = game.transport.requestTransport(
      game.plantation.fields.first,
    )!;
    until(VehicleState.unloading);
    advance(TransportConfig.unloadingDuration);
    expect(shipment.status, JobStatus.completed);
    expect(game.vehicle.assignedJobId, fieldJob.id);
  });
  test('34 Fabrika tesliminden sonra kuyruk boşsa garaja döner', () {
    deliver();
    expect(game.vehicle.state, VehicleState.returning);
    until(VehicleState.idle);
    expect(tileAt(game.vehicle.gridPosition), truckHomeTile);
  });
  test('35 Gerçek yol ağı fabrikaya bağlıdır, hata tanısı açıktır', () {
    expect(game.transport.validateRoutes(), isEmpty);
    game.transport.pathfinder = GridPathfinder(
      columns: 20,
      rows: 20,
      blocked: {...game.pathfinder.blocked, factoryDeliveryTile},
      allowed: roadTiles,
    );
    expect(
      game.transport.validateRoutes(),
      contains('Çay Fabrikasına ulaşılacak araç yolu bulunamadı.'),
    );
  });
  test('36 Fazla geçen süre ikinci partiyi otomatik başlatmaz', () {
    game.factory.receiveRawTea(250);
    game.factory.startProduction();
    advance(const Duration(hours: 1));
    expect(game.factory.dryTeaKg, 20);
    expect(game.factory.rawTeaKg, 150);
    expect(game.factory.state, FactoryState.idle);
  });
  test('37 Modeller JSON uyumludur, geçersiz miktar ve zaman reddedilir', () {
    final job = order();
    expect(
      jsonDecode(jsonEncode(job.toJson()))['sourceType'],
      'collectionCenter',
    );
    expect(jsonDecode(jsonEncode(game.factory.toJson()))['rawTeaKg'], 0);
    expect(() => game.factory.receiveRawTea(-1), throwsArgumentError);
    expect(
      () => game.factory.advance(const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(() => game.collectionCenter.removeTea(101), throwsArgumentError);
  });
  test('38 Sipariş edilen miktar sonradan gelen çayla sessizce büyümez', () {
    order(50);
    game.collectionCenter.receive(100);
    until(VehicleState.loading);
    advance(TransportConfig.loadingDuration);
    expect(game.vehicle.cargoKg, 50);
    expect(game.collectionCenter.receivedTeaKg, 100);
  });
}
