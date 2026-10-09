import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../features/buildings/packaging_facility.dart';
import '../../features/buildings/tea_shop.dart';
import '../../features/buildings/tea_factory.dart';
import '../../features/economy/business_config.dart';
import '../../features/economy/economy_state.dart';
import '../world/isometric_grid.dart';
import 'grid_pathfinder.dart';

enum CustomerState { arriving, waiting, leaving }

class Customer {
  Customer(this.id, this.gridPosition, this.home, this.path);
  final String id;
  final GridTile home;
  GridPoint gridPosition;
  List<GridTile> path;
  int nextNode = 1;
  CustomerState state = CustomerState.arriving;
  Duration wait = Duration.zero;
  bool purchased = false;
  Map<String, Object> toJson() => {
    'id': id,
    'x': gridPosition.x,
    'y': gridPosition.y,
    'state': state.name,
    'purchased': purchased,
  };
}

/// Post-factory ownership and pedestrian visitors. All timing is simulation time.
class RetailSystem extends ChangeNotifier {
  RetailSystem({
    required this.economy,
    required this.pedestrians,
    required this.roads,
    required this.factory,
  });
  final EconomyState economy;
  final GridPathfinder pedestrians, roads;
  final TeaFactory? Function() factory;
  PackagingFacility? packaging;
  TeaShop? shop;
  final List<Customer> _customers = [];
  List<Customer> get customers => List.unmodifiable(_customers);
  Duration _spawnElapsed = Duration.zero;
  int _sequence = 0;
  // Cumulative observation counters; never used for stock or scheduling.
  int customersArrived = 0, customersServed = 0, customersLost = 0;
  int get customersSpawned => _sequence;
  bool linked(GridPoint a, Footprint af, GridPoint b, Footprint bf) {
    final from = roads.interactionTiles(a, af),
        to = roads.interactionTiles(b, bf);
    return from.any((start) => roads.findPath(start, to) != null);
  }

  bool get industrialConnected {
    final f = factory(), p = packaging;
    return f != null &&
        p != null &&
        linked(f.gridPosition, f.footprint, p.gridPosition, p.footprint);
  }

  bool get retailConnected {
    final p = packaging, s = shop;
    return p != null &&
        s != null &&
        linked(p.gridPosition, p.footprint, s.gridPosition, s.footprint);
  }

  int get processedKg =>
      (factory()?.dryTeaKg ?? 0) +
      (packaging?.inputKg ?? 0) +
      (packaging?.output.quantityUnits ?? 0) *
          ProductType.packagedTea1Kg.kgPerUnit +
      (shop?.shelf.stockUnits ?? 0) * ProductType.packagedTea1Kg.kgPerUnit;
  void tick() {
    if (industrialConnected) packaging!.startFrom(factory()!);
    if (retailConnected) shop!.restock(packaging!);
  }

  List<GridTile>? _pathToShop(GridTile start) => shop == null
      ? null
      : pedestrians.findPath(
          start,
          pedestrians.interactionTiles(shop!.gridPosition, shop!.footprint),
        );
  void _spawn() {
    if (shop == null || _customers.length >= BusinessConfig.customerCap) return;
    for (var x = 0; x < pedestrians.columns; x++) {
      final home = (x: x, y: 0), path = _pathToShop((x: x, y: 0));
      if (path != null) {
        _customers.add(
          Customer('customer_${++_sequence}', tileCenter(home), home, path),
        );
        return;
      }
    }
  }

  bool _move(Customer c, double seconds) {
    var distance = seconds * BusinessConfig.customerSpeed;
    while (c.nextNode < c.path.length && distance > 0) {
      final tile = c.path[c.nextNode];
      if (!pedestrians.walkable(tile)) {
        final newPath = c.state == CustomerState.arriving
            ? _pathToShop(tileAt(c.gridPosition))
            : pedestrians.findPath(tileAt(c.gridPosition), [c.home]);
        if (newPath == null) return false;
        c.path = newPath;
        c.nextNode = 1;
        continue;
      }
      final target = tileCenter(tile),
          dx = target.x - c.gridPosition.x,
          dy = target.y - c.gridPosition.y;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length <= distance) {
        c.gridPosition = target;
        c.nextNode++;
        distance -= length;
      } else {
        c.gridPosition = GridPoint(
          c.gridPosition.x + dx / length * distance,
          c.gridPosition.y + dy / length * distance,
        );
        distance = 0;
      }
    }
    return c.nextNode >= c.path.length;
  }

  void advance(Duration dt, {required bool automatic}) {
    if (dt.isNegative) throw ArgumentError('Süre negatif olamaz.');
    packaging?.advance(dt);
    shop?.advance(dt);
    var spawnDue = false;
    if (automatic && shop != null) {
      _spawnElapsed += dt;
      if (_spawnElapsed >= BusinessConfig.customerInterval) {
        _spawnElapsed = Duration.zero;
        spawnDue = true;
      }
    }
    for (final c in [..._customers]) {
      if (c.state == CustomerState.waiting) {
        c.wait += dt;
        if (c.wait >= BusinessConfig.customerWait) {
          c.purchased = shop?.purchase(c.id, economy) ?? false;
          if (c.purchased) {
            customersServed++;
          } else {
            customersLost++;
          }
          c.state = CustomerState.leaving;
          c.path = pedestrians.findPath(tileAt(c.gridPosition), [c.home]) ?? [];
          c.nextNode = 1;
        }
      } else if (_move(c, dt.inMicroseconds / 1000000)) {
        if (c.state == CustomerState.leaving) {
          _customers.remove(c);
        } else {
          customersArrived++;
          c.state = CustomerState.waiting;
          c.wait = Duration.zero;
        }
      }
    }
    if (spawnDue) _spawn();
    if (_customers.isNotEmpty || shop != null) notifyListeners();
  }

  Set<GridTile> get reservedTiles => {
    for (final c in _customers) tileAt(c.gridPosition),
    for (final c in _customers) ...c.path.skip(c.nextNode),
  };
  bool get shopBusy => _customers.isNotEmpty;
  @override
  void dispose() {
    packaging?.dispose();
    shop?.dispose();
    super.dispose();
  }
}
