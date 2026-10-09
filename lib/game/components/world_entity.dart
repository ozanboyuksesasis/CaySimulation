import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../models/entity_definition.dart';
import '../world/isometric_grid.dart';

class WorldEntity extends PositionComponent {
  WorldEntity({required this.definition, required this.grid, this.sprite})
    : gridPosition = definition.gridPosition,
      super(
        size: Vector2(
          definition.visualSize.width,
          definition.visualSize.height,
        ),
        anchor: definition.anchor,
      ) {
    setGridPosition(gridPosition);
  }
  final EntityDefinition definition;
  final IsometricGrid grid;
  Sprite? sprite;
  GridPoint gridPosition;
  bool selected = false;
  bool previewHidden = false;

  Offset get groundPosition {
    final footprint = definition.footprint;
    // Multi-tile objects stand at the front corner of their footprint.
    return grid.toWorld(
      GridPoint(
        gridPosition.x + (footprint?.columns ?? 1),
        gridPosition.y + (footprint?.rows ?? 1),
      ),
    );
  }

  double get depthY => groundPosition.dy + definition.depthOffset;

  /// Logical occlusion geometry, independent of sprite dimensions.
  Rect get depthFootprint {
    if (definition.kind == EntityKind.character ||
        definition.kind == EntityKind.vehicle) {
      final ground = grid.toGrid(groundPosition);
      return Rect.fromLTWH(ground.x, ground.y, 0, 0);
    }
    return Rect.fromLTWH(
      gridPosition.x,
      gridPosition.y,
      (definition.footprint?.columns ?? 1).toDouble(),
      (definition.footprint?.rows ?? 1).toDouble(),
    );
  }

  void setGridPosition(GridPoint value) {
    gridPosition = value;
    final p = groundPosition + definition.visualOffset;
    position.setValues(p.dx, p.dy);
  }

  Rect get visualBounds => Rect.fromLTWH(
    position.x - size.x * anchor.x,
    position.y - size.y * anchor.y,
    size.x,
    size.y,
  );
  bool hitTest(Offset point) =>
      visualBounds.contains(point) ||
      (definition.footprint != null &&
          grid
              .footprintPath(gridPosition, definition.footprint!)
              .contains(point));

  @override
  void render(Canvas canvas) {
    if (previewHidden) return;
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
          const Radius.circular(10),
        ),
        Paint()
          ..color = const Color(0xFFFFDB7A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (sprite != null) {
      renderSprite(canvas);
    } else {
      renderPlaceholder(canvas);
    }
  }

  void renderSprite(Canvas canvas) {
    // PNG dimensions influence only aspect fit, never footprint/gameplay scale.
    final source = sprite!.srcSize;
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(source.x, source.y),
      Size(size.x, size.y),
    ).destination;
    sprite!.render(
      canvas,
      position: Vector2((size.x - fitted.width) / 2, size.y - fitted.height),
      size: Vector2(fitted.width, fitted.height),
    );
  }

  void renderPlaceholder(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF4E706A),
    );
    final text = TextPainter(
      text: TextSpan(
        text: '${definition.name}\nGeçici görsel',
        style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 17),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);
    text.paint(canvas, Offset(0, (size.y - text.height) / 2));
  }
}
