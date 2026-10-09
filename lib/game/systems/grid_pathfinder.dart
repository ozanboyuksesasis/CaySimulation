import '../world/isometric_grid.dart';

typedef GridTile = ({int x, int y});

GridTile tileAt(GridPoint point) => (x: point.x.floor(), y: point.y.floor());
GridPoint tileCenter(GridTile tile) => GridPoint(tile.x + 0.5, tile.y + 0.5);

/// Four-neighbour A*. All costs and targets use logical tiles, never pixels.
class GridPathfinder {
  GridPathfinder({
    required this.columns,
    required this.rows,
    required Set<GridTile> blocked,
    Set<GridTile>? allowed,
  }) : blocked = Set.unmodifiable(blocked),
       allowed = allowed == null ? null : Set.unmodifiable(allowed);
  final int columns;
  final int rows;
  Set<GridTile> blocked;
  int revision = 0;

  /// Null means normal worker terrain; vehicles supply an explicit road/access set.
  Set<GridTile>? allowed;
  void updateTopology({
    required Set<GridTile> blocked,
    Set<GridTile>? allowed,
  }) {
    revision++;
    this.blocked = Set.unmodifiable(blocked);
    this.allowed = allowed == null ? null : Set.unmodifiable(allowed);
  }

  bool walkable(GridTile tile) =>
      tile.x >= 0 &&
      tile.y >= 0 &&
      tile.x < columns &&
      tile.y < rows &&
      !blocked.contains(tile) &&
      (allowed == null || allowed!.contains(tile));
  static Iterable<GridTile> footprintTiles(
    GridPoint origin,
    Footprint footprint,
  ) sync* {
    for (var x = origin.x.floor(); x < origin.x + footprint.columns; x++) {
      for (var y = origin.y.floor(); y < origin.y + footprint.rows; y++) {
        yield (x: x, y: y);
      }
    }
  }

  List<GridTile> interactionTiles(GridPoint origin, Footprint footprint) {
    final x = origin.x.floor();
    final y = origin.y.floor();
    final result = <GridTile>[];
    for (var dx = 0; dx < footprint.columns; dx++) {
      result.addAll([
        (x: x + dx, y: y - 1),
        (x: x + dx, y: y + footprint.rows),
      ]);
    }
    for (var dy = 0; dy < footprint.rows; dy++) {
      result.addAll([
        (x: x - 1, y: y + dy),
        (x: x + footprint.columns, y: y + dy),
      ]);
    }
    return result.where(walkable).toList();
  }

  List<GridTile>? findPath(GridTile start, Iterable<GridTile> destinations) {
    final goals = destinations.where(walkable).toSet();
    if (!walkable(start) || goals.isEmpty) return null;
    int heuristic(GridTile tile) => goals
        .map((goal) => (tile.x - goal.x).abs() + (tile.y - goal.y).abs())
        .reduce((a, b) => a < b ? a : b);
    final open = <GridTile>[start];
    final closed = <GridTile>{};
    final costs = <GridTile, int>{start: 0};
    final previous = <GridTile, GridTile>{};
    while (open.isNotEmpty) {
      open.sort((a, b) {
        final f = (costs[a]! + heuristic(a)).compareTo(
          costs[b]! + heuristic(b),
        );
        if (f != 0) return f;
        final y = a.y.compareTo(b.y);
        return y != 0 ? y : a.x.compareTo(b.x);
      });
      final current = open.removeAt(0);
      if (goals.contains(current)) {
        final result = [current];
        while (previous.containsKey(result.last)) {
          result.add(previous[result.last]!);
        }
        return result.reversed.toList();
      }
      closed.add(current);
      for (final next in <GridTile>[
        (x: current.x + 1, y: current.y),
        (x: current.x - 1, y: current.y),
        (x: current.x, y: current.y + 1),
        (x: current.x, y: current.y - 1),
      ]) {
        if (!walkable(next) || closed.contains(next)) continue;
        final cost = costs[current]! + 1;
        if (cost < (costs[next] ?? 1 << 30)) {
          costs[next] = cost;
          previous[next] = current;
          if (!open.contains(next)) open.add(next);
        }
      }
    }
    return null;
  }
}
