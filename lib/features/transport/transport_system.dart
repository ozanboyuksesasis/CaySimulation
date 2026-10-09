import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import '../buildings/tea_collection_center.dart';
import '../buildings/tea_factory.dart';
import '../plantation/plantation_system.dart';
import '../plantation/tea_field.dart';
import 'transport_config.dart';
import 'transport_job.dart';
import 'transport_vehicle.dart';

/// Executes logistics on the world's clock; never advances crop time itself.
class TransportSystem extends ChangeNotifier {
  TransportSystem({
    required this.vehicle,
    required this.plantation,
    TeaCollectionCenter? center,
    this.factory,
    required this.pathfinder,
    required Map<String, GridTile> pickups,
  }) : collectionCenter = center,
       pickups = Map.of(pickups) {
    if (!pathfinder.walkable(vehicle.homePosition)) {
      throw ArgumentError('Kamyon yürünebilir bir yol karosunda başlamalı.');
    }
  }
  final TransportVehicle vehicle;
  void Function(TransportJob job)? onDeliveryCompleted;
  final PlantationSystem plantation;
  TeaCollectionCenter? collectionCenter;
  TeaCollectionCenter get center => collectionCenter!;
  bool get hasCollectionCenter => collectionCenter != null;
  TeaFactory? factory;
  GridPathfinder pathfinder;
  final Map<String, GridTile> pickups;
  final List<TransportJob> _jobs = [];
  List<TransportJob> get jobs => List.unmodifiable(_jobs);
  List<GridTile> _path = [];
  int _pathIndex = 0;
  List<GridTile> get remainingPath => List.unmodifiable(_path.skip(_pathIndex));
  String? failureMessage;
  int get queuedCount =>
      _jobs.where((j) => j.status == JobStatus.queued).length;
  int get totalTeaKg =>
      plantation.fields.fold(0, (sum, f) => sum + f.harvestedStockKg) +
      vehicle.cargoKg +
      (collectionCenter?.receivedTeaKg ?? 0) +
      (factory?.rawTeaKg ?? 0) +
      (factory?.processingInputKg ?? 0);
  // Only raw tea is conserved by transport. Production converts its batch to dry tea.
  int get totalRawTeaKg => totalTeaKg;
  int get queuedShipmentCount => _jobs
      .where((j) => j.isFactoryShipment && j.status == JobStatus.queued)
      .length;
  TransportJob? get latestShipment {
    for (final job in _jobs.reversed) {
      if (job.isFactoryShipment) return job;
    }
    return null;
  }

  bool get shipmentPending {
    final job = latestShipment;
    return job != null &&
        (job.isActive ||
            (vehicle.assignedJobId == job.id && vehicle.cargoKg > 0));
  }

  TransportJob? requestFactoryShipment() {
    if (!hasCollectionCenter || factory == null || center.receivedTeaKg <= 0) {
      return null;
    }
    if (shipmentPending) return latestShipment;
    final job = TransportJob.factoryShipment(
      id: 'transport-${_jobs.length + 1}',
      createdAt: plantation.simulationTime,
      sourceId: center.id,
      sourcePosition: center.deliveryInteractionTile,
      destinationId: factory!.id,
      amountKg: math.min(center.receivedTeaKg, vehicle.capacityKg),
    );
    _jobs.add(job);
    _assignNext();
    _publish();
    return job;
  }

  TransportJob? get currentJob {
    for (final job in _jobs) {
      if (job.id == vehicle.assignedJobId) return job;
    }
    return null;
  }

  TransportJob? jobForField(String id) {
    for (final job in _jobs.reversed) {
      if (job.fieldId == id) return job;
    }
    return null;
  }

  TeaField _field(TransportJob job) =>
      plantation.fields.singleWhere((f) => f.id == job.fieldId);
  bool _adjacent(TeaField field, GridTile tile) => pathfinder
      .interactionTiles(field.gridPosition, field.footprint)
      .contains(tile);

  TransportJob? requestTransport(TeaField field) {
    if (!hasCollectionCenter) return null;
    if (!plantation.fields.contains(field) || field.harvestedStockKg <= 0) {
      return null;
    }
    final previous = jobForField(field.id);
    if (previous != null &&
        (previous.isActive ||
            (vehicle.assignedJobId == previous.id && vehicle.cargoKg > 0))) {
      return previous;
    }
    final pickup = pickups[field.id];
    if (pickup == null) {
      failureMessage = 'Tarla için yükleme noktası tanımlı değil.';
      notifyListeners();
      return null;
    }
    final job = TransportJob(
      id: 'transport-${_jobs.length + 1}',
      createdAt: plantation.simulationTime,
      fieldId: field.id,
      sourcePosition: pickup,
      destinationId: center.id,
    );
    _jobs.add(job);
    _assignNext();
    _publish();
    return job;
  }

