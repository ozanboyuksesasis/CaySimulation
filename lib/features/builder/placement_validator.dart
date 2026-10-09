import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'build_catalog.dart';
import 'settlement.dart';

class PlacementResult {
  const PlacementResult(this.valid, [this.reason = 'Yerleştirmeye uygun.']);
  final bool valid;
  final String reason;
}

class PlacementValidator {
  PlacementValidator(this.world, {required this.reservedTiles});
  final Settlement world;
  final Set<GridTile> Function() reservedTiles;
  PlacementResult validate(
    BuildCatalogItem item,
    GridPoint position, {
    String? movingId,
  }) {
    final tiles = GridPathfinder.footprintTiles(
      position,
      item.footprint,
    ).toSet();
    if (position.x != position.x.floorToDouble() ||
        position.y != position.y.floorToDouble() ||
        tiles.any(
          (t) =>
              t.x < 0 || t.y < 0 || t.x >= world.columns || t.y >= world.rows,
        )) {
      return const PlacementResult(false, 'Harita sınırının dışında.');
    }
    if (tiles.any(
      (t) => world.occupancy[t] != null && world.occupancy[t] != movingId,
    )) {
      return const PlacementResult(false, 'Başka bir yapıyla çakışıyor.');
    }
    if (item.buildType != BuildType.road &&
        tiles.any(reservedTiles().contains)) {
      return const PlacementResult(false, 'Bu alan geçiş için ayrılmış.');
    }
    if (movingId == null &&
        item.uniqueLimit != null &&
        world.structures.where((e) => e.item.id == item.id).length >=
            item.uniqueLimit!) {
      return const PlacementResult(false, 'Bu yapıdan daha fazla yapılamaz.');
    }
    if (item.requiredRoadAccess &&
        world.roadAccess(position, item.footprint, ignoreId: movingId) ==
            null) {
      return const PlacementResult(false, 'Yol bağlantısı gerekli.');
    }
    return const PlacementResult(true);
  }
}
