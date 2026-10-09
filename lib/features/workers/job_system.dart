import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import '../plantation/plantation_system.dart';
import '../plantation/tea_field.dart';
import 'harvest_job.dart';
import 'worker.dart';
import 'worker_idle_system.dart';
import 'worker_config.dart';

/// FIFO jobs and deterministic workers share one plantation clock.
class JobSystem extends ChangeNotifier {
  JobSystem({
    Worker? worker,
    List<Worker> Function()? workers,
    required this.plantation,
    required this.pathfinder,
    this.idleMovementEnabled = true,
  }) : _workers = workers ?? (() => worker == null ? [] : [worker]) {
    for (final w in this.workers) {
      if (!pathfinder.walkable(tileAt(w.gridPosition))) {
        throw ArgumentError('İşçi yürünebilir bir karoda başlamalı.');
      }
    }
  }
  final List<Worker> Function() _workers;
  List<Worker> get workers => _workers();
  Worker get worker => workers.first;
  final PlantationSystem plantation;
  void Function(HarvestJob job, Worker worker)? onHarvestCompleted;
  final GridPathfinder pathfinder;
  final bool idleMovementEnabled;
  late final idle = WorkerIdleSystem(pathfinder);
  Set<GridTile> get reservedWorkTiles => {
    for (final j in _jobs)
      if (j.isActive && j.targetPosition != null) j.targetPosition!,
  };
  final List<HarvestJob> _jobs = [];
  final Map<String, List<GridTile>> _paths = {};
  final Map<String, int> _lastAssignment = {};
  int _assignmentSequence = 0;
  List<HarvestJob> get jobs => List.unmodifiable(_jobs);
  List<GridTile> pathFor(Worker w) => List.unmodifiable(_paths[w.id] ?? []);
  List<GridTile> get remainingPath => [for (final w in workers) ...pathFor(w)];
  int get queuedCount =>
      _jobs.where((j) => j.status == JobStatus.queued).length;
  HarvestJob? jobForWorker(Worker w) {
    for (final j in _jobs) {
      if (j.id == w.assignedJobId) return j;
    }
    return null;
  }

  HarvestJob? get currentJob =>
      workers.isEmpty ? null : jobForWorker(workers.first);
  Worker? assignedWorker(HarvestJob? job) {
    for (final w in workers) {
      if (w.id == job?.assignedWorkerId) return w;
    }
    return null;
  }

  HarvestJob? jobForField(String id) {
    for (final j in _jobs.reversed) {
      if (j.fieldId == id) return j;
    }
    return null;
  }

  TeaField _field(HarvestJob j) =>
      plantation.fields.singleWhere((f) => f.id == j.fieldId);
  String? requestFailure;
  HarvestJob? requestHarvest(TeaField field) {
    requestFailure = null;
    if (!plantation.fields.contains(field) ||
        field.state != TeaFieldState.ready) {
      return null;
    }
    final previous = jobForField(field.id);
    if (previous != null && previous.isActive) return previous;
    if (!workers.any((w) => w.canHarvest)) {
      requestFailure = 'Hasat yapabilecek ekipmanlı işçi yok.';
      return null;
    }
    final job = HarvestJob(
      id: 'harvest-${_jobs.length + 1}',
      createdAt: plantation.simulationTime,
      fieldId: field.id,
    );
    _jobs.add(job);
    _assign();
    _changed();
    return job;
  }

  void _release(Worker w) {
    w.state = WorkerState.idle;
    w.assignedJobId = null;
    w.workFacingTarget = null;
    idle.cancel(w);
    _paths.remove(w.id);
  }

  void _fail(Worker w, HarvestJob j, String reason) {
    j.status = JobStatus.failed;
    j.failureMessage = reason;
    _release(w);
  }

  void _assign() {
    for (final job in _jobs.where((j) => j.status == JobStatus.queued)) {
      final available = workers
          .where((w) => w.state == WorkerState.idle && w.canHarvest)
          .toList();
      if (available.isEmpty) return;
      final field = _field(job);
      if (field.state != TeaFieldState.ready) {
        job.status = JobStatus.failed;
        job.failureMessage = 'Tarla artık hasada hazır değil.';
        continue;
      }
      var assigned = false;
      final routes = {
        for (final w in available)
          w.id: pathfinder.findPath(
            tileAt(w.gridPosition),
            pathfinder
                .interactionTiles(field.gridPosition, field.footprint)
                .where(
                  (t) =>
                      !reservedWorkTiles.contains(t) &&
                      !workers.any(
                        (other) =>
                            other != w && tileAt(other.gridPosition) == t,
                      ),
                )
                .toSet(),
          ),
      };
      available.sort((a, b) {
        final reachable = (routes[a.id] == null ? 1 : 0).compareTo(
          routes[b.id] == null ? 1 : 0,
        );
        if (reachable != 0) return reachable;
        final waiting = (_lastAssignment[a.id] ?? 0).compareTo(
          _lastAssignment[b.id] ?? 0,
        );
        if (waiting != 0) return waiting;
        final distance = (routes[a.id]?.length ?? 100000).compareTo(
          routes[b.id]?.length ?? 100000,
        );
        return distance != 0 ? distance : a.id.compareTo(b.id);
      });
      for (final w in available) {
        final path = routes[w.id];
        if (path == null) continue;
        job.status = JobStatus.assigned;
        _lastAssignment[w.id] = ++_assignmentSequence;
        job.assignedWorkerId = w.id;
        job.targetPosition = path.last;
        job.harvestDuration = w.harvestDuration;
        idle.cancel(w);
        w.assignedJobId = job.id;
        w.state = WorkerState.movingToJob;
        _paths[w.id] = List.of(path);
        assigned = true;
        break;
      }
      if (!assigned) {
        // Occupied interaction points are temporary; keep reachable work queued.
        if (available.any(
          (w) =>
              pathfinder.findPath(
                tileAt(w.gridPosition),
                pathfinder.interactionTiles(
                  field.gridPosition,
                  field.footprint,
                ),
              ) !=
              null,
        )) {
          continue;
        }
        // An equipped colleague can reach it after finishing their current job.
        if (workers.any(
          (w) =>
              w.canHarvest &&
              w.state != WorkerState.idle &&
              pathfinder.findPath(
                    tileAt(w.gridPosition),
                    pathfinder.interactionTiles(
                      field.gridPosition,
                      field.footprint,
                    ),
                  ) !=
                  null,
        )) {
          continue;
        }
        job.status = JobStatus.failed;
        job.failureMessage = 'Tarlaya ulaşılacak yol bulunamadı.';
      }
    }
  }