  List<String> validateRoutes() {
    final issues = <String>[];
    if (!hasCollectionCenter) return issues;
    for (final field in plantation.fields) {
      final pickup = pickups[field.id];
      if (pickup == null ||
          !_adjacent(field, pickup) ||
          pathfinder.findPath(vehicle.homePosition, [pickup]) == null ||
          !_validDelivery ||
          pathfinder.findPath(pickup, [center.deliveryInteractionTile]) ==
              null) {
        issues.add('Tarla ${field.id} için araç yolu bulunamadı.');
      }
    }
    if (factory != null &&
        (!_validFactoryDelivery ||
            pathfinder.findPath(center.deliveryInteractionTile, [
                  factory!.deliveryInteractionTile,
                ]) ==
                null)) {
      issues.add('Çay Fabrikasına ulaşılacak araç yolu bulunamadı.');
    }
    return issues;
  }

  bool get _validFactoryDelivery =>
      factory != null &&
      pathfinder
          .interactionTiles(factory!.gridPosition, factory!.footprint)
          .contains(factory!.deliveryInteractionTile);

  bool get _validDelivery => pathfinder
      .interactionTiles(center.gridPosition, center.footprint)
      .contains(center.deliveryInteractionTile);

  void _setPath(List<GridTile> path) {
    _path = path;
    _pathIndex = 0;
  }

  bool _routeTo(GridTile tile) {
    final path = pathfinder.findPath(tileAt(vehicle.gridPosition), [tile]);
    if (path == null) return false;
    _setPath(path);
    return true;
  }

  void _fail(TransportJob? job) {
    failureMessage = job?.isFactoryShipment == true && vehicle.cargoKg > 0
        ? 'Çay Fabrikasına ulaşılacak araç yolu bulunamadı.'
        : 'Kamyon için uygun yol bulunamadı.';
    if (job != null) {
      job.status = JobStatus.failed;
      job.failureMessage = failureMessage;
    }
    _setPath([]);
    if (vehicle.cargoKg > 0 || job == null) {
      vehicle.state = VehicleState.blocked;
    } else {
      vehicle.state = VehicleState.idle;
      vehicle.assignedJobId = null;
    }
  }

  void _assignNext() {
    if ((vehicle.state != VehicleState.idle &&
            vehicle.state != VehicleState.returning) ||
        vehicle.cargoKg != 0) {
      return;
    }
    for (final job in _jobs.where((j) => j.status == JobStatus.queued)) {
      final sourceValid = job.isFactoryShipment
          ? center.receivedTeaKg > 0 && _validDelivery
          : _field(job).harvestedStockKg > 0 &&
                _adjacent(_field(job), job.sourcePosition);
      if (!sourceValid || !_routeTo(job.sourcePosition)) {
        _fail(job);
        continue;
      }
      failureMessage = null;
      vehicle.assignedJobId = job.id;
      job.vehicleId = vehicle.id;
      job.status = JobStatus.movingToSource;
      vehicle.state = job.isFactoryShipment
          ? VehicleState.movingToCollectionCenterForLoading
          : VehicleState.movingToField;
      return;
    }
  }

  void _driveToDestination(TransportJob job) {
    final valid = job.isFactoryShipment
        ? _validFactoryDelivery
        : _validDelivery;
    final destination = job.isFactoryShipment
        ? factory?.deliveryInteractionTile
        : center.deliveryInteractionTile;
    if (!valid || destination == null || !_routeTo(destination)) {
      _fail(job);
      return;
    }
    job.status = JobStatus.movingToDestination;
    job.failureMessage = null;
    failureMessage = null;
    vehicle.state = job.isFactoryShipment
        ? VehicleState.movingToFactory
        : VehicleState.movingToCollectionCenter;
  }

  void _returnHome() {
    if (!_routeTo(vehicle.homePosition)) {
      _fail(null);
      return;
    }
    vehicle.state = VehicleState.returning;
  }

  void retryRoute() {
    if (vehicle.state != VehicleState.blocked) return;
    final job = currentJob;
    if (vehicle.cargoKg > 0 && job != null) {
      _driveToDestination(job);
    } else {
      failureMessage = null;
      _returnHome();
    }
    _publish();
  }

  Duration _travelTime(double distance) => Duration(
    microseconds:
        (distance / vehicle.movementSpeed * Duration.microsecondsPerSecond)
            .ceil(),
  );
  bool get _moving =>
      vehicle.state == VehicleState.movingToCollectionCenterForLoading ||
      vehicle.state == VehicleState.movingToFactory ||
      vehicle.state == VehicleState.movingToField ||
      vehicle.state == VehicleState.movingToCollectionCenter ||
      vehicle.state == VehicleState.returning;
  Duration? get timeToNextEvent {
    if (_moving) {
      for (final tile in remainingPath) {
        final target = tileCenter(tile);
        final distance = math.sqrt(
          math.pow(target.x - vehicle.gridPosition.x, 2) +
              math.pow(target.y - vehicle.gridPosition.y, 2),
        );
        if (distance > 1e-9) return _travelTime(distance);
      }
      return const Duration(microseconds: 1);
    }
    final job = currentJob;
    if (job == null) return null;
    if (vehicle.state == VehicleState.loading) {
      return TransportConfig.loadingDuration - job.phaseElapsed;
    }
    if (vehicle.state == VehicleState.unloading) {
      return TransportConfig.unloadingDuration - job.phaseElapsed;
    }
    return null;
  }

