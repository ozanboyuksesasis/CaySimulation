import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/buildings/tea_collection_center.dart';
import 'package:cay_simulasyonu/features/economy/economy_state.dart';
import 'package:cay_simulasyonu/features/economy/inventory_state.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_system.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/transport/transport_config.dart';
import 'package:cay_simulasyonu/features/transport/transport_job.dart';
import 'package:cay_simulasyonu/features/transport/transport_system.dart';
import 'package:cay_simulasyonu/features/transport/transport_vehicle.dart';
import 'package:cay_simulasyonu/features/workers/job_system.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';
import 'package:cay_simulasyonu/game/systems/world_simulation.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';

class LogisticsFixture {
  LogisticsFixture({int capacity = 100}) {
    fields = [
      for (var i = 0; i < 3; i++)
        TeaField(
          id: 'field-$i',
          gridPosition: GridPoint(2.0 + i * 4, 2),
          footprint: const Footprint(2, 2),
        ),
    ];
    plantation = PlantationSystem(
      economy: economy,
      inventory: inventory,
      fields: fields,
    );
    for (final field in fields) {
      plantation.plant(field);
    }
    plantation.advance(PlantationConfig.growthDuration);
    for (final field in fields) {
      field.completeHarvest(plantation.simulationTime);
    }
    blocked = {
      for (final field in fields)
        ...GridPathfinder.footprintTiles(field.gridPosition, field.footprint),
      ...GridPathfinder.footprintTiles(center.gridPosition, center.footprint),
    };
    worker = Worker(
      equipment: EquipmentType.teaShears,
      id: 'worker',
      name: 'Mehmet',
      gridPosition: const GridPoint(2.5, 6.5),
    );
    workers = JobSystem(
      worker: worker,
      plantation: plantation,
      pathfinder: GridPathfinder(columns: 20, rows: 20, blocked: blocked),
    );
    vehicle = TransportVehicle(
      id: 'truck',
      displayName: 'Çay Kamyonu',
      homePosition: (x: 0, y: 4),
      capacityKg: capacity,
    );
    transport = TransportSystem(
      vehicle: vehicle,
      plantation: plantation,
      center: center,
      pathfinder: finder(),
      pickups: {for (var i = 0; i < 3; i++) fields[i].id: (x: 2 + i * 4, y: 4)},
    );
    simulation = WorldSimulation(workers: workers, transport: transport);
  }
  final economy = EconomyState();
  final inventory = InventoryState();
  final center = TeaCollectionCenter(
    id: 'center',
    gridPosition: const GridPoint(14, 2),
    footprint: const Footprint(2, 2),
    deliveryInteractionTile: (x: 14, y: 4),
  );
  final roads = {for (var x = 0; x < 20; x++) (x: x, y: 4)};
  late final List<TeaField> fields;
  late final Set<GridTile> blocked;
  late final PlantationSystem plantation;
  late final Worker worker;
  late final JobSystem workers;
  late final TransportVehicle vehicle;
  late final TransportSystem transport;
  late final WorldSimulation simulation;
  TeaField get a => fields[0];
  TeaField get b => fields[1];
  TeaField get c => fields[2];
  GridPathfinder finder({Set<GridTile> extraBlocked = const {}}) =>
      GridPathfinder(
        columns: 20,
        rows: 20,
        blocked: {...blocked, ...extraBlocked},
        allowed: roads,
      );
  void advance(Duration time) => simulation.advance(time);
  void until(VehicleState state) {
    for (var i = 0; i < 100 && vehicle.state != state; i++) {
      advance(transport.timeToNextEvent ?? const Duration(microseconds: 1));
    }
    expect(vehicle.state, state);
  }

  TransportJob load() {
    final job = transport.requestTransport(a)!;
    until(VehicleState.loading);
    advance(TransportConfig.loadingDuration);
    return job;
  }

  TransportJob deliver() {
    final job = load();
    until(VehicleState.unloading);
    advance(TransportConfig.unloadingDuration);
    return job;
  }

  void dispose() {
    transport.dispose();
    workers.dispose();
    vehicle.dispose();
    worker.dispose();
    plantation.dispose();
    economy.dispose();
    inventory.dispose();
    center.dispose();
  }
}

