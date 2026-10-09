import 'dart:ui';

import '../models/game_config.dart';

class GridPoint {
  const GridPoint(this.x, this.y);
  final double x;
  final double y;
  GridPoint get tile => GridPoint(x.floorToDouble(), y.floorToDouble());
}

class Footprint {
  const Footprint(this.columns, this.rows)
    : assert(columns > 0),
      assert(rows > 0);
  final int columns;
  final int rows;
}

class IsometricGrid {
  const IsometricGrid({
    this.tileWidth = GameConfig.tileWidth,
    this.tileHeight = GameConfig.tileHeight,
    this.columns = GameConfig.mapColumns,
    this.rows = GameConfig.mapRows,
  }) : assert(tileWidth > 0),
       assert(tileHeight > 0),
       assert(columns > 0),
       assert(rows > 0);
  final double tileWidth;
  final double tileHeight;
  final int columns;
  final int rows;

  Offset toWorld(GridPoint p) =>
      Offset((p.x - p.y) * tileWidth / 2, (p.x + p.y) * tileHeight / 2);
  GridPoint toGrid(Offset p) => GridPoint(
    p.dx / tileWidth + p.dy / tileHeight,
    p.dy / tileHeight - p.dx / tileWidth,
  );
  bool contains(GridPoint p) =>
      p.x >= 0 && p.y >= 0 && p.x < columns && p.y < rows;
  Rect get bounds => Rect.fromLTRB(
    -rows * tileWidth / 2,
    0,
    columns * tileWidth / 2,
    (columns + rows) * tileHeight / 2,
  );
  Path footprintPath(GridPoint p, Footprint footprint) {
    final corners = [
      p,
      GridPoint(p.x + footprint.columns, p.y),
      GridPoint(p.x + footprint.columns, p.y + footprint.rows),
      GridPoint(p.x, p.y + footprint.rows),
    ].map(toWorld).toList();
    return Path()..addPolygon(corners, true);
  }
}
