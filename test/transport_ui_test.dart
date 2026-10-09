import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field_component.dart';
import 'package:cay_simulasyonu/features/transport/transport_config.dart';
import 'package:cay_simulasyonu/features/transport/transport_job.dart';
import 'package:cay_simulasyonu/features/transport/transport_vehicle.dart';
import 'package:cay_simulasyonu/features/transport/vehicle_component.dart';
import 'package:cay_simulasyonu/features/ui/game_screen.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/components/world_entity.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Hasat, yol üzerinde nakliye, canlı stok panelleri ve FIFO teslimat',
    (tester) async {
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
      final truck = game.entities.whereType<VehicleComponent>().single;
      Future<void> select(WorldEntity entity) async {
        // The truck can occlude a field during loading. Click its visible area.
        final frontFirst = [...game.entities]
          ..sort((a, b) => b.priority.compareTo(a.priority));
        final bounds = entity.visualBounds;
        final candidates = [
          bounds.center,
          bounds.centerLeft + const Offset(8, 0),
          bounds.centerRight - const Offset(8, 0),
          bounds.bottomCenter - const Offset(0, 8),
        ];
        final worldPoint = candidates.firstWhere(
          (point) =>
              identical(frontFirst.firstWhere((e) => e.hitTest(point)), entity),
        );
        final point =
            (worldPoint - game.navigation.center) * game.navigation.zoom +
            const Offset(640, 360);
        await tester.tapAt(point);
        await tester.pump();
        expect(game.selectedEntity.value, same(entity));
      }

      Future<void> advance(Duration duration) async {
        game.simulation.advance(duration);
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

      for (final entity in fields.take(2)) {
        await select(entity);
        await tester.tap(find.text('Çay Dik'));
        await tester.pump();
      }
      await advance(PlantationConfig.growthDuration);
      for (final entity in fields.take(2)) {
        await select(entity);
        await tester.tap(find.text('Hasat Et'));
        await tester.pump();
      }
      await advance(const Duration(seconds: 30));
      expect(game.inventory.freshTeaKg, 0);
      expect(game.collectionCenter.receivedTeaKg, 0);
      await select(fields[0]);
      await tester.tap(find.text('Taşıma Emri Ver'));
      await tester.pump();
      expect(find.text('Nakliye: Çay Kamyonu geliyor'), findsOneWidget);
      expect(find.text('Taşıma Emri Ver'), findsNothing);
      await select(fields[1]);
      await tester.tap(find.text('Taşıma Emri Ver'));
      await tester.pump();
      expect(find.text('Nakliye: Taşıma sırası bekliyor'), findsOneWidget);
      await select(truck);
      expect(find.text('Çay Kamyonu'), findsOneWidget);
      expect(find.text('Durum: Tarlaya gidiyor'), findsOneWidget);
      await until(VehicleState.loading);
      expect(find.text('Durum: Yükleme yapılıyor'), findsOneWidget);
      await advance(const Duration(seconds: 2));
      expect(game.vehicle.cargoKg, 0);
      expect(fields[0].field.harvestedStockKg, 25);
      await select(fields[0]);
      expect(find.text('Nakliye: Yükleniyor'), findsOneWidget);
      await advance(const Duration(seconds: 1));
      expect(find.text('Tarlada Bekleyen Yaş Çay: 0 kg'), findsNothing);
      expect(find.text('Durum: Yeniden büyüyor'), findsOneWidget);
      expect(game.vehicle.cargoKg, 25);
      expect(game.collectionCenter.receivedTeaKg, 0);
      await until(VehicleState.unloading);
      await select(truck);
      expect(find.text('Durum: Teslimat yapılıyor'), findsOneWidget);
      expect(find.text('Yük: 25 / 100 kg'), findsOneWidget);
      await select(
        game.entities.singleWhere((e) => e.definition.id == 'collection-01'),
      );
      expect(find.text('Teslim Alınan Yaş Çay: 0 kg'), findsOneWidget);
      await advance(TransportConfig.unloadingDuration);
      expect(find.text('Teslim Alınan Yaş Çay: 25 kg'), findsOneWidget);
      expect(game.collectionCenter.receivedTeaKg, 25);
      expect(game.transport.jobs.first.status, JobStatus.completed);
      expect(game.vehicle.state, VehicleState.movingToField);
      await advance(const Duration(seconds: 30));
      expect(find.text('Teslim Alınan Yaş Çay: 50 kg'), findsOneWidget);
      expect(game.vehicle.state, VehicleState.idle);
      expect(game.vehicle.cargoKg, 0);
      expect(game.economy.balance, 9500);
      await advance(PlantationConfig.growthDuration);
      expect(fields[0].field.state, TeaFieldState.ready);
      await select(truck);
      tester.view.physicalSize = const Size(740, 360);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
