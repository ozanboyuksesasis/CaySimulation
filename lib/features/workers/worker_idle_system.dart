import 'dart:math' as math;

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'worker.dart';
import 'worker_config.dart';

/// Short deterministic walks on free pedestrian tiles. Jobs always preempt them.
class WorkerIdleSystem {
  WorkerIdleSystem(this.pathfinder);
  final GridPathfinder pathfinder;
  final Map<String, Duration> _wait = {};
  final Map<String, GridTile> _targets = {};
  final Map<String, GridTile> _anchors = {};
  final Map<String, int> _turns = {};
  void cancel(Worker w) {
    _wait.remove(w.id);
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
        if (wait < WorkerConfig.idlePause &&
            !workTiles.contains(tileAt(w.gridPosition))) {
          continue;
        }
        _wait[w.id] = Duration.zero;
        final current = tileAt(w.gridPosition);
        final anchor = _anchors.putIfAbsent(w.id, () => current);
        final candidates = [
          (x: current.x + 1, y: current.y),
          (x: current.x, y: current.y + 1),
          (x: current.x - 1, y: current.y),
          (x: current.x, y: current.y - 1),
        ];
        final turn = _turns[w.id] ?? 0;
        for (var i = 0; i < candidates.length; i++) {
          final t = candidates[(turn + i) % candidates.length];
          if (pathfinder.walkable(t) &&
              !occupied.contains(t) &&
              (t.x - anchor.x).abs() + (t.y - anchor.y).abs() <=
                  WorkerConfig.idleRadius) {
            _targets[w.id] = t;
            _turns[w.id] = turn + i + 1;
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
