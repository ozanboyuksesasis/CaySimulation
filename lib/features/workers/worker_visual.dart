import 'dart:ui';

import '../../game/world/isometric_grid.dart';

enum WorkerVisualDirection { se, sw, ne, nw }

enum WorkerVisualState { idle, walk, harvest }

class WorkerFrameDefinition {
  const WorkerFrameDefinition(this.asset, this.bodyTop, this.feetX, this.feetY);
  final String asset;
  final double bodyTop, feetX, feetY;
  double scaleFor(double visualHeight) => visualHeight / (feetY - bodyTop);
}

abstract final class WorkerVisualConfig {
  static const frameDuration = Duration(milliseconds: 140);
}

/// Presentation only: reads positions; never writes to workers or jobs.
class WorkerDirectionalVisual {
  WorkerDirectionalVisual(
    GridPoint initial, {
    required this.frames,
    required this.walkCycle,
  }) : _previous = initial;
  final Map<String, WorkerFrameDefinition> frames;
  final List<String> walkCycle;
  GridPoint _previous;
  WorkerVisualDirection direction = WorkerVisualDirection.se;
  WorkerVisualState state = WorkerVisualState.idle;
  double _elapsed = 0;
  int get frameIndex => state != WorkerVisualState.walk
      ? 1
      : (_elapsed * 1000000 / WorkerVisualConfig.frameDuration.inMicroseconds)
                .floor() %
            walkCycle.length;
  String get frameName =>
      state != WorkerVisualState.walk ? 'IDLE' : walkCycle[frameIndex];
  WorkerFrameDefinition get frame =>
      frames['${direction.name.toUpperCase()}_$frameName']!;

  static WorkerVisualDirection directionFor(
    GridPoint delta,
    IsometricGrid grid,
  ) {
    final Offset projected =
        grid.toWorld(delta) - grid.toWorld(const GridPoint(0, 0));
    if (projected.dy >= 0) {
      return projected.dx >= 0
          ? WorkerVisualDirection.se
          : WorkerVisualDirection.sw;
    }
    return projected.dx >= 0
        ? WorkerVisualDirection.ne
        : WorkerVisualDirection.nw;
  }

  void faceTarget(GridPoint position, GridPoint target, IsometricGrid grid) {
    final delta = GridPoint(target.x - position.x, target.y - position.y);
    if (delta.x.abs() + delta.y.abs() > 1e-9) {
      direction = directionFor(delta, grid);
    }
    state = WorkerVisualState.idle;
    _elapsed = 0;
  }

  void update(
    GridPoint position, {
    required bool moving,
    required double dt,
    required IsometricGrid grid,
  }) {
    final delta = GridPoint(position.x - _previous.x, position.y - _previous.y);
    _previous = position;
    final changedPosition = delta.x.abs() + delta.y.abs() > 1e-9;
    final next = changedPosition ? directionFor(delta, grid) : direction;
    if (!moving || !changedPosition) {
      direction = next;
      state = WorkerVisualState.idle;
      _elapsed = 0;
      return;
    }
    if (state != WorkerVisualState.walk || next != direction) {
      _elapsed = 0;
    } else {
      _elapsed += dt;
    }
    direction = next;
    state = WorkerVisualState.walk;
  }
}
