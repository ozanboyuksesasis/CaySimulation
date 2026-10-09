import '../models/game_config.dart';
import '../systems/grid_pathfinder.dart';

const truckHomeTile = (x: 10, y: 7);
const collectionDeliveryTile = (x: 10, y: 4);
const factoryDeliveryTile = (x: 12, y: 13);
const fieldPickupTiles = <String, GridTile>{
  'field-01': (x: 4, y: 3),
  'field-02': (x: 7, y: 3),
  'field-03': (x: 4, y: 6),
};

/// The same logical roads drive terrain rendering and vehicle traversal.
final Set<GridTile> roadTiles = Set.unmodifiable({
  for (var x = 0; x < GameConfig.mapColumns; x++)
    for (var y = 0; y < GameConfig.mapRows; y++)
      if (x == 8 ||
          x == 9 ||
          y == 7 ||
          y == 8 ||
          (y == 4 && x >= 4 && x <= 10) ||
          (x == 4 && y >= 3 && y <= 7) ||
          (x == 12 && y >= 9 && y <= 13) ||
          (x == 7 && y == 3))
        (x: x, y: y),
});
bool isRoad(int x, int y) => roadTiles.contains((x: x, y: y));
