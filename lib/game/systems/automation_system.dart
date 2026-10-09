import 'package:flutter/foundation.dart';

import '../../features/plantation/tea_field.dart';
import '../../features/transport/transport_system.dart';
import '../../features/transport/transport_vehicle.dart';
import '../../features/workers/job_system.dart';
import 'grid_pathfinder.dart';

/// Discovers work; existing executors own all physical stock transactions.
class AutomationSystem extends ChangeNotifier {
  AutomationSystem({
    required this.workers,
    required this.transport,
    this._enabled = true,
  });
  final JobSystem workers;
  final TransportSystem transport;
  bool _enabled;
  int _retryRevision = -1;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  bool canHarvest(TeaField field) => workers.workers.any(
    (w) =>
        w.canHarvest &&
        workers.pathfinder.findPath(
              tileAt(w.gridPosition),
              workers.pathfinder.interactionTiles(
                field.gridPosition,
                field.footprint,
              ),
            ) !=
            null,
  );
  bool canCollect(TeaField field) {
    final center = transport.collectionCenter;
    final pickup = transport.pickups[field.id];
    if (center == null || pickup == null || center.availableCapacityKg <= 0) {
      return false;
    }
    final finder = transport.pathfinder;
    return finder
            .interactionTiles(field.gridPosition, field.footprint)
            .contains(pickup) &&
        finder
            .interactionTiles(center.gridPosition, center.footprint)
            .contains(center.deliveryInteractionTile) &&
        finder.findPath(tileAt(transport.vehicle.gridPosition), [pickup]) !=
            null &&
        finder.findPath(pickup, [center.deliveryInteractionTile]) != null;
  }

  bool get canShip {
    final center = transport.collectionCenter, factory = transport.factory;
    if (center == null || factory == null) return false;
    final finder = transport.pathfinder;
    return finder
            .interactionTiles(factory.gridPosition, factory.footprint)
            .contains(factory.deliveryInteractionTile) &&
        finder.findPath(tileAt(transport.vehicle.gridPosition), [
              center.deliveryInteractionTile,
            ]) !=
            null &&
        finder.findPath(center.deliveryInteractionTile, [
              factory.deliveryInteractionTile,
            ]) !=
            null;
  }

  void tick() {
    if (!enabled) return;
    if (transport.vehicle.state == VehicleState.blocked &&
        _retryRevision != transport.pathfinder.revision) {
      _retryRevision = transport.pathfinder.revision;
      transport.retryRoute();
    }
    final fields = [...workers.plantation.fields]
      ..sort((a, b) {
        final time = a.stateStartedAt.compareTo(b.stateStartedAt);
        return time != 0 ? time : a.id.compareTo(b.id);
      });
    for (final field in fields) {
      if (field.state == TeaFieldState.ready &&
          workers.jobForField(field.id)?.isActive != true &&
          canHarvest(field)) {
        workers.requestHarvest(field);
      }
    }
    for (final field in fields) {
      if (field.harvestedStockKg > 0 &&
          transport.jobForField(field.id)?.isActive != true &&
          canCollect(field)) {
        transport.requestTransport(field);
      }
    }
    if ((transport.collectionCenter?.receivedTeaKg ?? 0) > 0 &&
        !transport.shipmentPending &&
        canShip) {
      transport.requestFactoryShipment();
    }
    if (transport.factory?.canStartProduction == true) {
      transport.factory!.startProduction();
    }
  }
}
