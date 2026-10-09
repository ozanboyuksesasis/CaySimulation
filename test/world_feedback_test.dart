import 'package:cay_simulasyonu/features/plantation/plantation_config.dart';

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/plantation/tea_field.dart';
import 'package:cay_simulasyonu/features/buildings/tea_factory.dart';
import 'package:cay_simulasyonu/features/workers/worker.dart';
import 'package:cay_simulasyonu/features/workers/worker_component.dart';
import 'package:cay_simulasyonu/game/components/world_entity.dart';
import 'package:cay_simulasyonu/game/systems/world_status.dart';
import 'package:cay_simulasyonu/game/systems/depth_sorter.dart';
import 'package:cay_simulasyonu/game/models/entity_definition.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/features/ui/world_move_gesture.dart';

void main() {
  TeaField field() => TeaField(
    id: 'f',
    gridPosition: const GridPoint(4, 4),
    footprint: const Footprint(2, 2),
  );
  test('Büyüme gerçek yapılandırılmış süreden kesintisiz hesaplanır', () {
    final f = field();
    addTearDown(f.dispose);
    f.plant(Duration.zero);
    for (final seconds in [
      0,
      2,
      5,
      7,
      10,
      14,
      PlantationConfig.growthDuration.inSeconds,
    ]) {
      f.advanceTo(Duration(seconds: seconds));
      expect(
        f.overallProgress,
        closeTo(seconds / PlantationConfig.growthDuration.inSeconds, 1e-9),
      );
    }
    expect(WorldStatus.field(f)!.symbol, '✓');
    expect(WorldStatus.field(f)!.progress, isNull);
  });
  test('Boş tarla sadece seçimde; stok çuvalı ve yeniden büyüme', () {
    final f = field();
    addTearDown(f.dispose);
    expect(WorldStatus.field(f), isNull);
    expect(WorldStatus.field(f, selected: true)!.label, 'Boş');
    f.plant(Duration.zero);
    f.advanceTo(PlantationConfig.growthDuration);
    f.completeHarvest(PlantationConfig.growthDuration);
    final before = f.toJson();
    expect(WorldStatus.field(f)!.sack, isTrue);
    expect(WorldStatus.field(f)!.label, '25 kg');
    expect(f.toJson(), before);
    f.advanceTo(const Duration(seconds: 50));
    expect(f.overallProgress, 0);
    f.removeHarvestedStock(25);
    f.advanceTo(const Duration(seconds: 55));
    expect(
      f.overallProgress,
      closeTo(5 / PlantationConfig.growthDuration.inSeconds, 1e-9),
    );
  });
  test('Fabrika dünya ilerlemesi ve kuru stok salt okunur', () {
    final f = TeaFactory(
      id: 'factory',
      gridPosition: const GridPoint(8, 8),
      footprint: const Footprint(3, 3),
      deliveryInteractionTile: (x: 7, y: 8),
    );
    addTearDown(f.dispose);
    expect(WorldStatus.factory(f), isNull);
    f.receiveRawTea(100);
    f.startProduction();
    f.advance(const Duration(seconds: 4));
    final before = f.toJson();
    expect(WorldStatus.factory(f)!.progress, .4);
    expect(f.toJson(), before);
    f.advance(const Duration(seconds: 6));
    expect(WorldStatus.factory(f)!.label, '20 kg Kuru Çay');
  });
  test('Boş işçi etiketsiz; seçili işçi adı gösterir', () {
    final w = Worker(
      id: 'turhan',
      name: 'Turhan',
      gridPosition: const GridPoint(3, 3),
    );
    addTearDown(w.dispose);
    expect(WorldStatus.worker(w), isNull);
    expect(WorldStatus.worker(w, selected: true)!.label, 'Turhan');
  });
  for (final position in [
    const GridPoint(4.5, 7.5),
    const GridPoint(4.5, 3.5),
    const GridPoint(7.5, 4.5),
    const GridPoint(3.5, 4.5),
  ]) {
    test('Ayak/ayak izi derinliği: ${position.x},${position.y}', () {
      const grid = IsometricGrid();
      final building = WorldEntity(
        grid: grid,
        definition: const EntityDefinition(
          id: 'b',
          name: 'Bina',
          kind: EntityKind.building,
          gridPosition: GridPoint(4, 4),
          visualSize: Size(350, 500),
          footprint: Footprint(3, 3),
        ),
      );
      final worker = Worker(
        id: 'turhan',
        name: 'Turhan',
        gridPosition: position,
      );
      addTearDown(worker.dispose);
      final actor = WorkerComponent(
        worker: worker,
        grid: grid,
        sprite: null,
        definition: EntityDefinition(
          id: 'w',
          name: 'Turhan',
          kind: EntityKind.character,
          gridPosition: position,
          visualSize: const Size(62, 95),
          footprint: const Footprint(1, 1),
        ),
      );
      final sorter = DepthSorter();
      sorter.sort([building, actor]);
      final front = position.x > 7 || position.y > 7;
      expect(actor.priority > building.priority, front);
      expect(actor.depthY, grid.toWorld(position).dy);
      final depth = actor.depthY, priority = actor.priority;
      for (var i = 0; i < 4; i++) {
        actor.visual.update(
          GridPoint(i.toDouble(), 0),
          moving: true,
          dt: .14,
          grid: grid,
        );
        sorter.sort([actor, building]);
        expect(actor.depthY, depth);
        expect(actor.priority, priority);
      }
    });
  }
  testWidgets('450 ms tutma başlatır; kaldırma onaylamaz', (tester) async {
    var began = 0, dragged = 0;
    final input = WorldMoveGesture(
      begin: (_) {
        began++;
        return true;
      },
      drag: (_) => dragged++,
    );
    addTearDown(input.dispose);
    input.down(1, Offset.zero);
    await tester.pump(const Duration(milliseconds: 449));
    expect(began, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(began, 1);
    input.move(1, const Offset(40, 20));
    expect(dragged, 1);
    input.up(1);
    expect(input.suppressTap, isTrue);
    expect(input.dragging, isFalse);
  });
  testWidgets('Dokunma, kamera sürükleme ve ikinci parmak tutmayı iptal eder', (
    tester,
  ) async {
    var began = 0;
    final input = WorldMoveGesture(
      begin: (_) {
        began++;
        return true;
      },
      drag: (_) {},
    );
    addTearDown(input.dispose);
    input.down(1, Offset.zero);
    input.up(1);
    await tester.pump(const Duration(seconds: 1));
    expect(began, 0);
    input.down(1, Offset.zero);
    input.move(1, const Offset(20, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(began, 0);
    input.up(1);
    input.down(1, Offset.zero);
    input.down(2, const Offset(40, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(began, 0);
  });
}
