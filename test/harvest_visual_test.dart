import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/harvest_test_scene.dart';
import 'package:cay_simulasyonu/game/models/entity_definition.dart';
import 'package:cay_simulasyonu/game/systems/asset_catalog.dart';
import 'package:cay_simulasyonu/game/systems/world_status.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/worker_component.dart';
import 'package:cay_simulasyonu/features/workers/worker_visual.dart';
import 'package:cay_simulasyonu/features/workers/harvest_job.dart';
import 'package:cay_simulasyonu/features/workers/harvest_visual.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field_component.dart';

void main() {
  late HarvestTestGame game;
  setUp(() => game = HarvestTestGame('Makas'));
  tearDown(() => game.disposeState());
  void untilWorking() {
    for (
      var i = 0;
      i < 200 &&
          !game.workforce.workers.every((w) => w.state == WorkerState.working);
      i++
    ) {
      game.simulation.advance(const Duration(milliseconds: 10));
    }
    expect(
      game.workforce.workers.every((w) => w.state == WorkerState.working),
      isTrue,
    );
  }

  WorkerComponent actor(Worker worker) => WorkerComponent(
    definition: EntityDefinition(
      id: worker.id,
      name: worker.name,
      kind: EntityKind.character,
      gridPosition: worker.gridPosition,
      visualSize: const Size(62, 95),
    ),
    grid: const IsometricGrid(),
    sprite: null,
    worker: worker,
    currentJob: () => game.jobs.jobForWorker(worker),
  );
  test('Real arrival enters harvest; actual completion ends it with unchanged yield and XP', () {
    final w = game.workforce.workers.first,
        a = actor(game.workforce.workers.first);
    a.update(.01);
    expect(a.visual.state, isNot(WorkerVisualState.harvest));
    untilWorking();
    a.update(.01);
    expect(a.visual.state, WorkerVisualState.harvest);
    final j = game.jobs.jobForWorker(w)!;
    expect(j.harvestDuration, const Duration(seconds: 5));
    final gold = game.economy.balance;
    game.simulation.advance(const Duration(seconds: 6));
    a.update(.01);
    expect(a.visual.state, isNot(WorkerVisualState.harvest));
    expect(a.harvest.particleCount(1), 0);
    expect(
      game.plantation.fields.map((f) => f.harvestedStockKg),
      everyElement(25),
    );
    expect(game.workforce.workers.map((w) => w.workerXp), everyElement(10));
    expect(game.economy.balance, gold);
  });
  test(
    'Cancelled or detached real job immediately removes harvest visuals',
    () {
      untilWorking();
      final a = actor(game.workforce.workers.first);
      final j = game.jobs.jobForWorker(a.worker)!;
      a.update(.01);
      expect(a.harvest.active, isTrue);
      j.status = JobStatus.failed;
      a.update(.01);
      expect(a.visual.state, WorkerVisualState.idle);
      expect(a.harvest.active, isFalse);
      expect(a.harvest.particleCount(1), 0);
      j.status = JobStatus.inProgress;
      a.worker.assignedJobId = null;
      a.update(.01);
      expect(a.harvest.active, isFalse);
    },
  );
  test(
    'Progress and action phase use job worked time, never rendering delta',
    () {
      untilWorking();
      final a = actor(game.workforce.workers.first);
      final j = game.jobs.jobForWorker(a.worker)!;
      game.simulation.advance(const Duration(milliseconds: 120));
      final expected = game.jobs.progress(j), phase = a.harvest.phase;
      for (var i = 0; i < 100; i++) {
        a.update(10);
      }
      expect(a.harvest.phase, phase);
      expect(a.harvest.progress, expected);
      final f = game.plantation.fields.singleWhere((f) => f.id == j.fieldId);
      final s = WorldStatus.field(
        f,
        harvestActive: true,
        harvestProgress: expected,
      )!;
      expect(s.label, 'Hasat');
      expect(s.progress, expected);
    },
  );
  test(
    'Direction faces field; effects preserve feet, selection bounds and depth',
    () {
      untilWorking();
      final a = actor(game.workforce.workers.first);
      final p = a.worker.gridPosition,
          depth = a.depthY,
          bounds = a.visualBounds;
      final target = a.worker.workFacingTarget!;
      a.update(.01);
      expect(
        a.visual.direction,
        WorkerDirectionalVisual.directionFor(
          GridPoint(target.x - p.x, target.y - p.y),
          const IsometricGrid(),
        ),
      );
      for (var i = 0; i < 100; i++) {
        a.update(.14);
      }
      expect(a.worker.gridPosition, same(p));
      expect(a.depthY, depth);
      expect(a.visualBounds, bounds);
      expect(a.visual.frameName, 'IDLE');
    },
  );
  test(
    'Procedural rendering cannot award XP, spend Gold or advance the job',
    () {
      untilWorking();
      final w = game.workforce.workers.first;
      final v = HarvestVisual(w, () => game.jobs.jobForWorker(w));
      final j = v.activeJob!,
          snapshot = w.toJson().toString(),
          gold = game.economy.balance,
          xp = game.progression.currentXp;
      final worked = j.worked, duration = j.harvestDuration;
      final recorder = PictureRecorder(), painter = HarvestEffectPainter();
      final canvas = Canvas(recorder);
      for (var i = 0; i < 100; i++) {
        painter.render(canvas, v, WorkerVisualDirection.se, 1, w.id);
      }
      recorder.endRecording().dispose();
      expect(w.toJson().toString(), snapshot);
      expect(j.worked, worked);
      expect(j.harvestDuration, duration);
      expect(game.economy.balance, gold);
      expect(game.progression.currentXp, xp);
    },
  );
  test('Each worker has independent phases; shears and motor differ', () {
    final mixed = HarvestTestGame('Karma');
    addTearDown(mixed.disposeState);
    final a = HarvestVisual(
      mixed.workforce.workers.first,
      () => mixed.jobs.jobForWorker(mixed.workforce.workers.first),
    );
    final b = HarvestVisual(
      mixed.workforce.workers.last,
      () => mixed.jobs.jobForWorker(mixed.workforce.workers.last),
    );
    mixed.simulation.advance(const Duration(seconds: 2));
    expect(a.active, isTrue);
    expect(b.active, isTrue);
    expect(a.motor, isFalse);
    expect(b.motor, isTrue);
    expect(a.cycleSeconds, .56);
    expect(b.cycleSeconds, .32);
    expect(a.phase, isNot(b.phase));
    expect(a.activeJob!.harvestDuration, const Duration(seconds: 5));
    expect(b.activeJob!.harvestDuration, const Duration(milliseconds: 2500));
  });
  test('Particles remain bounded and distant zoom hides them', () {
    untilWorking();
    final a = actor(game.workforce.workers.first);
    for (var i = 0; i < 100; i++) {
      expect(a.harvest.particleCount(1), lessThanOrEqualTo(10));
      expect(a.harvest.particleCount(.5), 0);
      game.simulation.advance(const Duration(milliseconds: 100));
    }
    expect(a.harvest.particleCount(1), 0);
  });
  test('Completion feedback captures real stock delta and expires without mutating stock', () async {
    final f = game.plantation.fields.first, catalog = AssetCatalog();
    addTearDown(catalog.dispose);
    final c = TeaFieldComponent(
      definition: EntityDefinition(
        id: f.id,
        name: 'Çay Tarlası',
        kind: EntityKind.field,
        gridPosition: f.gridPosition,
        visualSize: const Size(240, 155),
      ),
      grid: const IsometricGrid(),
      field: f,
      catalog: catalog,
    );
    await c.onLoad();
    game.simulation.advance(const Duration(seconds: 10));
    expect(c.completedKg, f.harvestedStockKg);
    expect(c.completionRemaining, greaterThan(0));
    c.update(2);
    expect(c.completionRemaining, 0);
    expect(f.harvestedStockKg, 25);
    c.onRemove();
  });
  test('Effects disabled still complete the exact same real work', () {
    final a = actor(game.workforce.workers.first)
      ..harvestEffectsEnabled = false;
    for (var i = 0; i < 100; i++) {
      game.simulation.advance(const Duration(milliseconds: 100));
      a.update(.1);
    }
    expect(
      game.plantation.fields.fold(0, (s, f) => s + f.harvestedStockKg),
      50,
    );
    expect(
      game.jobs.jobs.every((j) => j.status == JobStatus.completed),
      isTrue,
    );
  });
}
