import 'package:flutter/foundation.dart';

import '../../game/world/isometric_grid.dart';
import '../economy/business_config.dart';
import '../economy/economy_state.dart';
import 'packaging_facility.dart';

class RetailShelf extends PackagedProductStock {
  RetailShelf() : super(capacityUnits: BusinessConfig.shelfCapacity);
  int get stockUnits => quantityUnits;
  // Purchases are atomic at arrival; there are no outstanding reservations.
  int get reservedUnits => 0;
}

class TeaShop extends ChangeNotifier {
  TeaShop({
    required this.id,
    required this.gridPosition,
    required this.footprint,
  });
  final String id;
  GridPoint gridPosition;
  final Footprint footprint;
  final shelf = RetailShelf();
  int shelfLevel = 1, soldUnits = 0, revenue = 0;
  Duration saleFeedbackRemaining = Duration.zero;
  final Set<String> _purchaseAttempts = {};
  void Function(String)? onPurchase;
  void restock(PackagingFacility source) {
    final amount = source.output.quantityUnits.clamp(0, shelf.availableSpace);
    if (amount == 0) return;
    source.output.remove(amount);
    shelf.add(amount);
    source.changed();
    notifyListeners();
  }

  bool purchase(String customerId, EconomyState economy) {
    if (!_purchaseAttempts.add(customerId) || shelf.stockUnits == 0) {
      return false;
    }
    shelf.remove(1);
    soldUnits++;
    revenue += shelf.productType.price;
    economy.earn(shelf.productType.price);
    saleFeedbackRemaining = const Duration(seconds: 2);
    onPurchase?.call(customerId);
    notifyListeners();
    return true;
  }

  void advance(Duration dt) {
    if (saleFeedbackRemaining > Duration.zero) {
      saleFeedbackRemaining = dt >= saleFeedbackRemaining
          ? Duration.zero
          : saleFeedbackRemaining - dt;
    }
  }

  void changed() => notifyListeners();
  Map<String, Object> toJson() => {
    'id': id,
    'x': gridPosition.x,
    'y': gridPosition.y,
    'shelf': shelf.toJson(),
    'soldUnits': soldUnits,
    'revenue': revenue,
    'shelfLevel': shelfLevel,
    'purchaseAttempts': _purchaseAttempts.toList(),
  };
}
