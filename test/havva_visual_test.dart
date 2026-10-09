import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/workers/havva_visual.dart';
import 'package:cay_simulasyonu/features/workers/turhan_visual.dart';
import 'package:cay_simulasyonu/features/workers/worker_component.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/game/models/entity_definition.dart';
import 'package:cay_simulasyonu/game/systems/asset_catalog.dart';
import 'package:cay_simulasyonu/game/systems/depth_sorter.dart';
import 'package:cay_simulasyonu/game/components/world_entity.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';

import 'simulation/balance_harness.dart';

void main() {
  const grid = IsometricGrid();
  WorkerDirectionalVisual visual() => WorkerDirectionalVisual(
    const GridPoint(0, 0),
    frames: HavvaVisualConfig.frames,
    walkCycle: HavvaVisualConfig.walkCycle,
  );
  for (final (delta, direction) in [
    (const GridPoint(1, 0), WorkerVisualDirection.se),
    (const GridPoint(0, 1), WorkerVisualDirection.sw),
    (const GridPoint(0, -1), WorkerVisualDirection.ne),
    (const GridPoint(-1, 0), WorkerVisualDirection.nw),
  ]) {
    test(
      'Havva ${direction.name}: real movement, available A, retained idle',
      () {
        final v = visual();
        v.update(delta, moving: true, dt: .14, grid: grid);
        expect(v.direction, direction);
        expect(v.state, WorkerVisualState.walk);
        expect(
          v.frame.asset,
          endsWith('HAVVA_WALK_${direction.name.toUpperCase()}_A.png'),
        );
        v.update(delta, moving: false, dt: .14, grid: grid);
        expect(v.state, WorkerVisualState.idle);
        expect(v.direction, direction);
        expect(
          v.frame.asset,
          endsWith('HAVVA_IDLE_${direction.name.toUpperCase()}.png'),
        );
      },
    );
  }
  test(
    'Havva repeats A/idle without inventing B; Turhan retains A/idle/B/idle',
    () {
      final h = visual(), t = TurhanVisual(const GridPoint(0, 0));
      for (var i = 0; i < 12; i++) {
        final p = GridPoint((i + 1) * .28, 0);
        h.update(p, moving: true, dt: .14, grid: grid);
        t.update(p, moving: true, dt: .14, grid: grid);
        expect(h.frameName, ['A', 'IDLE', 'A', 'IDLE'][i % 4]);
        expect(t.frameName, ['A', 'IDLE', 'B', 'IDLE'][i % 4]);
        expect(h.frame.asset, isNot(contains('_B.png')));
      }
      expect(
        HavvaVisualConfig.frameDuration,
        const Duration(milliseconds: 140),
      );
      expect(TurhanVisualConfig.frames.length, 12);
    },
  );
  test(
    'Havva path corner switches direction and restarts frame immediately',
    () {
      final v = visual();
      v.update(const GridPoint(1, 0), moving: true, dt: .14, grid: grid);
      v.update(const GridPoint(2, 0), moving: true, dt: .14, grid: grid);
      expect(v.frameName, 'IDLE');
      v.update(const GridPoint(2, -1), moving: true, dt: .14, grid: grid);
      expect(v.direction, WorkerVisualDirection.ne);
      expect(v.frameName, 'A');
    },
  );
  test(
    'Eight supplied PNGs decode, retain true exterior alpha and fit stable box',
    () async {
      expect(HavvaVisualConfig.frames.length, 8);
      for (final f in HavvaVisualConfig.frames.values) {
        final bytes = File('assets/images/${f.asset}').readAsBytesSync();
        expect(bytes[25], 6, reason: f.asset);
        final codec = await instantiateImageCodec(bytes);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 1254);
        expect(image.height, 1254);
        final rgba = (await image.toByteData(format: ImageByteFormat.rawRgba))!;
        var transparent = 0, opaque = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final a = rgba.getUint8((y * image.width + x) * 4 + 3);
            if (a == 0) transparent++;
            if (a == 255) opaque++;
            // Exterior strips cannot contain a baked rectangle/checkerboard.
            if (x < 300 || x >= 900 || y < 30 || y >= 1210) {
              expect(a, 0, reason: f.asset);
            }
            if (a > 128) {
              final scale = f.scaleFor(95);
              expect(
                31 + (x - f.feetX) * scale,
                inInclusiveRange(0, 62),
                reason: f.asset,
              );
              expect(
                95 + (y - f.feetY) * scale,
                inInclusiveRange(-.2, 95.2),
                reason: f.asset,
              );
            }
          }
        }
        expect(transparent, greaterThan(1200000));
        expect(opaque, greaterThan(200000));
        image.dispose();
        codec.dispose();
      }
    },
  );
  test('Havva frames never change domain, hitbox or logical depth', () {
    final w = Worker(
      id: 'havva',
      name: 'Havva',
      gridPosition: const GridPoint(4, 4),
    );
    final catalog = AssetCatalog();
    addTearDown(w.dispose);
    addTearDown(catalog.dispose);
    final c = WorkerComponent(
      worker: w,
      catalog: catalog,
      sprite: null,
      grid: grid,
      definition: const EntityDefinition(
        id: 'havva',
        name: 'Havva',
        kind: EntityKind.character,
        gridPosition: GridPoint(4, 4),
        visualSize: Size(62, 95),
        footprint: Footprint(1, 1),
      ),
    );
    expect(c.usesDirectionalSprites, true);
    final before = w.toJson(), bounds = c.visualBounds, depth = c.depthY;
    final house = WorldEntity(
      grid: grid,
      definition: const EntityDefinition(
        id: 'house',
        name: 'Ev',
        kind: EntityKind.building,
        gridPosition: GridPoint(5, 5),
        footprint: Footprint(2, 2),
        visualSize: Size(245, 235),
      ),
    );
    final sorter = DepthSorter();
    for (var i = 0; i < 8; i++) {
      c.visual.update(
        GridPoint(i.toDouble(), 0),
        moving: true,
        dt: .14,
        grid: grid,
      );
      sorter.sort([house, c]);
      expect(w.toJson(), before);
      expect(c.visualBounds, bounds);
      expect(c.depthY, depth);
      expect(c.hitTest(bounds.center), true);
      expect(c.priority, lessThan(house.priority));
    }
    w.gridPosition = const GridPoint(8, 8);
    sorter.sort([house, c]);
    expect(c.priority, greaterThan(house.priority));
    c.directionalSpritesEnabled = false;
    expect(c.usesDirectionalSprites, false);
  });
  test(
    'Actual Havva automation retains harvest, independent XP and sale economy',
    () {
      final h = BalanceRun('F_HAVVA'), t = BalanceRun('F_TURHAN');
      addTearDown(h.dispose);
      addTearDown(t.dispose);
      final hs = h.run(minutes: 5), ts = t.run(minutes: 5);
      expect(h.game.workforce.workers.single.id, 'havva');
      expect(
        h.game.workforce.workers.single.workerXp,
        t.game.workforce.workers.single.workerXp,
      );
      expect(
        h.game.plantation.fields.fold<int>(0, (n, f) => n + f.harvestCount),
        greaterThan(0),
      );
      expect(h.game.economy.balance, t.game.economy.balance);
      expect(hs, isNotNull);
      expect(ts, isNotNull);
      h.check();
      t.check();
    },
  );
}
