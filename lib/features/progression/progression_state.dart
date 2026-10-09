import 'package:flutter/foundation.dart';

abstract final class ProgressionConfig {
  static const businessThresholds = [100, 150, 225, 325, 450];
  static int businessThreshold(int level) => level <= businessThresholds.length
      ? businessThresholds[level - 1]
      : 450 + (level - 5) * 150;
  static const workerThresholds = [50, 100, 175, 275];
  static int workerThreshold(int level) => level <= workerThresholds.length
      ? workerThresholds[level - 1]
      : 275 + (level - 4) * 125;
  static const firstHarvestXp = 10,
      harvestXp = 3,
      collectionDeliveryXp = 5,
      factoryDeliveryXp = 10,
      productionXp = 15,
      workerHarvestXp = 10;
  static const firstDeliveryBonus = 10,
      packagingXp = 15,
      saleXp = 2,
      firstSaleBonus = 20,
      factoryBuiltXp = 30;
  static const workerHarvestPointBonus = .03, workerMovementPointBonus = .02;
  static double harvestMultiplier(int level) =>
      1 + ((level - 1) * 0.02).clamp(0.0, 1.0);
}

class ProgressionState extends ChangeNotifier {
  ProgressionState({this.threshold = ProgressionConfig.businessThreshold});
  final int Function(int level) threshold;
  int _level = 1, _xp = 0;
  final Set<String> _rewarded = {};
  String lastRewardText = '';
  int get level => _level;
  int get currentXp => _xp;
  int get xpForNextLevel => threshold(level);
  double get progress => currentXp / xpForNextLevel;
  bool award(String eventId, int amount, {String label = 'Deneyim kazandın'}) {
    if (amount < 0) throw ArgumentError('Deneyim negatif olamaz.');
    if (!_rewarded.add(eventId)) return false;
    _xp += amount;
    while (_xp >= xpForNextLevel) {
      _xp -= xpForNextLevel;
      _level++;
    }
    lastRewardText = '$label: +$amount XP';
    notifyListeners();
    return true;
  }

  Map<String, Object> toJson() => {
    'level': level,
    'xp': currentXp,
    'rewardedEvents': _rewarded.toList(),
  };
}

enum BusinessActivity {
  harvest,
  collectionDelivery,
  factoryDelivery,
  production,
  packaging,
  sale,
  factoryBuilt,
}

class BusinessProgression extends ProgressionState {
  bool _harvestRewarded = false;
  bool _deliveryRewarded = false, _saleRewarded = false;
  bool record(BusinessActivity activity, String id) {
    final amount = switch (activity) {
      BusinessActivity.harvest =>
        _harvestRewarded
            ? ProgressionConfig.harvestXp
            : ProgressionConfig.firstHarvestXp,
      BusinessActivity.collectionDelivery =>
        ProgressionConfig.collectionDeliveryXp +
            (_deliveryRewarded ? 0 : ProgressionConfig.firstDeliveryBonus),
      BusinessActivity.factoryDelivery => ProgressionConfig.factoryDeliveryXp,
      BusinessActivity.production => ProgressionConfig.productionXp,
      BusinessActivity.packaging => ProgressionConfig.packagingXp,
      BusinessActivity.sale =>
        ProgressionConfig.saleXp +
            (_saleRewarded ? 0 : ProgressionConfig.firstSaleBonus),
      BusinessActivity.factoryBuilt => ProgressionConfig.factoryBuiltXp,
    };
    final label = switch (activity) {
      BusinessActivity.harvest => 'Hasat tamamlandı',
      BusinessActivity.collectionDelivery => 'Çay teslim edildi',
      BusinessActivity.factoryDelivery => 'Fabrikaya teslim edildi',
      BusinessActivity.production => 'Üretim tamamlandı',
      BusinessActivity.packaging => 'Paketleme tamamlandı',
      BusinessActivity.sale => 'Müşteri satın aldı',
      BusinessActivity.factoryBuilt => 'Çay Fabrikası kuruldu',
    };
    final granted = award('${activity.name}:$id', amount, label: label);
    if (granted && activity == BusinessActivity.harvest) {
      _harvestRewarded = true;
    }
    if (granted && activity == BusinessActivity.collectionDelivery) {
      _deliveryRewarded = true;
    }
    if (granted && activity == BusinessActivity.sale) _saleRewarded = true;
    return granted;
  }
}

class UnlockSystem {
  UnlockSystem(this.progression);
  final ProgressionState progression;
  bool allows(int requiredLevel) => progression.level >= requiredLevel;
  String? restriction(int requiredLevel) =>
      allows(requiredLevel) ? null : "Seviye $requiredLevel'da açılır";
}
