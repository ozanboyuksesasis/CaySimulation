import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../world/isometric_grid.dart';
import '../world/prototype_map.dart';
import '../../features/builder/settlement.dart';

void paintLabel(
  Canvas canvas,
  String text,
  Offset position, {
  double size = 13,
  Color color = const Color(0xFFE3EDD7),
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    position - Offset(painter.width / 2, painter.height / 2),
  );
}

class TerrainComponent extends Component {
  TerrainComponent(this.grid, {this.settlement, this.devMap = true})
    : super(priority: -100);
  final IsometricGrid grid;
  final Settlement? settlement;
  final bool devMap;
  void invalidate() {
    _picture?.dispose();
    _picture = null;
  }

  Picture? _picture;
  @override
  void render(Canvas canvas) {
    _picture ??= _build();
    canvas.drawPicture(_picture!);
  }

  Picture _build() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (var x = 0; x < grid.columns; x++) {
      for (var y = 0; y < grid.rows; y++) {
        var color = (x + y).isEven
            ? const Color(0xFF64885B)
            : const Color(0xFF688D5F);
        for (final zone in devMap ? prototypeZones : <MapZone>[]) {
          if (zone.contains(x, y)) color = zone.color;
        }
        if (settlement?.roads.contains((x: x, y: y)) ?? isRoad(x, y)) {
          color = const Color(0xFFB0A185);
        }
        final path = grid.footprintPath(
          GridPoint(x.toDouble(), y.toDouble()),
          const Footprint(1, 1),
        );
        canvas.drawPath(path, Paint()..color = color);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0x18608048)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
      }
    }
    for (final zone in devMap ? prototypeZones : <MapZone>[]) {
      paintLabel(
        canvas,
        zone.name,
        grid.toWorld(
          GridPoint(
            zone.origin.x + zone.footprint.columns / 2,
            zone.origin.y + 0.4,
          ),
        ),
        size: 16,
      );
    }
    return recorder.endRecording();
  }

  @override
  void onRemove() {
    _picture?.dispose();
    super.onRemove();
  }
}
