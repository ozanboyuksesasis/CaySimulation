import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../models/game_config.dart';
import '../world/isometric_grid.dart';

class ManagementCamera {
  ManagementCamera(this.camera, this.grid, {this.initialFocus});
  final GridPoint? initialFocus;
  final CameraComponent camera;
  final IsometricGrid grid;
  Size viewport = Size.zero;
  double get zoom => camera.viewfinder.zoom;
  Offset get center =>
      Offset(camera.viewfinder.position.x, camera.viewfinder.position.y);
  void resize(Size value) {
    viewport = value;
    clamp();
  }

  void reset() {
    camera.viewfinder.zoom = GameConfig.initialZoom;
    final focus = initialFocus == null
        ? grid.bounds.center
        : grid.toWorld(initialFocus!);
    camera.viewfinder.position = Vector2(focus.dx, focus.dy);
    clamp();
  }

  Offset screenToWorld(Offset screen) =>
      center +
      (screen - Offset(viewport.width / 2, viewport.height / 2)) / zoom;
  void pan(Offset delta) {
    camera.viewfinder.position =
        camera.viewfinder.position - Vector2(delta.dx / zoom, delta.dy / zoom);
    clamp();
  }

  void zoomAt(double target, Offset focalPoint) {
    final before = screenToWorld(focalPoint);
    camera.viewfinder.zoom = target.clamp(
      GameConfig.minZoom,
      GameConfig.maxZoom,
    );
    final correction = before - screenToWorld(focalPoint);
    camera.viewfinder.position =
        camera.viewfinder.position + Vector2(correction.dx, correction.dy);
    clamp();
  }

  void wheel(double delta, Offset point) =>
      zoomAt(zoom * math.exp(-delta * 0.0015), point);
  void clamp() {
    if (viewport.isEmpty) return;
    final bounds = grid.bounds;
    double axis(double value, double lo, double hi, double halfView) {
      if (halfView * 2 >= hi - lo) return (lo + hi) / 2;
      return value.clamp(lo + halfView, hi - halfView);
    }

    var p = Offset(
      axis(center.dx, bounds.left, bounds.right, viewport.width / (2 * zoom)),
      axis(center.dy, bounds.top, bounds.bottom, viewport.height / (2 * zoom)),
    );
    // Keep the camera center inside the diamond too, not just its bounding box.
    final logical = grid.toGrid(p);
    p = grid.toWorld(
      GridPoint(
        logical.x.clamp(0, grid.columns.toDouble()),
        logical.y.clamp(0, grid.rows.toDouble()),
      ),
    );
    camera.viewfinder.position = Vector2(p.dx, p.dy);
  }
}
