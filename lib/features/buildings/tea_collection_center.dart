import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';

class TeaCollectionCenter extends ChangeNotifier {
  TeaCollectionCenter({
    required this.id,
    required this.gridPosition,
    required this.footprint,
    required this.deliveryInteractionTile,
    this.displayName = 'Çay Alım Yeri',
  });
  final String id;
  final String displayName;
  GridPoint gridPosition;
  final Footprint footprint;
  GridTile deliveryInteractionTile;
  int _receivedTeaKg = 0;
  int get receivedTeaKg => _receivedTeaKg;
  int capacityLevel = 1;
  int get capacityKg => 1000 + (capacityLevel - 1) * 500;
  int get availableCapacityKg => capacityKg - receivedTeaKg;
  void receive(int amount, {bool notify = true}) {
    if (amount < 0 || amount > availableCapacityKg) {
      throw ArgumentError('Alım Yeri kapasitesi aşıldı.');
    }
    _receivedTeaKg += amount;
    if (notify) changed();
  }

  void changed() => notifyListeners();
  void removeTea(int amount, {bool notify = true}) {
    if (amount < 0 || amount > _receivedTeaKg) {
      throw ArgumentError('Geçersiz sevk miktarı.');
    }
    _receivedTeaKg -= amount;
    if (notify) changed();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'capacityLevel': capacityLevel,
    'capacityKg': capacityKg,
    'displayName': displayName,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
    'receivedTeaKg': receivedTeaKg,
    'deliveryX': deliveryInteractionTile.x,
    'deliveryY': deliveryInteractionTile.y,
  };
}