  double progress(HarvestJob j) =>
      (j.worked.inMicroseconds / j.harvestDuration.inMicroseconds).clamp(
        0.0,
        1.0,
      );
  int remainingSeconds(HarvestJob j) =>
      ((j.harvestDuration - j.worked).inMicroseconds /
              Duration.microsecondsPerSecond)
          .ceil()
          .clamp(0, 999);
  double _distance(Worker w, GridTile t) {
    final p = tileCenter(t);
    return math.sqrt(
      math.pow(p.x - w.gridPosition.x, 2) + math.pow(p.y - w.gridPosition.y, 2),
    );
  }

  Duration? _next(Worker w) {
    final j = jobForWorker(w);
    if (j == null) return null;
    if (w.state == WorkerState.working) return j.harvestDuration - j.worked;
    for (final t in pathFor(w)) {
      final d = _distance(w, t);
      if (d > 1e-9) {
        return Duration(
          microseconds: (d / w.movementSpeed * Duration.microsecondsPerSecond)
              .ceil(),
        );
      }
    }
    return const Duration(microseconds: 1);
  }

  Duration? get timeToNextEvent {
    Duration? result =
        idleMovementEnabled && workers.any((w) => w.state == WorkerState.idle)
        ? WorkerConfig.idleStep
        : null;
    for (final w in workers) {
      final next = _next(w);
      if (next != null && (result == null || next < result)) result = next;
    }
    return result;
  }

  void _normalize() {
    for (final w in workers) {
      final job = jobForWorker(w);
      if (job == null) continue;
      if (_field(job).state != TeaFieldState.ready) {
        _fail(w, job, 'Tarla artık hasada hazır değil.');
        continue;
      }
      if (w.state == WorkerState.movingToJob) {
        final path = _paths[w.id]!;
        while (path.isNotEmpty && _distance(w, path.first) < 1e-9) {
          path.removeAt(0);
        }
        if (path.isEmpty) {
          w.state = WorkerState.working;
          final field = _field(job);
          w.workFacingTarget = GridPoint(
            field.gridPosition.x + field.footprint.columns / 2,
            field.gridPosition.y + field.footprint.rows / 2,
          );
          job.status = JobStatus.inProgress;
        }
      }
    }
  }

  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Süre negatif olamaz.');
    var left = elapsed;
    _assign();
    while (left > Duration.zero) {
      _normalize();
      _assign();
      _normalize();
      var step = left;
      final boundary = timeToNextEvent;
      if (boundary != null && boundary > Duration.zero && boundary < step) {
        step = boundary;
      }
      if (idleMovementEnabled) {
        idle.advance(step, workers, reservedWorkTiles);
      }
      plantation.advance(step);
      for (final w in workers) {
        final job = jobForWorker(w);
        if (job == null) continue;
        if (w.state == WorkerState.movingToJob) {
          if (!pathfinder.walkable(_paths[w.id]!.first)) {
            _fail(w, job, 'Tarlaya ulaşılacak yol bulunamadı.');
            continue;
          }
          final p = tileCenter(_paths[w.id]!.first);
          final d = _distance(w, _paths[w.id]!.first);
          final ratio =
              (w.movementSpeed *
                      step.inMicroseconds /
                      Duration.microsecondsPerSecond /
                      d)
                  .clamp(0.0, 1.0);
          w.gridPosition = GridPoint(
            w.gridPosition.x + (p.x - w.gridPosition.x) * ratio,
            w.gridPosition.y + (p.y - w.gridPosition.y) * ratio,
          );
        } else if (w.state == WorkerState.working) {
          job.worked += step;
          if (job.worked >= job.harvestDuration) {
            if (_field(job).completeHarvest(plantation.simulationTime)) {
              job.status = JobStatus.completed;
              w.rewardHarvest(job.id);
              onHarvestCompleted?.call(job, w);
              _release(w);
            } else {
              _fail(w, job, 'Hasat tamamlanamadı.');
            }
          }
        } else {
          _fail(w, job, 'İşçi göreve devam edemedi.');
        }
      }
      left -= step;
      _normalize();
      _assign();
    }
    _changed();
  }

  void _changed() {
    for (final w in workers) {
      w.changed();
    }
    notifyListeners();
  }
}
