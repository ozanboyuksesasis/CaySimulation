import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/builder/builder_system.dart';
import 'package:cay_simulasyonu/features/builder/settlement.dart';
import 'package:cay_simulasyonu/features/buildings/factory_config.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/transport/transport_job.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/ui/game_navigation.dart';

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
  PlacedStructure place(String type, double x, double y) {
    while (g.progression.level < catalogItem(type).requiredLevel) {
      g.progression.award(
        "fixture-unlock-${g.progression.level}",
        g.progression.xpForNextLevel - g.progression.currentXp,
      );
    }
    g.builder.choose(catalogItem(type));
    g.builder.preview(GridPoint(x, y));
    expect(g.builder.confirm(), isTrue, reason: g.builder.feedback);
    return g.settlement.structures.last;
  }

  void move(String id, double x, double y) {
    expect(g.builder.startMove(id), isTrue);
    g.builder.preview(GridPoint(x, y));
    expect(g.builder.confirm(), isTrue, reason: g.builder.feedback);
  }

  TeaField field() {
    place('field', 5, 5);
    return g.plantation.fields.last;
  }

  void hire() {
    if (g.workforce.workers.isNotEmpty) return;
    expect(g.workforce.hire('turhan').success, isTrue);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isTrue);
    expect(
      g.workforce.equip(g.worker, EquipmentType.teaShears).success,
      isTrue,
    );
  }

  TeaField harvest() {
    hire();
    final f = field();
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.jobs.requestHarvest(f);
    g.simulation.advance(const Duration(seconds: 20));
    return f;
  }

  bool tryPlace(String type, double x, double y) {
    g.builder.choose(catalogItem(type));
    g.builder.preview(GridPoint(x, y));
    return g.builder.confirm();
  }

  test(
    '01 Katalog gerçek çay tarlasını içerir',
    () => expect(catalogItem('field').buildType, BuildType.field),
  );
  test(
    '02 Katalog alım yerini içerir',
    () => expect(
      catalogItem('collection_center').buildType,
      BuildType.collectionCenter,
    ),
  );
  test(
    '03 Katalog fabrikayı içerir',
    () => expect(catalogItem('factory').buildType, BuildType.factory),
  );
  test('04 Tarla bedeli 500', () => expect(catalogItem('field').goldCost, 500));
  test(
    '05 Alım yeri bedeli 2500',
    () => expect(catalogItem('collection_center').goldCost, 2500),
  );
  test(
    '06 Fabrika bedeli 4000',
    () => expect(catalogItem('factory').goldCost, 4000),
  );
  test(
    '07 Yol bedeli karo başına 25',
    () => expect(catalogItem('road').goldCost, 25),
  );
  test('08 Harita dışına yerleştirme reddedilir', () {
    expect(tryPlace('field', 19, 19), isFalse);
    expect(g.builder.feedback, 'Harita sınırının dışında.');
  });
  test('09 Ev veya başka tarla üzerine yerleştirilemez', () {
    expect(tryPlace('field', 3, 9), isFalse);
    expect(g.builder.feedback, 'Başka bir yapıyla çakışıyor.');
    field();
    expect(tryPlace('field', 5, 5), isFalse);
  });
  test('10 Geçerli yerleştirme gerçek dünya nesnesi oluşturur', () {
    final object = place('field', 5, 5);
    expect(g.settlement.byId(object.id), same(object));
    expect(g.builder.mode, BuilderMode.inactive);
  });
  test('11 Satın alma ve yerleştirme toplam tam bedel düşer', () {
    field();
    expect(g.economy.balance, 9500);
  });
  test('12 Geçersiz konum altını değiştirmez', () {
    tryPlace('field', -1, 0);
    expect(g.economy.balance, 10000);
  });
  test('13 Yetersiz altın nesne oluşturmaz', () {
    g.economy.spend(9600);
    expect(tryPlace('field', 5, 5), isFalse);
    expect(g.builder.feedback, 'Yeterli altının yok.');
    expect(g.economy.balance, 400);
    expect(g.plantation.fields, isEmpty);
  });
  test('14 Yeni tarla PlantationSystem içine kaydolur', () {
    final f = field();
    expect(f.id, 'field_001');
  });
  test('15 Yeni tarla bağımsız büyür', () {
    final f = field();
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(f.state, TeaFieldState.ready);
  });
  test('16 Yeni tarla mevcut hasat işini destekler', () {
    final f = harvest();
    expect(f.harvestedStockKg, 25);
    expect(g.jobs.jobs.single.status, JobStatus.completed);
  });
  test('17 Yeni alım yeri gerçek nakliye hedefidir', () {
    final f = harvest();
    final center = place('collection_center', 9, 4);
    final job = g.transport.requestTransport(f)!;
    expect(job.destinationId, center.id);
    g.simulation.advance(const Duration(minutes: 1));
    expect(g.collectionCenter.receivedTeaKg, 25);
  });
  test('18 Yeni fabrika mevcut sevkiyat hedefidir', () {
    place('collection_center', 9, 4);
    final factory = place('factory', 9, 8);
    g.collectionCenter.receive(100);
    final job = g.transport.requestFactoryShipment()!;
    expect(job.destinationId, factory.id);
    g.simulation.advance(const Duration(minutes: 1));
    expect(g.factory.rawTeaKg, 100);
  });
  test('19 Yeni yol araç tarafından hemen kullanılabilir', () {
    expect(g.vehiclePathfinder.walkable((x: 13, y: 7)), isFalse);
    place('road', 13, 7);
    expect(g.vehiclePathfinder.walkable((x: 13, y: 7)), isTrue);
    expect(g.builder.mode, BuilderMode.placingRoad);
  });
  test('20 Yapı footprinti iki yol bulucuda da engel olur', () {
    field();
    expect(g.pathfinder.walkable((x: 5, y: 5)), isFalse);
    expect(g.vehiclePathfinder.blocked, contains((x: 5, y: 5)));
  });
  test('21 Taşıma eski doluluğu bırakır', () {
    final f = field();
    move(f.id, 2, 2);
    expect(g.settlement.occupancy.containsKey((x: 5, y: 5)), isFalse);
    expect(g.pathfinder.walkable((x: 5, y: 5)), isTrue);
  });
  test('22 Taşıma yeni footprinti doldurur', () {
    final f = field();
    move(f.id, 2, 2);
    expect(g.settlement.occupancy[(x: 3, y: 3)], f.id);
  });
  test('23 Taşıma ücretsizdir', () {
    final f = field();
    final gold = g.economy.balance;
    move(f.id, 2, 2);
    expect(g.economy.balance, gold);
  });
  test('24 Vazgeçmek konumu ve gerçek doluluğu korur', () {
    final f = field();
    final position = f.gridPosition;
    final occupancy = g.settlement.occupancy;
    g.builder.startMove(f.id);
    g.builder.preview(const GridPoint(2, 2));
    g.builder.cancel();
    expect(f.gridPosition, position);
    expect(g.settlement.occupancy, occupancy);
  });
  test('25 Taşımadan vazgeçmek tüm tarla durumunu korur', () {
    final f = harvest();
    final before = f.toJson();
    g.builder.startMove(f.id);
    g.builder.preview(const GridPoint(2, 2));
    g.builder.cancel();
    expect(f.toJson(), before);
  });
  test('26 Taşıma tarla stoğunu ve hasat sayısını korur', () {
    final f = harvest();
    move(f.id, 2, 2);
    expect(g.plantation.fields.single, same(f));
    expect(f.harvestedStockKg, 25);
    expect(f.harvestCount, 1);
    expect(f.state, TeaFieldState.harvested);
  });
  test('27 Alım yeri taşınırken stoğu ve kimliği korunur', () {
    final s = place('collection_center', 9, 4);
    final model = g.collectionCenter;
    model.receive(37);
    final oldAccess = model.deliveryInteractionTile;
    move(s.id, 9, 8);
    expect(g.collectionCenter, same(model));
    expect(model.receivedTeaKg, 37);
    expect(model.deliveryInteractionTile, isNot(oldAccess));
  });
  test('28 Fabrika taşınırken ham ve kuru çay korunur', () {
    final s = place('factory', 9, 8);
    final model = g.factory;
    model.receiveRawTea(250);
    model.startProduction();
    g.simulation.advance(FactoryConfig.productionDuration);
    place('road', 13, 7);
    move(s.id, 13, 8);
    expect(g.factory, same(model));
    expect(model.rawTeaKg, 150);
    expect(model.dryTeaKg, 20);
  });
  test('29 İşçisi yürüyen veya hasat yapan tarla taşınamaz', () {
    hire();
    final f = field();
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.jobs.requestHarvest(f);
    expect(g.builder.startMove(f.id), isFalse);
    expect(g.builder.feedback, 'Bu nesne şu anda taşınamaz.');
  });
  test('30 Üretim yapan fabrika taşınamaz', () {
    final s = place('factory', 9, 8);
    g.factory.receiveRawTea(100);
    g.factory.startProduction();
    expect(g.builder.startMove(s.id), isFalse);
  });
  test('31 Aktif teslimat hedefi taşınamaz', () {
    final f = harvest();
    final s = place('collection_center', 9, 4);
    g.transport.requestTransport(f);
    expect(g.builder.startMove(s.id), isFalse);
    expect(g.builder.startMove(f.id), isFalse);
  });
  test('32 Yeni oyunda test tarlaları ve işletmeler yoktur', () {
    expect(g.plantation.fields, isEmpty);
    expect(g.settlement.structures.length, 1);
    expect(g.activeCollectionCenter, isNull);
    expect(g.activeFactory, isNull);
  });
  test(
    '33 Yeni oyun 10000 altınla başlar',
    () => expect(g.economy.balance, 10000),
  );
  test(
    '34 Yeni oyunda çiftlik evi vardır',
    () =>
        expect(g.settlement.structures.single.item.buildType, BuildType.house),
  );
  test('35 Yeni oyunda ücretsiz işçi yok; işe alınan Turhan boşta başlar', () {
    expect(g.workforce.workers, isEmpty);
    hire();
    expect(g.worker.name, 'Turhan');
    expect(g.worker.state, WorkerState.idle);
  });
  test('36 Alım yeri yokken nakliye emri verilemez', () {
    final f = harvest();
    expect(g.transport.requestTransport(f), isNull);
  });
  test('37 Alım yeri yapmak nakliye hedefini açar', () {
    expect(g.transport.hasCollectionCenter, isFalse);
    place('collection_center', 9, 4);
    expect(g.transport.hasCollectionCenter, isTrue);
  });
  test('38 Fabrika yokken sevkiyat oluşturulmaz', () {
    place('collection_center', 9, 4);
    g.collectionCenter.receive(100);
    expect(g.transport.requestFactoryShipment(), isNull);
  });
  test('39 Fabrika kurmak sevkiyat ve üretimi açar', () {
    place('collection_center', 9, 4);
    place('factory', 9, 8);
    g.collectionCenter.receive(100);
    expect(g.transport.requestFactoryShipment(), isNotNull);
    g.simulation.advance(const Duration(minutes: 1));
    expect(g.factory.startProduction(), isTrue);
    g.simulation.advance(FactoryConfig.productionDuration);
    expect(g.factory.dryTeaKg, 20);
  });
  test('40 Test haritası ayrı modda korunur', () {
    final dev = CayGame(
      initialGold: 10000,
      guidedTutorial: false,
      mapMode: GameMapMode.devTest,
    );
    addTearDown(dev.disposeState);
    expect(dev.plantation.fields.length, 3);
    expect(dev.collectionCenter.id, 'collection-01');
    expect(dev.factory.id, 'factory-01');
    expect(dev.transport.validateRoutes(), isEmpty);
  });
  test('41 Yol erişimi olmayan işletme kurulamaz', () {
    expect(tryPlace('collection_center', 15, 1), isFalse);
    expect(g.builder.feedback, 'Yol bağlantısı gerekli.');
    expect(g.economy.balance, 10000);
  });
  test('42 Tekil işletme sınırına uyulur', () {
    place('collection_center', 9, 4);
    expect(tryPlace('collection_center', 9, 8), isFalse);
    expect(g.builder.feedback, 'Bu yapıdan daha fazla yapılamaz.');
  });
  test('43 Yol tekrarlı yerleştirilir, aynı karoya yeniden para alınmaz', () {
    place('road', 13, 7);
    g.builder.preview(const GridPoint(14, 7));
    expect(g.builder.confirm(), isTrue);
    expect(g.builder.confirm(), isFalse);
    expect(g.economy.balance, 9950);
    g.builder.cancel();
    expect(g.builder.mode, BuilderMode.inactive);
  });
  test('44 Mevcut nesne kendi alanını taşıma doğrulamasında engellemez', () {
    final f = field();
    g.builder.startMove(f.id);
    expect(g.builder.validationResult.valid, isTrue);
    expect(g.builder.confirm(), isTrue);
    expect(g.economy.balance, 9500);
  });
  test('45 Onay anında yeniden doğrulama ve meşgul kontrolü yapılır', () {
    hire();
    final f = field();
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.builder.startMove(f.id);
    g.builder.preview(const GridPoint(2, 2));
    g.jobs.requestHarvest(f);
    expect(g.builder.confirm(), isFalse);
    expect(f.gridPosition.x, 5);
  });
  test('46 Çalışan işçinin rotasına yapı konulamaz', () {
    hire();
    final f = field();
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.jobs.requestHarvest(f);
    final tile = g.jobs.remainingPath.last;
    expect(tryPlace('well', tile.x.toDouble(), tile.y.toDouble()), isFalse);
  });
  test('47 Sonradan yapılan yol eski tarlanın nakliye erişimini açar', () {
    final s = place('field', 1, 5);
    expect(g.transport.pickups[s.id], isNull);
    place('road', 3, 7);
    place('road', 2, 7);
    expect(g.transport.pickups[s.id], isNotNull);
  });
  test('48 Kimlikler benzersiz ve durumlar JSON uyumludur', () {
    final a = place('field', 1, 1);
    final b = place('field', 4, 1);
    expect([a.id, b.id], ['field_001', 'field_002']);
    expect(jsonDecode(jsonEncode(b.toJson()))['type'], 'field');
  });
  test('49 Eğitim kancaları gerçek başarılı yerleştirmede olay üretir', () {
    final events = <BuildingEvent>[];
    final subscription = g.builder.events.listen(events.add);
    addTearDown(subscription.cancel);
    place('field', 5, 5);
    expect(events.map((e) => e.type), [
      BuildingEventType.buildingPlaced,
      BuildingEventType.fieldPlaced,
    ]);
  });
  test('50 Seçim ve iptal para harcamaz, görünüm nesnesi içermez', () {
    g.panels.open(GamePanel.inventory);
    g.builder.choose(catalogItem('field'));
    expect(g.economy.balance, 10000);
    g.builder.cancel();
    expect(g.plantation.fields, isEmpty);
    expect(g.economy.balance, 10000);
  });
}
