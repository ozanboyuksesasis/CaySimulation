import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/ui/game_navigation.dart';
import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/worker_idle_system.dart';
import 'package:cay_simulasyonu/features/workers/equipment.dart';
import 'package:cay_simulasyonu/features/workers/havva_visual.dart';
import 'package:cay_simulasyonu/features/workers/turhan_visual.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/game/systems/grid_pathfinder.dart';

void main() {
  test('Both characters face the actual field from the same road point', () {
    for (final frames in [
      TurhanVisualConfig.frames,
      HavvaVisualConfig.frames,
    ]) {
      final v = WorkerDirectionalVisual(
        const GridPoint(3.5, 3.5),
        frames: frames,
        walkCycle: const ['A', 'IDLE'],
      );
      v.faceTarget(
        const GridPoint(3.5, 3.5),
        const GridPoint(3.5, 1.5),
        const IsometricGrid(),
      );
      expect(v.direction, WorkerVisualDirection.ne);
      v.faceTarget(
        const GridPoint(3.5, 3.5),
        const GridPoint(3.5, 5.5),
        const IsometricGrid(),
      );
      expect(v.direction, WorkerVisualDirection.sw);
      expect(v.state, WorkerVisualState.idle);
      v.update(
        const GridPoint(3.5, 3.5),
        moving: false,
        dt: .1,
        grid: const IsometricGrid(),
      );
      expect(v.direction, WorkerVisualDirection.sw);
    }
  });
  test(
    'Idle stroll is bounded, avoids blocked and occupied tiles, and pauses',
    () {
      final p = GridPathfinder(columns: 10, rows: 10, blocked: {(x: 5, y: 4)});
      final idle = WorkerIdleSystem(p);
      final a = Worker(
        id: 'turhan',
        name: 'Turhan',
        gridPosition: const GridPoint(4.5, 4.5),
      );
      final b = Worker(
        id: 'havva',
        name: 'Havva',
        gridPosition: const GridPoint(4.5, 5.5),
      );
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final visited = <GridTile>{};
      for (var i = 0; i < 600; i++) {
        idle.advance(const Duration(milliseconds: 100), [a, b], {});
        visited.add(tileAt(a.gridPosition));
        expect(p.walkable(tileAt(a.gridPosition)), isTrue);
        expect(tileAt(a.gridPosition), isNot(tileAt(b.gridPosition)));
        expect(
          (a.gridPosition.x - 4.5).abs() + (a.gridPosition.y - 4.5).abs(),
          lessThanOrEqualTo(2.001),
        );
      }
      expect(visited.length, greaterThan(1));
      a.state = WorkerState.movingToJob;
      final before = a.gridPosition;
      idle.advance(const Duration(seconds: 1), [a, b], {});
      expect(a.isStrolling, isFalse);
      expect(a.gridPosition, same(before));
    },
  );
  test('Two fields reserve distinct harvest points and preserve yields', () {
    final g = CayGame(guidedTutorial: false, automationEnabled: false);
    addTearDown(g.disposeState);
    for (final p in [const GridPoint(5, 5), const GridPoint(5, 8)]) {
      g.builder.choose(catalogItem('field'));
      g.builder.preview(p);
      expect(g.builder.confirm(), isTrue);
    }
    g.progression.award('fixture', 100);
    for (final id in ['turhan', 'havva']) {
      expect(g.workforce.hire(id).success, isTrue);
      g.workforce.buyEquipment(EquipmentType.teaShears);
      g.workforce.equip(g.workforce.workers.last, EquipmentType.teaShears);
    }
    for (final f in g.plantation.fields) {
      g.plantation.plant(f);
    }
    g.plantation.advance(PlantationConfig.growthDuration);
    for (final f in g.plantation.fields) {
      g.jobs.requestHarvest(f);
    }
    expect(g.jobs.reservedWorkTiles.length, 2);
    for (var i = 0; i < 300; i++) {
      g.simulation.advance(const Duration(milliseconds: 100));
    }
    expect(
      g.plantation.fields.every(
        (f) => f.state == TeaFieldState.harvested && f.harvestedStockKg == 25,
      ),
      isTrue,
    );
    expect(g.workforce.workers.every((w) => w.workerXp == 10), isTrue);
  });
  test('Tutorial closes inventory only on a successful step transition', () {
    final g = CayGame();
    addTearDown(g.disposeState);
    g.tutorial!.begin();
    g.builder.choose(catalogItem('field'));
    g.builder.preview(const GridPoint(5, 5));
    expect(g.builder.confirm(), isTrue);
    g.panels.open(GamePanel.inventory);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isFalse);
    expect(g.panels.panel, GamePanel.inventory);
    expect(g.workforce.hire('turhan').success, isTrue);
    expect(g.panels.panel, GamePanel.none);
    g.panels.open(GamePanel.inventory);
    expect(g.workforce.buyEquipment(EquipmentType.teaShears).success, isTrue);
    expect(g.panels.panel, GamePanel.none);
  });
}
