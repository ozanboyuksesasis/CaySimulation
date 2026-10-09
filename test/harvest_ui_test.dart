import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field_component.dart';
import 'package:cay_simulasyonu/features/plantation/field_visuals.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/components/world_entity.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dikim, canlı panel/görsel, hasat, yeniden büyüme ve üç tarla', (
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
    final fields = game.entities.whereType<TeaFieldComponent>().toList();
    expect(fields.length, 3);
    Future<void> select(WorldEntity entity) async {
      final point =
          (entity.visualBounds.center - game.navigation.center) *
              game.navigation.zoom +
          const Offset(640, 360);
      await tester.tapAt(point);
      await tester.pump();
      expect(game.selectedEntity.value, same(entity));
    }

    Future<void> advance(int seconds) async {
      game.jobs.advance(Duration(seconds: seconds));
      await tester.pump();
    }

    expect(find.text('Altın: 10.000'), findsOneWidget);
    expect(game.collectionCenter.receivedTeaKg, 0);
    await select(fields[0]);
    await tester.tap(find.text('Çay Dik'));
    await tester.pump();
    expect(find.text('Altın: 9.750'), findsOneWidget);
    expect(find.text('Durum: Ekildi'), findsOneWidget);
    expect(
      fields[0].sprite,
      same(game.assetCatalog.sprite(fieldAssets[TeaFieldState.planted])),
    );
    await advance(5);
    expect(find.text('Durum: Büyüyor — 1. aşama'), findsOneWidget);
    expect(
      fields[0].sprite,
      same(game.assetCatalog.sprite(fieldAssets[TeaFieldState.growing1])),
    );
    await advance(5);
    expect(find.text('Durum: Büyüyor — 2. aşama'), findsOneWidget);
    await select(fields[1]);
    await tester.tap(find.text('Çay Dik'));
    await tester.pump();
    await select(fields[0]);
    await advance(PlantationConfig.growing2Duration.inSeconds);
    expect(find.text('Durum: Hasada Hazır'), findsOneWidget);
    expect(
      fields[0].sprite,
      same(game.assetCatalog.sprite(fieldAssets[TeaFieldState.ready])),
    );
    expect(fields.map((e) => e.field.state).toList(), [
      TeaFieldState.ready,
      TeaFieldState.growing2,
      TeaFieldState.empty,
    ]);
    await tester.tap(find.text('Hasat Et'));
    await tester.pump();
    expect(game.collectionCenter.receivedTeaKg, 0);
    expect(fields[0].field.state, TeaFieldState.ready);
    expect(find.text('Mehmet tarlaya geliyor'), findsOneWidget);
    await advance(20);
    expect(find.text('Tarlada Bekleyen Yaş Çay: 25 kg'), findsOneWidget);
    expect(find.text('Durum: Hasat Edildi'), findsOneWidget);
    expect(
      fields[0].sprite,
      same(game.assetCatalog.sprite(fieldAssets[TeaFieldState.harvested])),
    );
    expect(game.economy.balance, 9500);
    await advance(5);
    expect(fields[0].field.state, TeaFieldState.harvested);
    fields[0].field.removeHarvestedStock(25);
    await advance(5);
    expect(find.text('Durum: Büyüyor — 1. aşama'), findsOneWidget);
    await select(fields[2]);
    game.economy.spend(game.economy.balance);
    await tester.tap(find.text('Çay Dik'));
    await tester.pump();
    expect(find.text('Yeterli altının yok.'), findsOneWidget);
    expect(fields[2].field.state, TeaFieldState.empty);
    await tester.pump(const Duration(seconds: 4));
    await select(
      game.entities.singleWhere((e) => e.definition.id == 'collection-01'),
    );
    expect(find.text('Çay Alım Yeri'), findsOneWidget);
    expect(find.text('Durum: Açık'), findsOneWidget);
    expect(find.text('Teslim Alınan Yaş Çay: 0 kg'), findsOneWidget);
    await select(fields[0]);
    tester.view.physicalSize = const Size(740, 360);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
