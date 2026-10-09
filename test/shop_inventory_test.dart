import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/builder/builder_system.dart';
import 'package:cay_simulasyonu/features/economy/player_inventory.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/ui/game_navigation.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';

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
    expect(g.shop.buy(id).success, isTrue);
    g.builder.choose(catalogItem(id), fromInventory: true);
    g.builder.preview(GridPoint(x, y));
    expect(g.builder.confirm(), isTrue);
  }

  TeaField harvest() {
    g.workforce.hire('turhan');
    g.workforce.buyEquipment(EquipmentType.teaShears);
    g.workforce.equip(g.worker, EquipmentType.teaShears);
    place('field', 5, 5);
    final field = g.plantation.fields.single;
    g.plantation.plant(field);
    g.simulation.advance(PlantationConfig.growthDuration);
    g.jobs.requestHarvest(field);
    g.simulation.advance(const Duration(seconds: 20));
    return field;
  }

  void stocks() {
    harvest();
    place('collection_center', 9, 4);
    place('factory', 9, 8);
    g.vehicle.load(10);
    g.collectionCenter.receive(30);
    g.factory.receiveRawTea(150);
    g.factory.startProduction();
    g.simulation.advance(const Duration(seconds: 10));
  }

  test('01 Satın alma tam 500 Altın harcar', () {
    expect(g.shop.buy('field').success, isTrue);
    expect(g.economy.balance, 9500);
  });
  test('02 Satın alınan tarla envantere girer', () {
    g.shop.buy('field');
    expect(g.playerInventory.quantity('field'), 1);
  });
  test('03 Satın alma dünyaya nesne eklemez veya yerleştirme açmaz', () {
    g.shop.buy('field');
    expect(g.plantation.fields, isEmpty);
    expect(g.settlement.structures.length, 1);
    expect(g.builder.mode, BuilderMode.inactive);
  });
  test('04 Yetersiz altın satın almayı engeller', () {
    g.economy.spend(9600);
    final r = g.shop.buy('field');
    expect(r.success, isFalse);
    expect(r.message, 'Yeterli altının yok.');
    expect(g.economy.balance, 400);
  });
  test('05 Başarısız satın alma envanteri değiştirmez', () {
    g.economy.spend(10000);
    g.shop.buy('field');
    expect(g.playerInventory.placeables, isEmpty);
  });
  test('06 Tekil satın alma envanterdeki sahipliği de sayar', () {
    g.progression.award('factory-fixture-unlock', 100);
    g.shop.buy('factory');
    expect(g.shop.buy('factory').success, isFalse);
    expect(g.playerInventory.quantity('factory'), 1);
    expect(g.economy.balance, 6000);
  });
  test('07 Alım yeri önce envantere girer', () {
    g.shop.buy('collection_center');
    expect(g.playerInventory.quantity('collection_center'), 1);
    expect(g.activeCollectionCenter, isNull);
  });
  test('08 Fabrika önce envantere girer', () {
    g.progression.award('factory-fixture-unlock', 100);
    g.shop.buy('factory');
    expect(g.playerInventory.quantity('factory'), 1);
    expect(g.activeFactory, isNull);
  });
  test('09 Yerleştirme yalnız bir adet tüketir', () {
    g.shop.buy('field');
    place('field', 5, 5);
    expect(g.playerInventory.quantity('field'), 1);
  });
  test('10 İptal envanteri tüketmez ve para iadesi yapmaz', () {
    g.shop.buy('field');
    g.builder.choose(catalogItem('field'));
    g.builder.cancel();
    expect(g.playerInventory.quantity('field'), 1);
    expect(g.economy.balance, 9500);
  });
  test('11 Yerleştirme ikinci kez Altın harcamaz', () {
    g.shop.buy('field');
    g.economy.spend(9500);
    g.builder.choose(catalogItem('field'), fromInventory: true);
    g.builder.preview(const GridPoint(5, 5));
    expect(g.builder.confirm(), isTrue);
    expect(g.economy.balance, 0);
  });
  test('12 Envanter negatif olamaz', () {
    expect(g.playerInventory.takePlaceable('field'), isFalse);
    g.playerInventory.addPlaceable('field');
    expect(g.playerInventory.takePlaceable('field', 2), isFalse);
    expect(g.playerInventory.quantity('field'), 1);
    expect(
      () => g.playerInventory.addPlaceable('field', -1),
      throwsArgumentError,
    );
    expect(
      () => g.playerInventory.takePlaceable('field', 0),
      throwsArgumentError,
    );
  });
  test('13 Mağaza ve yerleştirme aynı katalog tanımını kullanır', () {
    final item = g.shop.catalog.first;
    g.shop.buy(item.id);
    g.builder.choose(item);
    expect(g.builder.selectedCatalogItem, same(catalogItem(item.id)));
  });
  test(
    '14 Yeni oyunun yerleştirilebilir envanteri boştur',
    () => expect(g.playerInventory.placeables, isEmpty),
  );
  test(
    '15 Yeni oyunda 10000 Altın vardır',
    () => expect(g.economy.balance, 10000),
  );
  test(
    '16 Başlangıçta yalnız ev yerleşiktir',
    () =>
        expect(g.settlement.structures.single.item.buildType, BuildType.house),
  );
  for (final panel in [
    GamePanel.shop,
    GamePanel.inventory,
    GamePanel.business,
  ]) {
    test('Panel açılır: ${panel.name}', () {
      g.panels.open(panel);
      expect(g.panels.panel, panel);
    });
  }
  test('20 Tek ana panel ve yerleştirme birbirini dışlar', () {
    g.panels.open(GamePanel.shop);
    g.panels.open(GamePanel.inventory);
    expect(g.panels.panel, GamePanel.inventory);
    g.shop.buy('field');
    g.builder.choose(catalogItem('field'));
    expect(g.panels.panel, GamePanel.none);
    g.panels.open(GamePanel.business);
    expect(g.builder.mode, BuilderMode.inactive);
  });
  test('21 Kaynak özeti tarla stoklarını toplar', () {
    stocks();
    expect(g.resources.fieldsKg, 25);
  });
  test('22 Kaynak özeti kamyon yükünü okur', () {
    stocks();
    expect(g.resources.cargoKg, 10);
  });
  test('23 Kaynak özeti alım yeri stoğunu okur', () {
    stocks();
    expect(g.resources.collectionKg, 30);
  });
  test('24 Kaynak özeti fabrika yaş stokunu okur', () {
    stocks();
    expect(g.resources.factoryRawKg, 50);
  });
  test('25 Kuru çay özeti fabrika çıktısını okur', () {
    stocks();
    expect(g.resources.dryKg, 20);
  });
  test('26 Özet tekrar okumak stokları değiştirmez veya global envantere çay eklemez', () {
    stocks();
    final before = g.transport.totalRawTeaKg;
    for (var i = 0; i < 10; i++) {
      expect(g.resources.totalFreshKg, 115);
      expect(g.resources.dryKg, 20);
    }
    expect(g.transport.totalRawTeaKg, before);
    expect(g.playerInventory.resourceQuantity(GlobalResource.freshTea), 0);
    expect(g.playerInventory.resourceQuantity(GlobalResource.dryTea), 0);
    expect(g.inventory.freshTeaKg, 0);
  });
  test('27 Envanterden yerleşen tarla büyür', () {
    place('field', 5, 5);
    final f = g.plantation.fields.single;
    g.plantation.plant(f);
    g.simulation.advance(PlantationConfig.growthDuration);
    expect(f.state, TeaFieldState.ready);
  });
  test(
    '28 Envanterden yerleşen tarla Mehmet ile hasat edilir',
    () => expect(harvest().harvestedStockKg, 25),
  );
  test('29 Envanterden alım yeri gerçek nakliye hedefidir', () {
    final f = harvest();
    place('collection_center', 9, 4);
    g.transport.requestTransport(f);
    g.simulation.advance(const Duration(minutes: 1));
    expect(g.collectionCenter.receivedTeaKg, 25);
  });
  test('30 Envanterden fabrika gerçek sevkiyat ve üretim yapar', () {
    place('collection_center', 9, 4);
    place('factory', 9, 8);
    g.collectionCenter.receive(100);
    g.transport.requestFactoryShipment();
    g.simulation.advance(const Duration(minutes: 1));
    expect(g.factory.startProduction(), isTrue);
    g.simulation.advance(const Duration(seconds: 10));
    expect(g.factory.dryTeaKg, 20);
  });
  test('31 Taşıma stokları ve envanteri korur', () {
    final f = harvest();
    final gold = g.economy.balance;
    g.builder.startMove(f.id);
    g.builder.preview(const GridPoint(2, 2));
    expect(g.builder.confirm(), isTrue);
    expect(f.harvestedStockKg, 25);
    expect(g.economy.balance, gold);
    expect(g.playerInventory.placeables, isEmpty);
  });
  test('32 Yol da satın alınan stoktan tekrarlı yerleştirilir', () {
    g.shop.buy('road');
    place('road', 13, 7);
    final gold = g.economy.balance;
    g.builder.preview(const GridPoint(14, 7));
    expect(g.builder.confirm(), isTrue);
    g.builder.preview(const GridPoint(15, 7));
    expect(g.builder.confirm(), isFalse);
    expect(g.vehiclePathfinder.walkable((x: 14, y: 7)), isTrue);
    expect(g.economy.balance, gold);
  });
  test('33 Yerleşmiş tekil bina yeniden satın alınamaz', () {
    place('collection_center', 9, 4);
    final gold = g.economy.balance;
    expect(g.shop.buy('collection_center').success, isFalse);
    expect(g.economy.balance, gold);
  });
  test('34 Geçersiz yerleştirme satın alınmış öğeyi korur', () {
    g.shop.buy('field');
    g.builder.choose(catalogItem('field'));
    g.builder.preview(const GridPoint(3, 9));
    expect(g.builder.confirm(), isFalse);
    expect(g.playerInventory.quantity('field'), 1);
    expect(g.economy.balance, 9500);
  });
  test('35 Üretime ayrılmış yaş çay özette kaybolmaz', () {
    place('factory', 9, 8);
    g.factory.receiveRawTea(100);
    g.factory.startProduction();
    expect(g.resources.processingKg, 100);
    expect(g.resources.totalFreshKg, 100);
    g.simulation.advance(const Duration(seconds: 10));
    expect(g.resources.totalFreshKg, 0);
    expect(g.resources.dryKg, 20);
  });
  test('36 Envantere ekleme satın almaya bağlı değildir ve JSON uyumludur', () {
    g.playerInventory.addPlaceable('field', 2);
    expect(
      jsonDecode(jsonEncode(g.playerInventory.toJson()))['placeables']['field'],
      2,
    );
    expect(g.economy.balance, 10000);
  });
  test('37 Satın alma ve panel olayları eğitim için yayınlanır', () {
    final purchases = <String>[];
    final panels = <GamePanel>[];
    final a = g.shop.purchases.listen(purchases.add);
    final b = g.panels.opened.listen(panels.add);
    addTearDown(a.cancel);
    addTearDown(b.cancel);
    g.panels.open(GamePanel.shop);
    g.shop.buy('field');
    g.panels.open(GamePanel.inventory);
    expect(purchases, ['field']);
    expect(panels, [GamePanel.shop, GamePanel.inventory]);
  });
  test('38 Katalog dışı satın alma para harcamaz', () {
    expect(g.shop.buy('unknown').success, isFalse);
    expect(g.economy.balance, 10000);
  });
}
