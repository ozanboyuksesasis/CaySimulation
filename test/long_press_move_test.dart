import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/builder/builder_system.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';

void main() {
  testWidgets(
    'Gerçek dokunma: seç, pan, uzun bas, sürükle, vazgeç ve stokla taşı',
    (tester) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: GameScreen(initialGold: 10000, guidedTutorial: false),
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
      game.pauseEngine();
      game.builder.choose(catalogItem('field'));
      game.builder.preview(const GridPoint(5, 5));
      expect(game.builder.confirm(), isTrue);
      await tester.runAsync(() async {
        await game.ready();
      });
      game.update(0);
      await tester.pump();
      final field = game.plantation.fields.single;
      field.plant(Duration.zero);
      field.advanceTo(PlantationConfig.growthDuration);
      field.completeHarvest(PlantationConfig.growthDuration);
      final entity = game.entities.singleWhere(
        (e) => e.definition.id == field.id,
      );
      Offset screen() =>
          (entity.visualBounds.center - game.navigation.center) *
              game.navigation.zoom +
          const Offset(480, 270);
      await tester.tapAt(screen());
      await tester.pump();
      expect(game.selectedEntity.value, same(entity));
      expect(game.builder.mode, BuilderMode.inactive);
      final camera = game.navigation.center;
      await tester.dragFrom(screen(), const Offset(70, 20));
      await tester.pump(const Duration(milliseconds: 500));
      expect(game.builder.mode, BuilderMode.inactive);
      expect(game.navigation.center, isNot(camera));
      game.navigation.reset();
      final before = field.toJson();
      final gold = game.economy.balance;
      final finger = await tester.startGesture(screen());
      await tester.pump(const Duration(milliseconds: 451));
      expect(game.builder.mode, BuilderMode.movingExisting);
      expect(entity.previewHidden, isTrue);
      await finger.moveBy(const Offset(35, -30));
      await tester.pump();
      await finger.up();
      await tester.pump();
      expect(game.builder.mode, BuilderMode.movingExisting);
      expect(field.toJson(), before);
      await tester.tap(find.text('Vazgeç'));
      await tester.pump();
      expect(field.toJson(), before);
      expect(entity.previewHidden, isFalse);
      final second = await tester.startGesture(screen());
      await tester.pump(const Duration(milliseconds: 451));
      final delta =
          (game.grid.toWorld(const GridPoint(4.1, 3.1)) -
              game.grid.toWorld(const GridPoint(5, 5))) *
          game.navigation.zoom;
      await second.moveBy(delta);
      await tester.pump();
      await second.up();
      await tester.pump();
      expect(game.builder.validationResult.valid, isTrue);
      expect([field.gridPosition.x, field.gridPosition.y], [5, 5]);
      await tester.tap(find.text('Onayla'));
      await tester.pump();
      expect([field.gridPosition.x, field.gridPosition.y], [4, 3]);
      expect(field.harvestedStockKg, 25);
      expect(field.harvestCount, 1);
      expect(game.economy.balance, gold);
      expect(game.builder.mode, BuilderMode.inactive);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