  double progress(TransportJob job) {
    final duration = job.status == JobStatus.unloading
        ? TransportConfig.unloadingDuration
        : TransportConfig.loadingDuration;
    return (job.phaseElapsed.inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }

  void _arrive() {
    final job = currentJob;
    if (vehicle.state == VehicleState.returning) {
      vehicle.state = VehicleState.idle;
      _assignNext();
    } else if (job != null) {
      job.phaseElapsed = Duration.zero;
      if (vehicle.state == VehicleState.movingToField ||
          vehicle.state == VehicleState.movingToCollectionCenterForLoading) {
        vehicle.state = VehicleState.loading;
        job.status = JobStatus.loading;
      } else {
        vehicle.state = VehicleState.unloading;
        job.status = JobStatus.unloading;
      }
    }
  }

  void _checkMass(int before) {
    if (totalTeaKg != before) {
      throw StateError('Taşıma sırasında çay miktarı değişti.');
    }
  }

  void _load(TransportJob job) {
    final field = job.isFactoryShipment ? null : _field(job);
    final amount = math.min(
      field?.harvestedStockKg ?? center.receivedTeaKg,
      math.min(
        job.isFactoryShipment
            ? vehicle.availableCapacityKg
            : math.min(vehicle.availableCapacityKg, center.availableCapacityKg),
        job.requestedAmountKg ?? vehicle.capacityKg,
      ),
    );
    final before = totalTeaKg;
    if (field != null) {
      field.removeHarvestedStock(amount, notify: false);
    } else {
      center.removeTea(amount, notify: false);
    }
    vehicle.load(amount, notify: false);
    job.amountKg = amount;
    _checkMass(before);
    _driveToDestination(job);
    if (field != null) {
      field.stockChanged();
    } else {
      center.changed();
    }
    vehicle.changed();
  }

  void _unload(TransportJob job) {
    final before = totalTeaKg;
    final amount = vehicle.cargoKg;
    vehicle.unload(amount, notify: false);
    if (job.isFactoryShipment) {
      factory!.receiveRawTea(amount, notify: false);
    } else {
      center.receive(amount, notify: false);
    }
    job.deliveredKg += amount;
    job.status = JobStatus.completed;
    vehicle.assignedJobId = null;
    vehicle.state = VehicleState.idle;
    _checkMass(before);
    _assignNext();
    if (amount > 0) onDeliveryCompleted?.call(job);
    if (vehicle.state == VehicleState.idle) _returnHome();
    if (job.isFactoryShipment) {
      factory!.changed();
    } else {
      center.changed();
    }
    vehicle.changed();
  }

  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Süre negatif olamaz.');
    var left = elapsed;
    _assignNext();
    while (left > Duration.zero) {
      if (_moving) {
        if (_pathIndex >= _path.length) {
          _arrive();
          continue;
        }
        final target = tileCenter(_path[_pathIndex]);
        final dx = target.x - vehicle.gridPosition.x;
        final dy = target.y - vehicle.gridPosition.y;
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance < 1e-9) {
          _pathIndex++;
          continue;
        }
        // A changed traversal map stops movement without moving or losing stock.
        if (!pathfinder.walkable(_path[_pathIndex])) {
          _fail(currentJob);
          break;
        }
        final needed = _travelTime(distance);
        final step = left < needed ? left : needed;
        final ratio = step == needed
            ? 1.0
            : step.inMicroseconds / needed.inMicroseconds;
        vehicle.gridPosition = GridPoint(
          vehicle.gridPosition.x + dx * ratio,
          vehicle.gridPosition.y + dy * ratio,
        );
        left -= step;
        if (step == needed) _pathIndex++;
        if (_pathIndex == _path.length) _arrive();
      } else if (vehicle.state == VehicleState.loading ||
          vehicle.state == VehicleState.unloading) {
        final job = currentJob!;
        final loading = vehicle.state == VehicleState.loading;
        final duration = loading
            ? TransportConfig.loadingDuration
            : TransportConfig.unloadingDuration;
        final needed = duration - job.phaseElapsed;
        final step = left < needed ? left : needed;
        left -= step;
        job.phaseElapsed += step;
        if (job.phaseElapsed >= duration) {
          if (loading) {
            _load(job);
          } else {
            _unload(job);
          }
        }
      } else {
        break;
      }
    }
    _publish();
  }

  void _publish() {
    vehicle.changed();
    notifyListeners();
  }
}
