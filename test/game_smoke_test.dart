import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Gerçek assetlerle dünya yüklenir ve kontroller çalışır', (
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
      await game.loaded.timeout(const Duration(seconds: 20));
      await game.ready();
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(game.isWorldReady, isTrue);
    expect(game.entities.length, 11);
    expect(game.assetCatalog.warnings, isEmpty);
    expect(game.entities.every((e) => e.sprite != null), isTrue);
    expect(find.text('Altın: 10.000'), findsOneWidget);
    await tester.tap(find.byTooltip('Geliştirici araçları'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Izgara'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(game.showGrid.value, isTrue);
    final worker = game.entities.firstWhere(
      (e) => e.definition.id == 'worker-01',
    );
    final nav = game.navigation;
    final point = worker.visualBounds.center;
    final screen = (point - nav.center) * nav.zoom + const Offset(640, 360);
    await tester.tapAt(screen);
    await tester.pump();
    expect(game.selectedEntity.value, same(worker));
    expect(find.text('Mehmet'), findsOneWidget);
    final before = nav.center;
    await tester.dragFrom(const Offset(900, 480), const Offset(80, 25));
    await tester.pump();
    expect(nav.center, isNot(before));
    expect(game.selectedEntity.value, same(worker));
    await tester.tap(find.byTooltip('Yakınlaş'));
    await tester.pump();
    expect(nav.zoom, greaterThan(0.65));
    final wheelZoom = nav.zoom;
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(850, 400),
        scrollDelta: Offset(0, -100),
      ),
    );
    await tester.pump();
    expect(nav.zoom, greaterThan(wheelZoom));
    final pinchZoom = nav.zoom;
    final first = await tester.startGesture(const Offset(700, 420), pointer: 1);
    final second = await tester.startGesture(
      const Offset(900, 420),
      pointer: 2,
    );
    await first.moveTo(const Offset(650, 420));
    await second.moveTo(const Offset(950, 420));
    await tester.pump();
    await first.moveTo(const Offset(600, 420));
    await second.moveTo(const Offset(1000, 420));
    await tester.pump();
    expect(nav.zoom, greaterThan(pinchZoom));
    await first.up();
    await second.up();
    tester.view.physicalSize = const Size(740, 360);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
