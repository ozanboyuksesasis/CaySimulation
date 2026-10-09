import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/workers/turhan_visual.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/worker_component.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/game/models/entity_definition.dart';
import 'package:cay_simulasyonu/game/systems/asset_catalog.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';

void main() {
  const grid = IsometricGrid();
  for (final (delta, direction) in [
    (const GridPoint(1, 0), WorkerVisualDirection.se),
    (const GridPoint(0, 1), WorkerVisualDirection.sw),
    (const GridPoint(0, -1), WorkerVisualDirection.ne),
    (const GridPoint(-1, 0), WorkerVisualDirection.nw),
  ]) {
    test(
      'İzometrik gerçek hareket ${delta.x},${delta.y} → ${direction.name}',
      () {
        expect(TurhanVisual.directionFor(delta, grid), direction);
      },
    );
  }
  test('Yürüyüş A → IDLE → B → IDLE ve tekrar A, 140 ms', () {
    final visual = TurhanVisual(const GridPoint(0, 0));
    for (var i = 0; i < 5; i++) {
      visual.update(
        GridPoint((i + 1) * .28, 0),
        moving: true,
        dt: .14,
        grid: grid,
      );
      expect(visual.state, WorkerVisualState.walk);
      expect(visual.frameName, ['A', 'IDLE', 'B', 'IDLE', 'A'][i]);
    }
  });
  test(
    'Durunca son yöndeki idle, yeniden hareket ve köşe anında yön değişimi',
    () {
      final visual = TurhanVisual(const GridPoint(0, 0));
      visual.update(const GridPoint(0, -.2), moving: true, dt: .1, grid: grid);
      visual.update(const GridPoint(0, -.2), moving: false, dt: .1, grid: grid);
      expect(visual.direction, WorkerVisualDirection.ne);
      expect(visual.state, WorkerVisualState.idle);
      expect(visual.frame.asset, endsWith('TURHAN IDLE NE.png'));
      visual.update(
        const GridPoint(-.2, -.2),
        moving: true,
        dt: .1,
        grid: grid,
      );
      expect(visual.direction, WorkerVisualDirection.nw);
      expect(visual.frameName, 'A');
    },
  );
  test('Hareket durumu açık olsa bile gerçek konum değişmezse idle', () {
    final visual = TurhanVisual(const GridPoint(0, 0));
    visual.update(const GridPoint(.1, 0), moving: true, dt: .1, grid: grid);
    visual.update(const GridPoint(.1, 0), moving: true, dt: .1, grid: grid);
    expect(visual.state, WorkerVisualState.idle);
    expect(visual.direction, WorkerVisualDirection.se);
  });
  WorkerComponent component(String id, {bool enabled = true}) {
    final w = Worker(id: id, name: id, gridPosition: const GridPoint(4, 4));
    final catalog = AssetCatalog();
    addTearDown(w.dispose);
    addTearDown(catalog.dispose);
    return WorkerComponent(
      worker: w,
      catalog: catalog,
      directionalSpritesEnabled: enabled,
      sprite: null,
      grid: grid,
      definition: EntityDefinition(
        id: id,
        name: id,
        kind: EntityKind.character,
        gridPosition: const GridPoint(4, 4),
        visualSize: const Size(62, 95),
        footprint: const Footprint(1, 1),
      ),
    );
  }

  test(
    'Kare değişimi konum, derinlik, boyut ve seçim kutusunu değiştirmez',
    () {
      final c = component('turhan');
      final before = c.worker.toJson(),
          depth = c.depthY,
          bounds = c.visualBounds;
      for (var i = 0; i < 12; i++) {
        c.visual.update(
          GridPoint(i.toDouble(), 0),
          moving: true,
          dt: .14,
          grid: grid,
        );
        expect(c.worker.toJson(), before);
        expect(c.depthY, depth);
        expect(c.visualBounds, bounds);
        expect(c.hitTest(bounds.center), isTrue);
      }
    },
  );
  test('Turhan ve Havva yönlü sunum kullanır; eski Mehmet kullanmaz', () {
    expect(component('turhan').usesDirectionalSprites, isTrue);
    expect(component('havva').usesDirectionalSprites, isTrue);
    expect(component('worker-01').usesDirectionalSprites, isFalse);
    expect(component('turhan', enabled: false).usesDirectionalSprites, isFalse);
  });
  test(
    'On iki final PNG gerçek alfa içerir ve dış kenarları şeffaftır',
    () async {
      expect(TurhanVisualConfig.frames.length, 12);
      for (final frame in TurhanVisualConfig.frames.values) {
        final bytes = File('assets/images/${frame.asset}').readAsBytesSync();
        expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(bytes[25], 6, reason: frame.asset);
        final codec = await instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        final pixels = (await image.toByteData(
          format: ImageByteFormat.rawRgba,
        ))!;
        var transparent = 0;
        var opaque = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final alpha = pixels.getUint8((y * image.width + x) * 4 + 3);
            if (alpha == 0) transparent++;
            if (alpha == 255) opaque++;
            if (x == 0 ||
                y == 0 ||
                x == image.width - 1 ||
                y == image.height - 1) {
              expect(alpha, 0, reason: '${frame.asset}: dış kenar');
            }
          }
        }
        expect(transparent, greaterThan(0), reason: frame.asset);
        expect(opaque, greaterThan(0), reason: frame.asset);
        image.dispose();
        codec.dispose();
        final scale = frame.scaleFor(95);
        expect((frame.feetY - frame.bodyTop) * scale, closeTo(95, 1e-9));
        expect(
          frame.feetX * scale + (31 - frame.feetX * scale),
          closeTo(31, 1e-9),
        );
      }
    },
  );
  test(
    'Animasyon bileşeni olmadan gerçek hasat aynı süre ve 25 kg ürünü korur',
    () {
      final game = CayGame(initialGold: 10000, guidedTutorial: false);
      addTearDown(game.disposeState);
      game.workforce.hire('turhan');
      game.workforce.buyEquipment(EquipmentType.teaShears);
      game.workforce.equip(game.worker, EquipmentType.teaShears);
      game.builder.choose(catalogItem('field'));
      game.builder.preview(const GridPoint(5, 5));
      expect(game.builder.confirm(), isTrue);
      final field = game.plantation.fields.single;
      game.plantation.plant(field);
      game.simulation.advance(PlantationConfig.growthDuration);
      final job = game.jobs.requestHarvest(field)!;
      expect(job.harvestDuration, const Duration(seconds: 5));
      final gold = game.economy.balance;
      game.simulation.advance(const Duration(seconds: 20));
      expect(field.harvestedStockKg, 25);
      expect(game.economy.balance, gold);
      expect(game.inventory.freshTeaKg, 0);
    },
  );
}