void main() {
  late LogisticsFixture f;
  setUp(() => f = LogisticsFixture());
  tearDown(() => f.dispose());
  test('01 Stoklu tarla tek taşıma işi oluşturur', () {
    final job = f.transport.requestTransport(f.a)!;
    expect(job.fieldId, f.a.id);
    expect(f.transport.jobs, [job]);
  });
  test('02 Stoksuz tarla emir veremez', () {
    f.a.removeHarvestedStock(25);
    expect(f.transport.requestTransport(f.a), isNull);
    expect(f.transport.jobs, isEmpty);
  });
  test('03 Tekrarlanan emir çoğaltılmaz', () {
    final job = f.transport.requestTransport(f.a);
    expect(f.transport.requestTransport(f.a), same(job));
    expect(f.transport.jobs.length, 1);
  });
  test('04 Boştaki kamyon ilk işi alır', () {
    final job = f.transport.requestTransport(f.a)!;
    expect(f.vehicle.assignedJobId, job.id);
    expect(job.vehicleId, f.vehicle.id);
    expect(f.vehicle.state, VehicleState.movingToField);
  });
  test('05 Meşgul kamyona ikinci eşzamanlı iş atanmaz', () {
    final first = f.transport.requestTransport(f.a)!;
    final second = f.transport.requestTransport(f.b)!;
    expect(f.vehicle.assignedJobId, first.id);
    expect(second.vehicleId, isNull);
  });
  test('06 Birden fazla emir FIFO kuyruğundadır', () {
    f.transport.requestTransport(f.a);
    final second = f.transport.requestTransport(f.b)!;
    final third = f.transport.requestTransport(f.c)!;
    expect(f.transport.jobs.where((j) => j.status == JobStatus.queued), [
      second,
      third,
    ]);
  });
  test('07 Araç yolu yalnızca izinli yol karolarından geçer', () {
    f.transport.requestTransport(f.a);
    expect(f.transport.remainingPath.every(f.roads.contains), isTrue);
    expect(
      f.transport.pathfinder.findPath((x: 0, y: 4), [(x: 0, y: 5)]),
      isNull,
    );
  });
  test('08 Yükleme noktası erişilebilir tarla kenarıdır', () {
    final job = f.transport.requestTransport(f.a)!;
    f.until(VehicleState.loading);
    expect(tileAt(f.vehicle.gridPosition), job.sourcePosition);
    expect(
      f.transport.pathfinder.interactionTiles(f.a.gridPosition, f.a.footprint),
      contains(job.sourcePosition),
    );
  });
  test('09 Araç tarlanın kapladığı alana girmez', () {
    f.transport.requestTransport(f.a);
    final interior = GridPathfinder.footprintTiles(
      f.a.gridPosition,
      f.a.footprint,
    ).toSet();
    expect(f.transport.remainingPath.any(interior.contains), isFalse);
    f.until(VehicleState.loading);
    expect(interior.contains(tileAt(f.vehicle.gridPosition)), isFalse);
  });
  test('10 Yükleme bitmeden stok aktarılmaz', () {
    f.transport.requestTransport(f.a);
    f.until(VehicleState.loading);
    f.advance(
      TransportConfig.loadingDuration - const Duration(microseconds: 1),
    );
    expect(f.a.harvestedStockKg, 25);
    expect(f.vehicle.cargoKg, 0);
  });
  test('11 Yükleme tam 25 kg aktarır', () {
    final job = f.load();
    expect(job.amountKg, 25);
    expect(f.a.harvestedStockKg + f.vehicle.cargoKg, 25);
  });
  test('12 Tam yüklemede tarla boşalır', () {
    f.load();
    expect(f.a.harvestedStockKg, 0);
  });
  test('13 Kamyon yükü 25 kg olur', () {
    f.load();
    expect(f.vehicle.cargoKg, 25);
  });
  test('14 Yenilenme stok sıfırlandığında başlar, teslimatı beklemez', () {
    f.transport.requestTransport(f.a);
    f.until(VehicleState.loading);
    expect(f.a.stageDuration, isNull);
    f.advance(TransportConfig.loadingDuration);
    expect(f.a.remainingSeconds, 5);
    expect(f.center.receivedTeaKg, 0);
    expect(f.a.stateStartedAt, f.plantation.simulationTime);
    f.advance(const Duration(seconds: 5));
    expect(f.a.state, TeaFieldState.growing1);
    expect(f.center.receivedTeaKg, 0);
  });
  test('15 Yükleme sonrası alım yerine fiziksel hareket başlar', () {
    final job = f.load();
    final position = f.vehicle.gridPosition;
    expect(job.status, JobStatus.movingToDestination);
    expect(f.vehicle.state, VehicleState.movingToCollectionCenter);
    f.advance(const Duration(milliseconds: 100));
    expect(f.vehicle.gridPosition.x - position.x, closeTo(0.25, 1e-8));
  });
  test('16 Teslim karosuna ulaşır, bina içine girmez', () {
    f.load();
    f.until(VehicleState.unloading);
    expect(tileAt(f.vehicle.gridPosition), f.center.deliveryInteractionTile);
    expect(
      GridPathfinder.footprintTiles(f.center.gridPosition, f.center.footprint),
      isNot(contains(tileAt(f.vehicle.gridPosition))),
    );
  });
  test('17 Boşaltma bitmeden teslim alınmaz', () {
    f.load();
    f.until(VehicleState.unloading);
    f.advance(
      TransportConfig.unloadingDuration - const Duration(microseconds: 1),
    );
    expect(f.vehicle.cargoKg, 25);
    expect(f.center.receivedTeaKg, 0);
  });
  test('18 Boşaltma tam kamyon yükünü aktarır', () {
    final job = f.deliver();
    expect(job.deliveredKg, 25);
    expect(f.center.receivedTeaKg, 25);
  });
  test('19 Teslim sonrası kamyon yükü sıfırdır', () {
    f.deliver();
    expect(f.vehicle.cargoKg, 0);
  });
  test('20 Alım yeri birden fazla teslimatı biriktirir', () {
    f.transport.requestTransport(f.a);
    f.transport.requestTransport(f.b);
    f.advance(const Duration(minutes: 1));
    expect(f.center.receivedTeaKg, 50);
  });
  test('21 Başarılı teslimat işi tamamlar', () {
    expect(f.deliver().status, JobStatus.completed);
  });
  test('22 Sonraki FIFO işi garaja dönmeden alır', () {
    final first = f.load();
    final second = f.transport.requestTransport(f.b)!;
    final third = f.transport.requestTransport(f.c)!;
    f.until(VehicleState.unloading);
    f.advance(TransportConfig.unloadingDuration);
    expect(first.status, JobStatus.completed);
    expect(f.vehicle.assignedJobId, second.id);
    expect(tileAt(f.vehicle.gridPosition), f.center.deliveryInteractionTile);
    expect(f.vehicle.state, VehicleState.movingToField);
    expect(third.status, JobStatus.queued);
    f.until(VehicleState.unloading);
    f.advance(TransportConfig.unloadingDuration);
    expect(second.status, JobStatus.completed);
    expect(f.vehicle.assignedJobId, third.id);
  });
  test('23 Kuyruk boşsa garaja dönüş yolu başlar', () {
    f.deliver();
    expect(f.vehicle.state, VehicleState.returning);
    expect(f.transport.remainingPath.last, f.vehicle.homePosition);
  });
  test('24 Garaja dönünce boşta olur', () {
    f.deliver();
    f.until(VehicleState.idle);
    expect(tileAt(f.vehicle.gridPosition), f.vehicle.homePosition);
    expect(f.vehicle.assignedJobId, isNull);
  });
  test('25 Kapasite aşılamaz', () {
    expect(() => f.vehicle.load(101), throwsArgumentError);
    expect(f.vehicle.capacityKg, 100);
    expect(f.vehicle.cargoKg, 0);
  });
  test('26 Kısmi yükleme kalan stoğu ve yenilenme engelini korur', () {
    f.dispose();
    f = LogisticsFixture(capacity: 10);
    f.load();
    expect(f.a.harvestedStockKg, 15);
    expect(f.vehicle.cargoKg, 10);
    expect(f.a.stageDuration, isNull);
    f.until(VehicleState.unloading);
    f.advance(TransportConfig.unloadingDuration);
    expect(f.center.receivedTeaKg, 10);
    expect(f.transport.totalTeaKg, 75);
    expect(f.transport.requestTransport(f.a), isNotNull);
    f.advance(const Duration(minutes: 1));
    expect(f.a.harvestedStockKg, 5);
    expect(f.center.receivedTeaKg, 20);
  });
  test('27 Tarlaya yol yoksa stok ve araç konumu korunur', () {
    f.transport.pathfinder = f.finder(extraBlocked: {(x: 1, y: 4)});
    final job = f.transport.requestTransport(f.a)!;
    expect(job.status, JobStatus.failed);
    expect(f.a.harvestedStockKg, 25);
    expect(f.vehicle.state, VehicleState.idle);
    expect(tileAt(f.vehicle.gridPosition), f.vehicle.homePosition);
    expect(job.failureMessage, 'Kamyon için uygun yol bulunamadı.');
  });
  test('28 Teslim yolunun kapanması kamyon yükünü silmez', () {
    f.transport.requestTransport(f.a);
    f.until(VehicleState.loading);
    f.transport.pathfinder = f.finder(extraBlocked: {(x: 8, y: 4)});
    f.advance(TransportConfig.loadingDuration);
    expect(f.vehicle.state, VehicleState.blocked);
    expect(f.vehicle.cargoKg, 25);
    expect(f.transport.currentJob!.status, JobStatus.failed);
    f.advance(const Duration(minutes: 1));
    expect(f.vehicle.cargoKg, 25);
    expect(f.center.receivedTeaKg, 0);
  });
  test('29 Yükleme atomiktir, dinleyicilerde bile toplam çay korunur', () {
    f.a.addListener(() => expect(f.transport.totalTeaKg, 75));
    f.vehicle.addListener(() => expect(f.transport.totalTeaKg, 75));
    f.load();
    expect(f.transport.totalTeaKg, 75);
  });
  test('30 Boşaltmada çay kütlesi korunur', () {
    f.center.addListener(() => expect(f.transport.totalTeaKg, 75));
    f.deliver();
    expect(f.transport.totalTeaKg, 75);
  });
  test(
    '31 İşçi ve kamyon aynı anda bağımsız ilerler, saat iki kez işlemez',
    () {
      f.b.removeHarvestedStock(25);
      f.advance(PlantationConfig.growthDuration);
      f.workers.requestHarvest(f.b);
      f.transport.requestTransport(f.a);
      final workerStart = f.worker.gridPosition;
      final truckStart = f.vehicle.gridPosition;
      final time = f.plantation.simulationTime;
      f.advance(const Duration(milliseconds: 100));
      expect(f.worker.gridPosition == workerStart, isFalse);
      expect(f.vehicle.gridPosition == truckStart, isFalse);
      expect(
        f.plantation.simulationTime,
        time + const Duration(milliseconds: 100),
      );
      f.advance(const Duration(seconds: 30));
      expect(f.b.harvestedStockKg, 25);
      expect(f.center.receivedTeaKg, 25);
    },
  );
  test('32 Ekonomi ve eski global envanter taşımadan etkilenmez', () {
    f.inventory.addFreshTea(7);
    final gold = f.economy.balance;
    f.deliver();
    expect(f.economy.balance, gold);
    expect(f.inventory.freshTeaKg, 7);
  });
  test('33 Gerçek haritadaki tüm yollar ve etkileşim noktaları bağlıdır', () {
    final game = CayGame(
      initialGold: 10000,
      guidedTutorial: false,
      mapMode: GameMapMode.devTest,
    );
    expect(game.transport.validateRoutes(), isEmpty);
    expect(game.vehiclePathfinder.walkable(game.vehicle.homePosition), isTrue);
    game.disposeState();
  });
  test('34 Bağlantı doğrulama kopuk yol için Türkçe tanı üretir', () {
    f.transport.pathfinder = f.finder(extraBlocked: {(x: 1, y: 4)});
    expect(
      f.transport.validateRoutes(),
      contains('Tarla field-0 için araç yolu bulunamadı.'),
    );
  });
  test(
    '35 Büyük adım ile küçük adımlar aynı sonucu ve yenilenme zamanını üretir',
    () {
      final other = LogisticsFixture();
      addTearDown(other.dispose);
      f.transport.requestTransport(f.a);
      other.transport.requestTransport(other.a);
      f.advance(const Duration(seconds: 12));
      for (var i = 0; i < 120; i++) {
        other.advance(const Duration(milliseconds: 100));
      }
      expect(f.a.toJson(), other.a.toJson());
      expect(f.center.receivedTeaKg, other.center.receivedTeaKg);
      expect(
        f.vehicle.gridPosition.x,
        closeTo(other.vehicle.gridPosition.x, 1e-5),
      );
      expect(f.vehicle.state, other.vehicle.state);
    },
  );
  test('36 Yol tekrar açılınca eldeki yük güvenle teslim edilir', () {
    f.transport.requestTransport(f.a);
    f.until(VehicleState.loading);
    f.transport.pathfinder = f.finder(extraBlocked: {(x: 8, y: 4)});
    f.advance(TransportConfig.loadingDuration);
    f.transport.pathfinder = f.finder();
    f.transport.retryRoute();
    f.advance(const Duration(seconds: 30));
    expect(f.center.receivedTeaKg, 25);
    expect(f.vehicle.cargoKg, 0);
    expect(f.transport.jobs.single.status, JobStatus.completed);
  });
  test('37 Araç ve teslimat modelleri JSON uyumludur', () {
    final job = f.load();
    expect(jsonDecode(jsonEncode(f.vehicle.toJson()))['cargoKg'], 25);
    expect(jsonDecode(jsonEncode(job.toJson()))['fieldId'], f.a.id);
    expect(jsonDecode(jsonEncode(f.center.toJson()))['receivedTeaKg'], 0);
  });
  test('38 Dönüş sırasında alınan emir kaybolmaz', () {
    f.deliver();
    final next = f.transport.requestTransport(f.b)!;
    expect(next.status, JobStatus.movingToSource);
    f.advance(const Duration(minutes: 1));
    expect(next.status, JobStatus.completed);
    expect(f.center.receivedTeaKg, 50);
  });
}
