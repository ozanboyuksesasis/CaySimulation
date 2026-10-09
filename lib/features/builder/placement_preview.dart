import 'dart:ui';

import 'package:flame/components.dart';

import '../../game/cay_game.dart';
import '../../game/world/isometric_grid.dart';
import '../plantation/field_visuals.dart';
import 'build_catalog.dart';

class PlacementPreview extends Component {
  PlacementPreview(this.game) : super(priority: 2000000);
  final CayGame game;
  String? _lastMovingId;
  double _pulse = 0;
  @override
  void update(double dt) {
    final id = game.builder.movingEntityId;
    if (id != _lastMovingId) {
      _lastMovingId = id;
      _pulse = id == null ? 0 : 1;
    }
    _pulse = (_pulse - dt / .3).clamp(0.0, 1.0);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final builder = game.builder;
    if (!builder.isPlacing) return;
    final item = builder.selectedCatalogItem!;
    final point = builder.previewGridPosition;
    final color = builder.validationResult.valid
        ? const Color(0xFF65E18F)
        : const Color(0xFFFF6666);
    final path = game.grid.footprintPath(point, item.footprint);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.5));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + 3 * _pulse,
    );
    if (item.buildType == BuildType.road) return;
    var asset = item.assetPath;
    final fields = game.plantation.fields.where(
      (f) => f.id == builder.movingEntityId,
    );
    if (fields.isNotEmpty) asset = fieldAssets[fields.single.state]!;
    final sprite = game.assetCatalog.sprite(asset);
    if (sprite == null) return;
    final ground = game.grid.toWorld(
      GridPoint(
        point.x + item.footprint.columns,
        point.y + item.footprint.rows,
      ),
    );
    final scale =
        (item.visualWidth / sprite.srcSize.x) <
            (item.visualHeight / sprite.srcSize.y)
        ? item.visualWidth / sprite.srcSize.x
        : item.visualHeight / sprite.srcSize.y;
    final width = sprite.srcSize.x * scale, height = sprite.srcSize.y * scale;
    sprite.render(
      canvas,
      position: Vector2(ground.dx - width / 2, ground.dy - height),
      size: Vector2(width, height),
      overridePaint: Paint()..color = const Color(0xA6FFFFFF),
    );
    // Keep the validity outline visible even when the master PNG has a background.
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}
