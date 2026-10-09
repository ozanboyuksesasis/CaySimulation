import 'dart:ui';

import '../../game/models/entity_definition.dart';
import '../../game/systems/game_assets.dart';
import '../../game/world/isometric_grid.dart';

const prototypeBuildings = [
  EntityDefinition(
    id: 'house-01',
    name: 'Çiftlik Evi',
    kind: EntityKind.building,
    gridPosition: GridPoint(3, 9),
    visualSize: Size(245, 235),
    footprint: Footprint(2, 2),
    assetPath: GameAssets.farmerHouse,
  ),
  EntityDefinition(
    id: 'collection-01',
    name: 'Çay Alım Yeri',
    kind: EntityKind.building,
    gridPosition: GridPoint(11, 3),
    visualSize: Size(285, 230),
    footprint: Footprint(3, 2),
    assetPath: GameAssets.collectionCenter,
  ),
  EntityDefinition(
    id: 'warehouse-01',
    name: 'Depo',
    kind: EntityKind.building,
    gridPosition: GridPoint(11, 6),
    visualSize: Size(245, 205),
    footprint: Footprint(2, 1),
    assetPath: GameAssets.warehouse,
  ),
  EntityDefinition(
    id: 'factory-01',
    name: 'Çay Fabrikası',
    kind: EntityKind.building,
    gridPosition: GridPoint(13, 11),
    visualSize: Size(365, 315),
    footprint: Footprint(3, 3),
    assetPath: GameAssets.factory,
  ),
  EntityDefinition(
    id: 'market-01',
    name: 'Pazar',
    kind: EntityKind.building,
    gridPosition: GridPoint(5, 14),
    visualSize: Size(260, 220),
    footprint: Footprint(2, 2),
    assetPath: GameAssets.market,
  ),
];
