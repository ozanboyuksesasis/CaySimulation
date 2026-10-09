import 'package:flutter/foundation.dart';

import '../../game/systems/game_assets.dart';

import '../../game/world/isometric_grid.dart';
import '../economy/economy_state.dart';
import '../economy/player_inventory.dart';
import '../shop/shop_service.dart' show PurchaseResult;
import 'worker.dart';
import 'equipment.dart';
import '../progression/progression_state.dart';

class WorkerOffer {
  const WorkerOffer(
    this.id,
    this.name,
    this.assetPath, {
    this.requiredLevel = 1,
  });
  final int requiredLevel;
  final String id, name, assetPath;
  static const cost = 1000;
}

const workerCatalog = [
  WorkerOffer('turhan', 'Turhan', GameAssets.farmerMale),
  WorkerOffer('havva', 'Havva', GameAssets.farmerFemale, requiredLevel: 2),
];

class WorkforceState extends ChangeNotifier {
  WorkforceState({
    required this.economy,
    required this.inventory,
    required this.spawnPosition,
    this.unlocks,
  });
  final EconomyState economy;
  final UnlockSystem? unlocks;
  final PlayerInventory inventory;
  final GridPoint? Function() spawnPosition;
  String? Function(int cost, String id)? purchaseRestriction;
  String? Function(Worker worker, EquipmentType type)? equipmentRestriction;

  /// One starter choice during the first-worker tutorial step. Subsequent
  /// hires still use the catalog level gate.
  bool Function()? starterChoiceAllowed;
  String? hireRestriction(WorkerOffer offer) {
    final starter = workers.isEmpty && starterChoiceAllowed?.call() == true;
    return (!starter && (unlocks?.progression.level ?? 1) < offer.requiredLevel
            ? "Seviye ${offer.requiredLevel}'da açılır"
            : null) ??
        purchaseRestriction?.call(WorkerOffer.cost, offer.id);
  }

  final List<Worker> _workers = [];
  List<Worker> get workers => List.unmodifiable(_workers);
  Worker? byId(String? id) {
    for (final w in _workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  void registerFixture(Worker worker) {
    _workers.add(worker);
    notifyListeners();
  }

  PurchaseResult hire(String id) {
    final matches = workerCatalog.where((o) => o.id == id);
    if (matches.isEmpty) {
      return const PurchaseResult(false, 'Bu işçi bulunamadı.');
    }
    if (byId(id) != null) {
      return const PurchaseResult(false, 'Zaten işletmende çalışıyor.');
    }
    final point = spawnPosition();
    if (point == null) {
      return const PurchaseResult(
        false,
        'İşçi için uygun başlangıç alanı yok.',
      );
    }
    final restriction = hireRestriction(matches.single);
    if (restriction != null) return PurchaseResult(false, restriction);
    if (!economy.spend(WorkerOffer.cost)) {
      return const PurchaseResult(false, 'Yeterli altının yok.');
    }
    final offer = matches.single;
    _workers.add(
      Worker(
        id: id,
        name: offer.name,
        assetPath: offer.assetPath,
        gridPosition: point,
      ),
    );
    notifyListeners();
    return PurchaseResult(true, '${offer.name} artık işletmende çalışıyor.');
  }

  PurchaseResult buyEquipment(EquipmentType type) {
    if (type == EquipmentType.none) {
      return const PurchaseResult(false, 'Geçersiz ekipman.');
    }
    final item = equipmentDefinition(type);
    final restriction =
        ((unlocks?.progression.level ?? 1) < item.requiredLevel
            ? "Seviye ${item.requiredLevel}'da açılır"
            : null) ??
        purchaseRestriction?.call(item.cost, type.name);
    if (restriction != null) return PurchaseResult(false, restriction);
    if (!economy.spend(item.cost)) {
      return const PurchaseResult(false, 'Yeterli altının yok.');
    }
    inventory.addEquipment(type);
    notifyListeners();
    return PurchaseResult(true, '${item.name} envantere eklendi.');
  }

  PurchaseResult equip(Worker worker, EquipmentType type) {
    final restriction = equipmentRestriction?.call(worker, type);
    if (restriction != null) return PurchaseResult(false, restriction);
    if (!_workers.contains(worker) || worker.state != WorkerState.idle) {
      return const PurchaseResult(
        false,
        'İşçi görevdeyken ekipman değiştirilemez.',
      );
    }
    if (worker.equipment == type) {
      return const PurchaseResult(false, 'Bu ekipman zaten takılı.');
    }
    if (type != EquipmentType.none && inventory.equipmentQuantity(type) == 0) {
      return const PurchaseResult(false, 'Bu ekipman envanterde yok.');
    }
    final previous = worker.equipment;
    // Set ownership before inventory notifications, so observers never see a
    // successful removal without its new owner.
    worker.equipment = type;
    if (type != EquipmentType.none) inventory.takeEquipment(type);
    if (previous != EquipmentType.none) inventory.addEquipment(previous);
    worker.changed();
    notifyListeners();
    return const PurchaseResult(true, 'Ekipman değiştirildi.');
  }

  Map<String, Object> toJson() => {
    'workers': workers.map((w) => w.toJson()).toList(),
  };
  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.dispose();
  }
}
