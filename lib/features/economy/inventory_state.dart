import 'package:flutter/foundation.dart';

/// Fresh tea is a product quantity, never a currency or an automatic sale.
/// Legacy inventory retained for compatibility; logistics stock belongs only to
/// fields, vehicles and the collection center. Their tea is never added here.
class InventoryState extends ChangeNotifier {
  int _freshTeaKg = 0;
  int get freshTeaKg => _freshTeaKg;
  void addFreshTea(int kilograms) {
    if (kilograms < 0) throw ArgumentError.value(kilograms, 'kilograms');
    if (kilograms == 0) return;
    _freshTeaKg += kilograms;
    notifyListeners();
  }
}
