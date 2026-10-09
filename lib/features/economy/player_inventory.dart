import 'package:flutter/foundation.dart';

import '../workers/equipment.dart';

enum GlobalResource { freshTea, dryTea }

/// Unplaced possessions only. Physical tea never enters these resource balances.
class PlayerInventory extends ChangeNotifier {
  final Map<EquipmentType, int> _equipment = {};
  int equipmentQuantity(EquipmentType type) => _equipment[type] ?? 0;
  Map<EquipmentType, int> get equipment => Map.unmodifiable(_equipment);
  void addEquipment(EquipmentType type) {
    if (type == EquipmentType.none) throw ArgumentError('Geçersiz ekipman.');
    _equipment[type] = equipmentQuantity(type) + 1;
    notifyListeners();
  }

  bool takeEquipment(EquipmentType type) {
    if (equipmentQuantity(type) <= 0) return false;
    final count = equipmentQuantity(type) - 1;
    if (count == 0) {
      _equipment.remove(type);
    } else {
      _equipment[type] = count;
    }
    notifyListeners();
    return true;
  }

  final Map<String, int> _placeables = {};
  final Map<GlobalResource, int> _resources = {};
  Map<String, int> get placeables => Map.unmodifiable(_placeables);
  int quantity(String catalogId) => _placeables[catalogId] ?? 0;
  int resourceQuantity(GlobalResource resource) => _resources[resource] ?? 0;
  int get placeableCount => _placeables.values.fold(0, (sum, n) => sum + n);

  void addPlaceable(String catalogId, [int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _placeables[catalogId] = quantity(catalogId) + amount;
    notifyListeners();
  }

  bool takePlaceable(String catalogId, [int amount = 1]) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    if (quantity(catalogId) < amount) return false;
    final remaining = quantity(catalogId) - amount;
    if (remaining == 0) {
      _placeables.remove(catalogId);
    } else {
      _placeables[catalogId] = remaining;
    }
    notifyListeners();
    return true;
  }

  void addResource(GlobalResource resource, int amount) {
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    _resources[resource] = resourceQuantity(resource) + amount;
    notifyListeners();
  }

  Map<String, Object> toJson() => {
    'equipment': {for (final e in _equipment.entries) e.key.name: e.value},
    'placeables': Map<String, int>.of(_placeables),
    'resources': {for (final e in _resources.entries) e.key.name: e.value},
  };
}
