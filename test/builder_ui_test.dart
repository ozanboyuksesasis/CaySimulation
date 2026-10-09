import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:cay_simulasyonu/features/builder/builder_system.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';

void main() {
  testWidgets(
    'Yeni oyun menü, önizleme, satın alma, taşıma, yol ve kamera akışı',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
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
      await tester.pump();
      game.pauseEngine();
      Future<void> settleWorld() async {
        await tester.runAsync(() async {
          await game.ready();
        });
        game.update(0);
        await tester.pump();
      }

      Future<void> tapTile(double x, double y) async {
        final world = game.grid.toWorld(GridPoint(x + 0.2, y + 0.2));
        final screen =
            (world - game.navigation.center) * game.navigation.zoom +
            const Offset(640, 360);
        await tester.tapAt(screen);
        await tester.pump();
      }

      Future<void> choose(String id, [String category = 'Tarım']) async {
        await tester.tap(find.byKey(const ValueKey('nav-inventory')));
        await tester.pump();
        await tester.tap(find.text(category));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey('acquire-$id')));
        await tester.pump();
      }

      expect(game.mapMode, GameMapMode.newGame);
      expect(game.entities.length, 1);
      expect(find.text('Altın: 10.000'), findsOneWidget);
      await choose('field');
      expect(game.economy.balance, 10000);
      await tapTile(3, 9);
      expect(game.builder.validationResult.valid, isFalse);
      expect(find.text('Başka bir yapıyla çakışıyor.'), findsOneWidget);
      await tester.tap(find.text('Yerleştir'));
      await tester.pump();
      expect(game.economy.balance, 10000);
      await tapTile(5, 5);
      expect(game.builder.validationResult.valid, isTrue);
      final pinned = game.builder.previewGridPosition;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 200));
      await mouse.moveTo(const Offset(720, 530));
      await tester.pump();
      expect(game.builder.previewGridPosition, pinned);
      await mouse.removePointer();
      await tester.tap(find.text('Yerleştir'));
      await settleWorld();
      expect(find.text('Altın: 9.500'), findsOneWidget);
      expect(game.plantation.fields.length, 1);
      await choose('field');
      await tapTile(4, 3);
      await tester.tap(find.text('Yerleştir'));
      await settleWorld();
      expect(game.plantation.fields.length, 2);
      expect(find.text('Altın: 9.000'), findsOneWidget);
      final field = game.plantation.fields.first;
      game.workforce.hire('turhan');
      game.workforce.buyEquipment(EquipmentType.teaShears);
      game.workforce.equip(game.worker, EquipmentType.teaShears);
      await settleWorld();
      final component = game.entities.singleWhere(
        (e) => e.definition.id == field.id,
      );
      Future<void> selectField() async {
        final point =
            (component.visualBounds.center - game.navigation.center) *
                game.navigation.zoom +
            const Offset(640, 360);
        await tester.tapAt(point);
        await tester.pump();
        expect(game.selectedEntity.value, same(component));
      }

      await selectField();
      expect(find.textContaining('Konum:'), findsNothing);
      expect(find.textContaining('Kapladığı alan:'), findsNothing);
      await tester.tap(find.text('Çay Dik'));
      await tester.pump();
      game.simulation.advance(PlantationConfig.growthDuration);
      await tester.pump();
      expect(find.text('Hasat Et'), findsNothing);
      expect(game.jobs.jobForField(field.id)?.isActive, isTrue);
      await tester.pump();
      await tester.tap(find.text('Taşı'));
      await tester.pump();
      expect(find.text('Bu nesne şu anda taşınamaz.'), findsOneWidget);
      game.simulation.advance(const Duration(seconds: 20));
      game.update(0);
      await tester.pump();
      expect(find.text('Çay Alım Yeri gerekli.'), findsOneWidget);
      await tester.tap(find.text('Taşı'));
      await tester.pump();
      final original = field.gridPosition;
      await tapTile(2, 2);
      await tester.tap(find.text('Vazgeç'));
      await tester.pump();
      expect(field.gridPosition, original);
      expect(field.harvestedStockKg, 25);
      expect(component.previewHidden, isFalse);
      await tester.tap(find.text('Taşı'));
      await tester.pump();
      await tapTile(2, 2);
      await tester.tap(find.text('Onayla'));
      await settleWorld();
      expect(field.gridPosition.x, 2);
      expect(field.harvestedStockKg, 25);
      expect(game.economy.balance, 7500);
      expect(component.gridPosition, field.gridPosition);
      await choose('road', 'Altyapı');
      final gold = game.economy.balance;
      final center = game.navigation.center;
      await tester.dragFrom(const Offset(900, 430), const Offset(60, 30));
      await tester.pump();
      expect(game.navigation.center, isNot(center));
      expect(game.economy.balance, gold);
      final zoom = game.navigation.zoom;
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(900, 400),
          scrollDelta: Offset(0, -50),
        ),
      );
      await tester.pump();
      expect(game.navigation.zoom, greaterThan(zoom));
      await tapTile(13, 7);
      await settleWorld();
      await tapTile(14, 7);
      await settleWorld();
      expect(game.economy.balance, gold - 50);
      expect(game.builder.mode, BuilderMode.placingRoad);
      await tester.tap(find.text('Bitir'));
      await tester.pump();
      await choose('field');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(game.builder.mode, BuilderMode.inactive);
      tester.view.physicalSize = const Size(740, 360);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('nav-inventory')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lojistik'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
