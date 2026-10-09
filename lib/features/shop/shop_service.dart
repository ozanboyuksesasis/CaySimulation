import 'dart:async';

import '../builder/build_catalog.dart';
import '../builder/settlement.dart';
import '../economy/economy_state.dart';
import '../economy/player_inventory.dart';
import '../progression/progression_state.dart';

class PurchaseResult {
  const PurchaseResult(this.success, this.message);
  final bool success;
  final String message;
}

class ShopService {
  ShopService({
    required this.economy,
    required this.inventory,
    required this.world,
    this.unlocks,
  });
  final EconomyState economy;
  final UnlockSystem? unlocks;
  String? Function(int cost, String id)? purchaseRestriction;
  final PlayerInventory inventory;
  final Settlement world;
  final _purchases = StreamController<String>.broadcast(sync: true);
  Stream<String> get purchases => _purchases.stream;
  List<BuildCatalogItem> get catalog => buildCatalog;
  int ownedCount(BuildCatalogItem item) =>
      inventory.quantity(item.id) +
      world.structures.where((e) => e.item.id == item.id).length;
  bool atLimit(BuildCatalogItem item) =>
      item.uniqueLimit != null && ownedCount(item) >= item.uniqueLimit!;
  PurchaseResult buy(String catalogId) {
    final matches = catalog.where((item) => item.id == catalogId);
    if (matches.isEmpty) {
      return const PurchaseResult(false, 'Bu ürün mağazada yok.');
    }
    final item = matches.single;
    final restriction = purchaseRestriction?.call(item.goldCost, item.id);
    if (restriction != null) return PurchaseResult(false, restriction);
    if ((unlocks?.progression.level ?? 1) < item.requiredLevel) {
      return PurchaseResult(false, "Seviye ${item.requiredLevel}'da açılır");
    }
    if (atLimit(item)) return const PurchaseResult(false, 'Zaten sahip.');
    if (!economy.canAfford(item.goldCost) || !economy.spend(item.goldCost)) {
      return const PurchaseResult(false, 'Yeterli altının yok.');
    }
    inventory.addPlaceable(item.id);
    _purchases.add(item.id);
    return PurchaseResult(true, '${item.displayName} envantere eklendi.');
  }

  void dispose() => _purchases.close();
}
