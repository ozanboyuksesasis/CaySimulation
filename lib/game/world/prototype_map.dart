import 'dart:ui';

import '../../features/buildings/building_prototypes.dart';
import '../../features/plantation/plantation_prototype.dart';
import '../../features/workers/worker_prototype.dart';
import '../models/entity_definition.dart';
import '../systems/game_assets.dart';
import 'isometric_grid.dart';
export 'road_tiles.dart' show isRoad;

class MapZone {
  const MapZone(this.name, this.origin, this.footprint, this.color);
  final String name;
  final GridPoint origin;
  final Footprint footprint;
  final Color color;
  bool contains(int x, int y) =>
      x >= origin.x &&
      y >= origin.y &&
      x < origin.x + footprint.columns &&
      y < origin.y + footprint.rows;
}

const prototypeZones = [
  MapZone('ÇAY BAHÇESİ', GridPoint(1, 1), Footprint(6, 6), Color(0xFF527E49)),
  MapZone('ÇİFTLİK EVİ', GridPoint(1, 9), Footprint(6, 4), Color(0xFF7B895B)),
  MapZone(
    'ÇAY ALIM YERİ',
    GridPoint(10, 1),
    Footprint(7, 6),
    Color(0xFF819077),
  ),
  MapZone(
    'İŞLEME VE FABRİKA',
    GridPoint(11, 10),
    Footprint(7, 7),
    Color(0xFF6D7F79),
  ),
  MapZone('PAZAR', GridPoint(2, 14), Footprint(7, 4), Color(0xFF9B906C)),
];

const prototypeEntities = [
  ...prototypeFields,
  ...prototypeBuildings,
  prototypeWorker,
  EntityDefinition(
    id: 'truck-01',
    name: 'Çay Kamyonu',
    kind: EntityKind.vehicle,
    gridPosition: GridPoint(10, 7),
    visualSize: Size(190, 130),
    footprint: Footprint(1, 1),
    assetPath: GameAssets.transportTruck,
  ),
  EntityDefinition(
    id: 'well-01',
    name: 'Köy kuyusu',
    kind: EntityKind.decoration,
    gridPosition: GridPoint(2, 12),
    visualSize: Size(95, 105),
    footprint: Footprint(1, 1),
    assetPath: GameAssets.well,
  ),
];
