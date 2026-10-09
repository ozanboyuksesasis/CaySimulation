import 'dart:ui';

import 'package:cay_simulasyonu/game/camera/management_camera.dart';
import 'package:cay_simulasyonu/game/components/world_entity.dart';
import 'package:cay_simulasyonu/game/models/entity_definition.dart';
import 'package:cay_simulasyonu/game/models/game_config.dart';
import 'package:cay_simulasyonu/game/systems/depth_sorter.dart';
import 'package:cay_simulasyonu/game/world/isometric_grid.dart';
import 'package:cay_simulasyonu/game/world/prototype_map.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const grid = IsometricGrid();
  test('İzometrik dönüşüm negatif ve kesirli konumlarda tersinirdir', () {
    for (final p in [
      const GridPoint(0, 0),
      const GridPoint(19, 19),
      const GridPoint(-3.7, 8.2),
      const GridPoint(10.4, -12.8),
    ]) {
      final converted = grid.toGrid(grid.toWorld(p));
      expect(converted.x, closeTo(p.x, 1e-9));
      expect(converted.y, closeTo(p.y, 1e-9));
    }
    expect(grid.toWorld(const GridPoint(1, 0)), const Offset(64, 32));
    expect(grid.contains(const GridPoint(20, 0)), isFalse);
    expect(grid.toGrid(const Offset(-1, 0)).tile.x, -1);
  });
  test('Farklı karo boyutu mantıksal koordinatı değiştirmez', () {
    const scaled = IsometricGrid(tileWidth: 200, tileHeight: 100);
    final world = scaled.toWorld(const GridPoint(3.5, 7));
    final point = scaled.toGrid(world);
    expect(point.x, 3.5);
    expect(point.y, 7);
  });
  test(
    'Örnek yerleşimin kimlikleri benzersiz ve alanları harita içindedir',
    () {
      expect(
        prototypeEntities.map((e) => e.id).toSet().length,
        prototypeEntities.length,
      );
      for (final e in prototypeEntities) {
        expect(grid.contains(e.gridPosition), isTrue);
        expect(
          e.gridPosition.x + (e.footprint?.columns ?? 1),
          lessThanOrEqualTo(grid.columns),
        );
        expect(
          e.gridPosition.y + (e.footprint?.rows ?? 1),
          lessThanOrEqualTo(grid.rows),
        );
      }
    },
  );
  test('Hareket eden karakter binanın arkasından önüne geçebilir', () {
    final building = WorldEntity(
      grid: grid,
      definition: prototypeBuildingsForTest,
    );
    final character = WorldEntity(
      grid: grid,
      definition: const EntityDefinition(
        id: 'actor',
        name: 'İşçi',
        kind: EntityKind.character,
        gridPosition: GridPoint(1, 1),
        visualSize: Size(40, 80),
        footprint: Footprint(1, 1),
      ),
    );
    final sorter = DepthSorter();
    sorter.sort([building, character]);
    expect(character.priority, lessThan(building.priority));
    character.setGridPosition(const GridPoint(9, 9));
    sorter.sort([character, building]);
    expect(character.priority, greaterThan(building.priority));
  });
  test('Derinlik eşitliğinde kimlik deterministik sıralama sağlar', () {
    WorldEntity entity(String id) => WorldEntity(
      grid: grid,
      definition: EntityDefinition(
        id: id,
        name: id,
        kind: EntityKind.character,
        gridPosition: const GridPoint(4, 4),
        visualSize: const Size(20, 40),
      ),
    );
    final a = entity('a');
    final b = entity('b');
    final sorter = DepthSorter();
    sorter.sort([b, a]);
    expect(a.priority, lessThan(b.priority));
    sorter.sort([a, b]);
    expect(a.priority, lessThan(b.priority));
  });
  test('Kamera yakınlaştırma sınırları, odak noktası ve uzak kaydırma', () {
    final camera = ManagementCamera(CameraComponent(), grid);
    camera.resize(const Size(800, 400));
    camera.reset();
    camera.zoomAt(1, const Offset(400, 200));
    const focal = Offset(450, 225);
    final before = camera.screenToWorld(focal);
    camera.zoomAt(1.5, focal);
    // Flame transforms use float32 matrices; sub-pixel tolerance is intentional.
    expect((camera.screenToWorld(focal) - before).distance, lessThan(0.001));
    camera.zoomAt(100, focal);
    expect(camera.zoom, GameConfig.maxZoom);
    camera.pan(const Offset(100000, -100000));
    final logical = grid.toGrid(camera.center);
    expect(logical.x, inInclusiveRange(0, 20));
    expect(logical.y, inInclusiveRange(0, 20));
    camera.zoomAt(0.001, focal);
    expect(camera.zoom, GameConfig.minZoom);
    camera.resize(const Size(4000, 2000));
    expect(camera.center, grid.bounds.center);
  });
}

const prototypeBuildingsForTest = EntityDefinition(
  id: 'building',
  name: 'Ev',
  kind: EntityKind.building,
  gridPosition: GridPoint(4, 4),
  visualSize: Size(200, 200),
  footprint: Footprint(3, 3),
);
