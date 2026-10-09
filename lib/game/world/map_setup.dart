import 'dart:ui';

import '../../features/builder/build_catalog.dart';
import '../../features/builder/settlement.dart';
import '../models/entity_definition.dart';
import '../systems/grid_pathfinder.dart';
import 'prototype_map.dart';
import 'road_tiles.dart';

Settlement createSettlement(GameMapMode mode) {
  final definitions = prototypeEntities.where(
    (e) =>
        e.kind != EntityKind.character &&
        e.kind != EntityKind.vehicle &&
        (mode == GameMapMode.devTest || e.id == 'house-01'),
  );
  return Settlement(
    structures: definitions.map(
      (e) => PlacedStructure(
        id: e.id,
        item: e.kind == EntityKind.field
            ? catalogItem('field')
            : [
                ...buildCatalog,
                houseCatalogItem,
                marketCatalogItem,
              ].singleWhere((i) => i.assetPath == e.assetPath),
        gridPosition: e.gridPosition,
      ),
    ),
    roads: mode == GameMapMode.devTest
        ? roadTiles
        : <GridTile>{
            for (var x = 4; x <= 12; x++) (x: x, y: 7),
            for (var y = 4; y <= 10; y++) (x: 8, y: y),
          },
    homeTile: truckHomeTile,
  );
}

EntityDefinition structureDefinition(PlacedStructure structure) {
  final item = structure.item;
  return EntityDefinition(
    id: structure.id,
    name: item.displayName,
    kind: item.buildType == BuildType.field
        ? EntityKind.field
        : item.buildType == BuildType.decoration
        ? EntityKind.decoration
        : EntityKind.building,
    gridPosition: structure.gridPosition,
    visualSize: Size(item.visualWidth, item.visualHeight),
    footprint: item.footprint,
    assetPath: item.assetPath,
  );
}
