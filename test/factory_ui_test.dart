import 'package:cay_simulasyonu/features/buildings/tea_factory.dart';
import 'package:cay_simulasyonu/features/transport/transport_vehicle.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fabrika sevkiyatı ve tek proses paneli canlı güncellenir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            initialGold: 10000,
            guidedTutorial: false,
            mapMode: GameMapMode.devTest,
          ),
        ),
      );
    });
    final game = tester
        .widget<GameWidget<CayGame>>(find.byType(GameWidget<CayGame>))
        .game!;
    await tester.runAsync(() async {
      await game.loaded;
      await game.ready();
    });
    await tester.pump();
    game.pauseEngine();
    Future<void> select(String id) async {
      final entity = game.entities.singleWhere((e) => e.definition.id == id);
      final point =
          (entity.visualBounds.center - game.navigation.center) *
              game.navigation.zoom +
          const Offset(640, 360);
      await tester.tapAt(point);
      await tester.pump();
      expect(game.selectedEntity.value, same(entity));
    }

    Future<void> advance(Duration time) async {
      game.simulation.advance(time);
      game.update(0);
      await tester.pump();
    }

    Future<void> until(VehicleState state) async {
      for (var i = 0; i < 100 && game.vehicle.state != state; i++) {
        await advance(
          game.transport.timeToNextEvent ?? const Duration(microseconds: 1),
        );
      }
      expect(game.vehicle.state, state);
    }

    await select('factory-01');
    expect(
      find.text('Üretim için 100 kg daha yaş çay gerekiyor.'),
      findsOneWidget,
    );
    expect(find.text('Üretimi Başlat'), findsNothing);
    for (var delivery = 1; delivery <= 2; delivery++) {
      game.collectionCenter.receive(50);
      await select('collection-01');
      await tester.tap(find.text('Fabrikaya Sevk Et'));
      await tester.pump();
      expect(find.text('Fabrikaya Sevk Et'), findsNothing);
      await until(VehicleState.loading);
      expect(find.text('Sevkiyat: Yükleniyor'), findsOneWidget);
      await select('truck-01');
      expect(
        find.text('Durum: Alım Yerinde yükleme yapılıyor'),
        findsOneWidget,
      );
      await advance(const Duration(seconds: 3));
      expect(find.text('Durum: Çay Fabrikasına gidiyor'), findsOneWidget);
      expect(find.text('Yük: 50 / 100 kg'), findsOneWidget);
      await select('factory-01');
      expect(find.text('Çay Fabrikası'), findsOneWidget);
      await until(VehicleState.unloading);
      await select('truck-01');
      expect(find.text('Durum: Teslimat yapılıyor'), findsOneWidget);
      await select('factory-01');
      await advance(const Duration(seconds: 2));
      expect(
        find.text('Yaş Çay Stoğu: ${(delivery - 1) * 50} kg'),
        findsOneWidget,
      );
      await advance(const Duration(seconds: 1));
      expect(find.text('Yaş Çay Stoğu: ${delivery * 50} kg'), findsOneWidget);
      if (delivery == 1) {
        expect(
          find.text('Üretim için 50 kg daha yaş çay gerekiyor.'),
          findsOneWidget,
        );
        expect(find.text('Üretimi Başlat'), findsNothing);
      }
      await until(VehicleState.idle);
    }
    expect(find.text('Durum: Üretime Hazır'), findsOneWidget);
    await tester.tap(find.text('Üretimi Başlat'));
    await tester.pump();
    expect(find.text('Durum: Üretim Yapılıyor'), findsOneWidget);
    expect(game.factory.processingInputKg, 100);
    expect(find.text('Yaş Çay Stoğu: 0 kg'), findsOneWidget);
    expect(find.text('Kuru Çay Stoğu: 0 kg'), findsOneWidget);
    expect(find.text('Üretimi Başlat'), findsNothing);
    await advance(const Duration(seconds: 6));
    expect(find.text('%60 • Kalan süre: 4 sn'), findsOneWidget);
    expect(game.factory.state, FactoryState.processing);
    await advance(const Duration(seconds: 4));
    expect(find.text('Durum: Bekliyor'), findsOneWidget);
    expect(find.text('Kuru Çay Stoğu: 20 kg'), findsOneWidget);
    expect(game.economy.balance, 10000);
    expect(game.inventory.freshTeaKg, 0);
    tester.view.physicalSize = const Size(740, 360);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
