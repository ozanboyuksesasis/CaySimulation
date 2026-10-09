import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'build_catalog.dart';

enum GameMapMode { devTest, newGame }

class PlacedStructure {
  PlacedStructure({
    required this.id,
    required this.item,
    required this.gridPosition,
  });
  final String id;
  final BuildCatalogItem item;
  GridPoint gridPosition;
  Map<String, Object?> toJson() => {
    'id': id,
    'catalogId': item.id,
    'type': item.buildType.name,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
  };
}

/// Logical ownership only. A road has a tile owner even when rendered as terrain.
class Settlement extends ChangeNotifier {
  Settlement({
    required Iterable<PlacedStructure> structures,
    required Set<GridTile> roads,
    required this.homeTile,
    this.columns = 20,
    this.rows = 20,
  }) : _structures = {for (final e in structures) e.id: e},
       _roads = {...roads} {
    _index();
  }
  final int columns, rows;
  final GridTile homeTile;
  final Map<String, PlacedStructure> _structures;
  final Set<GridTile> _roads;
  final Map<GridTile, String> _occupants = {};
  final Map<String, int> _sequences = {};
  List<PlacedStructure> get structures => List.unmodifiable(_structures.values);
  Set<GridTile> get roads => Set.unmodifiable(_roads);
  Map<GridTile, String> get occupancy => Map.unmodifiable(_occupants);
  PlacedStructure? byId(String id) => _structures[id];
  Set<GridTile> get blocked => {
    for (final e in _structures.values)
      if (e.item.buildType != BuildType.road)
        ...GridPathfinder.footprintTiles(e.gridPosition, e.item.footprint),
  };
  String nextId(String prefix) {
    var n = _sequences[prefix] ?? 0;
    String id;
    do {
      id = '${prefix}_${(++n).toString().padLeft(3, '0')}';
    } while (_structures.containsKey(id));
    _sequences[prefix] = n;
    return id;
  }

  void _index() {
    _occupants.clear();
    for (final tile in _roads) {
      _occupants[tile] = 'road:${tile.x},${tile.y}';
    }
    for (final e in _structures.values) {
      for (final tile in GridPathfinder.footprintTiles(
        e.gridPosition,
        e.item.footprint,
      )) {
        _occupants[tile] = e.id;
      }
    }
  }

  void add(PlacedStructure structure) {
    if (_structures.containsKey(structure.id)) {
      throw ArgumentError('Yapı kimliği zaten var.');
    }
    _structures[structure.id] = structure;
    if (structure.item.buildType == BuildType.road) {
      _roads.add(tileAt(structure.gridPosition));
    }
    _index();
    notifyListeners();
  }

  void move(String id, GridPoint position) {
    _structures[id]!.gridPosition = position;
    _index();
    notifyListeners();
  }

  GridTile? roadAccess(
    GridPoint position,
    Footprint footprint, {
    String? ignoreId,
  }) {
    final obstacles = {
      for (final e in _structures.values)
        if (e.id != ignoreId && e.item.buildType != BuildType.road)
          ...GridPathfinder.footprintTiles(e.gridPosition, e.item.footprint),
      ...GridPathfinder.footprintTiles(position, footprint),
    };
    final finder = GridPathfinder(
      columns: columns,
      rows: rows,
      blocked: obstacles,
      allowed: roads,
    );
    return finder
        .findPath(homeTile, finder.interactionTiles(position, footprint))
        ?.last;
  }
}
