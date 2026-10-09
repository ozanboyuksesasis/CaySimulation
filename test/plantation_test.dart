import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:convert';

import 'package:cay_simulasyonu/features/economy/economy_state.dart';
import 'package:cay_simulasyonu/features/economy/inventory_state.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_system.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EconomyState economy;
  late InventoryState inventory;
  late PlantationSystem system;
  late TeaField a;
  late TeaField b;
  late TeaField c;
  setUp(() {
    economy = EconomyState();
    inventory = InventoryState();
    TeaField field(String id) => TeaField(
      id: id,
      gridPosition: const GridPoint(2, 2),
      footprint: const Footprint(2, 2),
    );
    a = field('a');
    b = field('b');
    c = field('c');
    system = PlantationSystem(
      economy: economy,
      inventory: inventory,
      fields: [a, b, c],
    );
  });
  tearDown(() {
    system.dispose();
    economy.dispose();
    inventory.dispose();
  });
  void grow() {
    system.plant(a);
    system.advance(PlantationConfig.growthDuration);
  }

  test('Boş tarla yeterli altınla ekilir', () {
    expect(a.state, TeaFieldState.empty);
    expect(system.plant(a), PlantResult.planted);
    expect(a.state, TeaFieldState.planted);
    expect(a.plantedAt, Duration.zero);
  });
  test('Dikim tam 250 altın düşer', () {
    system.plant(a);
    expect(economy.balance, 9750);
    expect(inventory.freshTeaKg, 0);
  });
  test('Yetersiz altın durumunda para ve tarla değişmez', () {
    economy.spend(9751);
    expect(system.plant(a), PlantResult.insufficientGold);
    expect(economy.balance, 249);
    expect(a.state, TeaFieldState.empty);
    expect(a.plantedAt, isNull);
  });
  test('Ekildi aşaması tam 5 saniyede ilk büyümeye geçer', () {
    system.plant(a);
    system.advance(const Duration(milliseconds: 4999));
    expect(a.state, TeaFieldState.planted);
    expect(a.remainingSeconds, 1);
    system.advance(const Duration(milliseconds: 1));
    expect(a.state, TeaFieldState.growing1);
    expect(a.stateStartedAt, const Duration(seconds: 5));
  });
  test('Yapılandırılan aşama sürelerinde hasada hazır olur', () {
    system.plant(a);
    system.advance(const Duration(seconds: 10));
    expect(a.state, TeaFieldState.growing2);
    expect(a.remainingSeconds, PlantationConfig.growing2Duration.inSeconds);
    system.advance(
      PlantationConfig.growing2Duration - const Duration(seconds: 1),
    );
    expect(a.state, TeaFieldState.growing2);
    system.advance(const Duration(seconds: 1));
    expect(a.state, TeaFieldState.ready);
    expect(a.progress, 1);
  });
  test('Hazır tarlanın ürünü tam 25 kilogramdır', () {
    grow();
    expect(a.yieldAmount, 25);
    expect(a.completeHarvest(system.simulationTime), isTrue);
    expect(a.harvestedStockKg, 25);
    expect(inventory.freshTeaKg, 0);
  });
  test('Tamamlanan hasat tarla stoğuna eklenir; global envanter değişmez', () {
    inventory.addFreshTea(10);
    grow();
    a.completeHarvest(system.simulationTime);
    expect(inventory.freshTeaKg, 10);
    expect(a.harvestedStockKg, 25);
    expect(economy.balance, 9750);
  });
  test('Hasat hazır durumu hasat edildiye çevirir', () {
    grow();
    a.completeHarvest(system.simulationTime);
    expect(a.state, TeaFieldState.harvested);
    expect(a.harvestCount, 1);
    expect(a.stageDuration, isNull);
  });
  test('Üç tarla bağımsız durum, ilerleme ve hasat sayısı tutar', () {
    system.plant(a);
    system.advance(
      PlantationConfig.growthDuration - const Duration(seconds: 8),
    );
    system.plant(b);
    system.advance(const Duration(seconds: 8));
    expect(a.state, TeaFieldState.ready);
    expect(b.state, TeaFieldState.growing1);
    expect(c.state, TeaFieldState.empty);
    expect(b.progress, closeTo(0.6, 0.001));
    a.completeHarvest(system.simulationTime);
    expect(a.harvestCount, 1);
    expect(b.harvestCount, 0);
    expect(c.harvestCount, 0);
    expect(
      b.plantedAt,
      PlantationConfig.growthDuration - const Duration(seconds: 8),
    );
  });
  test('Ekonomi tek kaynaktır; dışarıdan bakiye değişimi dikimde görülür', () {
    expect(identical(system.economy, economy), isTrue);
    economy.spend(10000);
    expect(system.plant(a), PlantResult.insufficientGold);
    economy.earn(250);
    expect(system.plant(a), PlantResult.planted);
    expect(economy.balance, 0);
  });
  test('Tekrar dikim ve çift hasat ikinci işlem oluşturmaz', () {
    expect(a.completeHarvest(system.simulationTime), isFalse);
    grow();
    expect(system.plant(a), PlantResult.invalidState);
    a.completeHarvest(system.simulationTime);
    expect(a.completeHarvest(system.simulationTime), isFalse);
    expect(a.harvestCount, 1);
    expect(a.harvestedStockKg, 25);
    expect(inventory.freshTeaKg, 0);
    expect(economy.balance, 9750);
  });
  test('Tarla stoğu boşaltıldıktan 5 saniye sonra ücretsiz yeniden büyür', () {
    grow();
    a.completeHarvest(system.simulationTime);
    a.removeHarvestedStock(25);
    system.advance(const Duration(seconds: 5));
    expect(a.state, TeaFieldState.growing1);
    system.advance(
      PlantationConfig.growing1Duration + PlantationConfig.growing2Duration,
    );
    expect(a.state, TeaFieldState.ready);
    a.completeHarvest(system.simulationTime);
    expect(a.harvestCount, 2);
    expect(a.harvestedStockKg, 25);
    expect(inventory.freshTeaKg, 0);
    expect(economy.balance, 9750);
  });
  test(
    'Uzun kare aşamaları atlamadan zamanı taşır; kendiliğinden hasat yapmaz',
    () {
      system.plant(a);
      system.advance(const Duration(hours: 1));
      expect(a.state, TeaFieldState.ready);
      expect(a.stateStartedAt, PlantationConfig.growthDuration);
      expect(inventory.freshTeaKg, 0);
      expect(a.harvestCount, 0);
      expect(c.state, TeaFieldState.empty);
    },
  );
  test('Durum görüntüsü JSON verisidir ve geri giden zaman reddedilir', () {
    grow();
    a.completeHarvest(system.simulationTime);
    final data = jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>;
    expect(data['state'], 'harvested');
    expect(data['harvestCount'], 1);
    expect(
      data['stateStartedAtMicros'],
      PlantationConfig.growthDuration.inMicroseconds,
    );
    expect(
      () => system.advance(const Duration(seconds: -1)),
      throwsArgumentError,
    );
    expect(() => a.advanceTo(Duration.zero), throwsArgumentError);
  });
}
