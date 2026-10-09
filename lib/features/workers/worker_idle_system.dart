import 'dart:math' as math;

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'worker.dart';
import 'worker_config.dart';

/// Short deterministic walks on free pedestrian tiles. Jobs always preempt them.
class WorkerIdleSystem {
  WorkerIdleSystem(this.pathfinder, {math.Random? random})
    : random = random ?? math.Random(8411);
  final math.Random random;
  final GridPathfinder pathfinder;
  final Map<String, Duration> _wait = {};
  final Map<String, GridTile> _targets = {};
  final Map<String, GridTile> _anchors = {};
  final Map<String, Duration> _pause = {};
  final Map<String, GridTile> _previousTile = {};
  void cancel(Worker w) {
    _wait.remove(w.id);
    _pause.remove(w.id);
    _targets.remove(w.id);
    _anchors.remove(w.id);
    w.isStrolling = false;
  }

  void advance(Duration dt, List<Worker> workers, Set<GridTile> workTiles) {
    for (final w in workers) {
      if (w.state != WorkerState.idle || w.assignedJobId != null) {
        cancel(w);
        continue;
      }
      final occupied = {
        ...workTiles,
        for (final other in workers)
          if (other != w) tileAt(other.gridPosition),
        for (final entry in _targets.entries)
          if (entry.key != w.id) entry.value,
      };
      var target = _targets[w.id];
      if (target != null &&
          (!pathfinder.walkable(target) || occupied.contains(target))) {
        _targets.remove(w.id);
        target = null;
        w.isStrolling = false;
      }
      if (target == null) {
        final wait = (_wait[w.id] ?? Duration.zero) + dt;
        _wait[w.id] = wait;
        // Vacate a newly reserved workplace without waiting for the idle pause.
        final pause = _pause.putIfAbsent(
          w.id,
          () => Duration(
            milliseconds:
                WorkerConfig.idlePauseMinMs +
                random.nextInt(
                  WorkerConfig.idlePauseMaxMs - WorkerConfig.idlePauseMinMs + 1,
                ),
          ),
        );
        if (wait < pause && !workTiles.contains(tileAt(w.gridPosition))) {
          continue;
        }
        _wait[w.id] = Duration.zero;
        _pause.remove(w.id);
        final current = tileAt(w.gridPosition);
        final anchor = _anchors.putIfAbsent(w.id, () => current);
        final candidates = [
          (x: current.x + 1, y: current.y),
          (x: current.x, y: current.y + 1),
          (x: current.x - 1, y: current.y),
          (x: current.x, y: current.y - 1),
        ];
        candidates.shuffle(random);
        // Prefer exploring over immediate backtracking when another tile is free.
        final previous = _previousTile[w.id];
        candidates.sort(
          (a, b) => (a == previous ? 1 : 0).compareTo(b == previous ? 1 : 0),
        );
        for (var i = 0; i < candidates.length; i++) {
          final t = candidates[i];
          if (pathfinder.walkable(t) &&
              !occupied.contains(t) &&
              (t.x - anchor.x).abs() + (t.y - anchor.y).abs() <=
                  WorkerConfig.idleRadius) {
            _targets[w.id] = t;
            _previousTile[w.id] = current;
            w.isStrolling = true;
            break;
          }
        }
        continue;
      }
      final p = tileCenter(target);
      final dx = p.x - w.gridPosition.x, dy = p.y - w.gridPosition.y;
      final distance = math.sqrt(dx * dx + dy * dy);
      final step =
          w.movementSpeed * dt.inMicroseconds / Duration.microsecondsPerSecond;
      if (distance <= step) {
        w.gridPosition = p;
        _targets.remove(w.id);
        w.isStrolling = false;
      } else {
        w.gridPosition = GridPoint(
          w.gridPosition.x + dx * step / distance,
          w.gridPosition.y + dy * step / distance,
        );
        w.isStrolling = true;
      }
    }
  }
}
