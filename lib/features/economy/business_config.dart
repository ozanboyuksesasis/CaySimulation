abstract final class BusinessConfig {
  // Minimum revenue chain: 12,000 + roads 500 + safety margin 2,500.
  static const startingGold = 15000;
  static const packagingCost = 2000, retailCost = 1500;
  static const industrialLevel = 2, retailLevel = 2;
  static const workerUpgradeLevel = 3, truckUpgradeLevel = 4;
  static const packagingInputKg = 20, packagingOutputUnits = 20;
  static const packagingDuration = Duration(seconds: 8);
  static const packagingCapacity = 100, shelfCapacity = 10;
  static const customerInterval = Duration(seconds: 10);
  static const customerWait = Duration(seconds: 2);
  static const customerCap = 5;
  static const customerSpeed = 1.8;
}

abstract final class RetailEconomyConfig {
  static const packagedTea1KgPrice = 150;
}

enum ProductType { packagedTea1Kg }

extension ProductDefinition on ProductType {
  String get displayName => '1 kg Paket Çay';
  int get kgPerUnit => 1;
  int get price => RetailEconomyConfig.packagedTea1KgPrice;
}

/// A physical container, never a global inventory mirror.
class PackagedProductStock {
  PackagedProductStock({
    this.productType = ProductType.packagedTea1Kg,
    required this.capacityUnits,
  });
  final ProductType productType;
  int capacityUnits;
  int _units = 0;
  int get quantityUnits => _units;
  int get availableSpace => capacityUnits - _units;
  void add(int units) {
    if (units < 0 || units > availableSpace) {
      throw ArgumentError('Ürün kapasitesi aşıldı.');
    }
    _units += units;
  }

  void remove(int units) {
    if (units < 0 || units > _units) throw ArgumentError('Yetersiz ürün.');
    _units -= units;
  }

  Map<String, Object> toJson() => {
    'product': productType.name,
    'units': _units,
    'capacityUnits': capacityUnits,
  };
}
