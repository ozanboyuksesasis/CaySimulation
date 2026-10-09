import 'dart:ui';

import 'package:flame/components.dart';

import '../cay_game.dart';
import '../world/isometric_grid.dart';
import 'terrain_component.dart';
import '../systems/grid_pathfinder.dart';
import '../world/road_tiles.dart';

class GridDebugComponent extends Component {
  GridDebugComponent(this.game) : super(priority: 1000000);
  final CayGame game;
  @override
  void render(Canvas canvas) {
    final grid = game.grid;
    if (game.showGrid.value) {
      for (final tile in game.settlement.roads) {
        canvas.drawPath(
          grid.footprintPath(
            GridPoint(tile.x.toDouble(), tile.y.toDouble()),
            const Footprint(1, 1),
          ),
          Paint()..color = const Color(0x303EA9FF),
        );
      }
      final vehicleRoute = [
        grid.toWorld(game.vehicle.gridPosition),
        ...game.transport.remainingPath.map(
          (tile) => grid.toWorld(tileCenter(tile)),
        ),
      ];
      if (vehicleRoute.length > 1) {
        canvas.drawPath(
          Path()..addPolygon(vehicleRoute, false),
          Paint()
            ..color = const Color(0xFF52BFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      for (final entry in {
        truckHomeTile: 'Garaj',
        if (game.activeCollectionCenter != null)
          game.collectionCenter.deliveryInteractionTile: 'Teslim',
        if (game.activeFactory != null)
          game.factory.deliveryInteractionTile: 'Fabrika teslim',
        for (final tile in game.transport.pickups.values) tile: 'Yükleme',
      }.entries) {
        final point = grid.toWorld(tileCenter(entry.key));
        canvas.drawCircle(point, 9, Paint()..color = const Color(0xFF52BFFF));
        paintLabel(canvas, entry.value, point.translate(0, -15), size: 12);
      }
      for (final tile in game.pathfinder.blocked) {
        canvas.drawPath(
          grid.footprintPath(
            GridPoint(tile.x.toDouble(), tile.y.toDouble()),
            const Footprint(1, 1),
          ),
          Paint()..color = const Color(0x35EF796A),
        );
      }
      for (final worker in game.workforce.workers) {
        final route = [
          grid.toWorld(worker.gridPosition),
          ...game.jobs
              .pathFor(worker)
              .map((tile) => grid.toWorld(tileCenter(tile))),
        ];
        if (route.length > 1) {
          canvas.drawPath(
            Path()..addPolygon(route, false),
            Paint()
              ..color = const Color(0xFFFFD879)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        final target = game.jobs.jobForWorker(worker)?.targetPosition;
        if (target != null) {
          canvas.drawCircle(
            grid.toWorld(tileCenter(target)),
            10,
            Paint()..color = const Color(0xFF7CE4DF),
          );
        }
      }
      final line = Paint()
        ..color = const Color(0x707CE4DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var x = 0; x < grid.columns; x++) {
        for (var y = 0; y < grid.rows; y++) {
          canvas.drawPath(
            grid.footprintPath(
              GridPoint(x.toDouble(), y.toDouble()),
              const Footprint(1, 1),
            ),
            line,
          );
          paintLabel(
            canvas,
            '$x,$y',
            grid.toWorld(GridPoint(x + 0.5, y + 0.5)),
            size: 11,
          );
        }
      }
    }
    for (final entity in game.entities) {
      if (!game.showGrid.value || entity.previewHidden) continue;
      final footprint = entity.definition.footprint;
      if (footprint == null) continue;
      final path = grid.footprintPath(entity.gridPosition, footprint);
      canvas.drawPath(
        path,
        Paint()
          ..color = entity.selected
              ? const Color(0x35FFD879)
              : const Color(0x207CE4DF),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = entity.selected
              ? const Color(0xFFFFD879)
              : const Color(0xFF7CE4DF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final tile = game.selectedTile.value;
    if (game.showGrid.value && tile != null) {
      canvas.drawPath(
        grid.footprintPath(tile, const Footprint(1, 1)),
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}
