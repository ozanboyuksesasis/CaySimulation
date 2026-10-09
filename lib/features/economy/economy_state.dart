import 'package:flutter/foundation.dart';

class EconomyState extends ChangeNotifier {
  EconomyState({int initialBalance = 10000}) : _balance = initialBalance {
    _validate(initialBalance);
  }
  int _balance;
  int get balance => _balance;
  static void _validate(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Negatif olamaz');
    }
  }

  bool canAfford(int amount) {
    _validate(amount);
    return _balance >= amount;
  }

  bool spend(int amount) {
    if (!canAfford(amount)) return false;
    if (amount == 0) return true;
    _balance -= amount;
    notifyListeners();
    return true;
  }

  void earn(int amount) {
    _validate(amount);
    if (amount == 0) return;
    _balance += amount;
    notifyListeners();
  }
}
