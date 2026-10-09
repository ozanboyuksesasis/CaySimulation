import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/builder/builder_system.dart';
import 'package:cay_simulasyonu/features/ui/game_navigation.dart';

void main() {
  for (final size in [
    const Size(1280, 720),
    const Size(960, 540),
    const Size(844, 390),
  ]) {
    testWidgets(
      'Birleşik envanter, dokunmatik yerleştirme ve güvenli alan: $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(
          left: 24,
          right: 24,
          bottom: 12,
        );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
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
        final beginRect = tester.getRect(
          find.byKey(const ValueKey('tutorial-begin')),
        );
        expect(beginRect.bottom, lessThanOrEqualTo(size.height - 156));
        expect(beginRect.height, greaterThanOrEqualTo(44));
        Future<void> tapKey(String key) async {
          final target = find.byKey(ValueKey(key));
          await tester.ensureVisible(target);
          await tester.tap(target);
          await tester.pump();
        }

        expect(find.byKey(const ValueKey('nav-shop')), findsNothing);
        for (final name in ['inventory', 'business']) {
          final rect = tester.getRect(find.byKey(ValueKey('nav-$name')));
          expect(rect.height, greaterThanOrEqualTo(44));
          expect(rect.left, greaterThanOrEqualTo(24));
          expect(rect.right, lessThanOrEqualTo(size.width - 24));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 12));
        }
        await tapKey('nav-inventory');
        await tapKey('acquire-field');
        expect(find.text('Altın: 10.000'), findsOneWidget);
        expect(game.plantation.fields, isEmpty);
        expect(game.builder.mode, BuilderMode.placingNew);
        expect(game.playerInventory.quantity('field'), 0);
        expect(find.text('Yerleştirme için uygun alan seç.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        expect(find.text('Yerleştirme için uygun alan seç.'), findsNothing);
        expect(find.byKey(const ValueKey('buy-field')), findsNothing);
        expect(game.panels.panel, GamePanel.none);
        expect(find.byKey(const ValueKey('nav-shop')), findsNothing);
        final gold = game.economy.balance;
        final first = await tester.startGesture(
          Offset(size.width * .60, size.height * .32),
          pointer: 1,
        );
        final second = await tester.startGesture(
          Offset(size.width * .80, size.height * .32),
          pointer: 2,
        );
        final zoom = game.navigation.zoom;
        await first.moveBy(const Offset(-15, 0));
        await second.moveBy(const Offset(15, 0));
        await tester.pump();
        await first.moveBy(const Offset(-30, 0));
        await second.moveBy(const Offset(30, 0));
        await tester.pump();
        await first.up();
        await second.up();
        await tester.pump();
        expect(game.navigation.zoom, greaterThan(zoom));
        expect(game.playerInventory.quantity('field'), 0);
        expect(game.plantation.fields, isEmpty);
        expect(game.economy.balance, gold);
        await tester.tap(find.text('İptal'));
        await tester.pump();
        expect(game.playerInventory.quantity('field'), 0);
        await tapKey('nav-inventory');
        await tapKey('acquire-field');
        game.navigation.reset();
        final point =
            (game.grid.toWorld(const GridPoint(5.2, 5.2)) -
                    game.navigation.center) *
                game.navigation.zoom +
            Offset(size.width / 2, size.height / 2);
        await tester.tapAt(point);
        await tester.pump();
        expect(game.builder.validationResult.valid, isTrue);
        await tester.tap(find.text('Yerleştir'));
        await tester.pump();
        expect(game.playerInventory.quantity('field'), 0);
        expect(game.plantation.fields.length, 1);
        expect(game.economy.balance, 9500);
        await tapKey('nav-inventory');
        expect(find.textContaining('Kurulu: 1'), findsOneWidget);
        await tapKey('nav-business');
        expect(find.text('İşletme Özeti'), findsOneWidget);
        expect(find.text('Çay Tarlası sayısı'), findsOneWidget);
        expect(
          game.entities.where((e) => e.definition.id == 'house-01').length,
          1,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
