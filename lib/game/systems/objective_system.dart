import '../../features/progression/progression_state.dart';
import '../../features/transport/transport_system.dart';
import '../../features/buildings/factory_config.dart';
import 'retail_system.dart';

enum BusinessObjective {
  levelTwo,
  secondWorker,
  factory,
  firstDryTea,
  packaging,
  shop,
  firstSale,
  secondField,
  workerUpgrade,
  levelThree,
  motorPurchase,
  motorUnlock,
  completed,
}

/// Optional goals read authoritative state; they never lock controls or pay rewards.
class ObjectiveSystem {
  ObjectiveSystem(
    this.progression,
    this.transport, {
    this.retail,
    this.hasSecondWorker,
    this.fieldCount,
    this.workerDeveloped,
    this.motorOwned,
  });
  final RetailSystem? retail;
  final bool Function()? hasSecondWorker;
  final int Function()? fieldCount;
  final bool Function()? workerDeveloped, motorOwned;
  final ProgressionState progression;
  final TransportSystem transport;
  BusinessObjective get current {
    if (progression.level < 2) return BusinessObjective.levelTwo;
    if (transport.factory == null) return BusinessObjective.factory;
    if (retail != null) {
      if (retail!.packaging == null) return BusinessObjective.packaging;
      if (retail!.shop == null) return BusinessObjective.shop;
      if (retail!.shop!.soldUnits == 0) return BusinessObjective.firstSale;
    }
    if (fieldCount != null && fieldCount!() < 2) {
      return BusinessObjective.secondField;
    }
    if (workerDeveloped?.call() == false) {
      return progression.level < 3
          ? BusinessObjective.levelThree
          : BusinessObjective.workerUpgrade;
    }
    if (progression.level < 6) return BusinessObjective.motorUnlock;
    if (motorOwned?.call() == false) return BusinessObjective.motorPurchase;
    return BusinessObjective.completed;
  }

  String get message => switch (current) {
    BusinessObjective.levelTwo =>
      "İşletme Seviyesi 2'ye ulaş\n${progression.currentXp} / ${progression.xpForNextLevel} XP",
    BusinessObjective.factory => 'Çay Fabrikası Kur',
    BusinessObjective.secondWorker =>
      'İkinci işçini işe al\nİsteğe bağlı: Havva Seviye 2’de açıldı.',
    BusinessObjective.packaging => 'Paketleme Tesisi Kur',
    BusinessObjective.shop => 'Çay Dükkânı Kur',
    BusinessObjective.firstSale => 'İlk müşteri satışını gerçekleştir',
    BusinessObjective.secondField => 'İkinci çay tarlanı kur',
    BusinessObjective.levelThree => 'İşçi gelişimi için Seviye 3’e ulaş',
    BusinessObjective.workerUpgrade => 'İşçinde bir gelişim puanı kullan',
    BusinessObjective.motorPurchase => 'Çay Motoru satın al',
    BusinessObjective.firstDryTea =>
      transport.factory!.processingInputKg > 0
          ? 'İlk kuru çayın üretiliyor.'
          : 'İlk Kuru Çayını Üret\n${transport.factory!.rawTeaKg} / ${FactoryConfig.inputKg} kg yaş çay',
    BusinessObjective.motorUnlock => "Seviye 6'ya ulaş\nÇay Motorunu aç",
    BusinessObjective.completed => 'Hedefler tamamlandı! ✓',
  };
}
