import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'factory_config.dart';

enum FactoryState { idle, processing, outputBlocked }

/// Stocks and the in-process batch have distinct ownership. No rendering state.
class TeaFactory extends ChangeNotifier {
  TeaFactory({
    required this.id,
    required this.gridPosition,
    required this.footprint,
    required this.deliveryInteractionTile,
    this.displayName = 'Çay Fabrikası',
  });
  final String id;
  final String displayName;
  GridPoint gridPosition;
  final Footprint footprint;
  GridTile deliveryInteractionTile;
  int _rawTeaKg = 0;
  int _dryTeaKg = 0;
  int _processingInputKg = 0;
  int completedBatchCount = 0;
  void Function(int batchNumber)? onProductionCompleted;
  int get rawTeaKg => _rawTeaKg;
  int get dryTeaKg => _dryTeaKg;
  void takeDryTea(int kg, {bool notify = true}) {
    if (kg < 0 || kg > _dryTeaKg) throw ArgumentError('Yetersiz kuru çay.');
    _dryTeaKg -= kg;
    if (notify) changed();
  }

  int speedLevel = 1;
  int get processingInputKg => _processingInputKg;
  FactoryState _state = FactoryState.idle;
  FactoryState get state => _state;
  Duration _now = Duration.zero;
  Duration? _productionStartedAt;
  Duration? get productionStartedAt => _productionStartedAt;
  Duration get productionDuration => Duration(
    microseconds:
        (FactoryConfig.productionDuration.inMicroseconds /
                (1 + (speedLevel - 1) * .2))
            .round(),
  );
  bool get canStartProduction =>
      state == FactoryState.idle && rawTeaKg >= FactoryConfig.inputKg;
  int get missingInputKg =>
      (FactoryConfig.inputKg - rawTeaKg).clamp(0, FactoryConfig.inputKg);
  Duration get remaining => state == FactoryState.processing
      ? productionDuration - (_now - _productionStartedAt!)
      : Duration.zero;
  double get progress => state == FactoryState.processing
      ? ((_now - _productionStartedAt!).inMicroseconds /
                productionDuration.inMicroseconds)
            .clamp(0.0, 1.0)
      : 0;
  void receiveRawTea(int amount, {bool notify = true}) {
    if (amount < 0) throw ArgumentError('Çay miktarı negatif olamaz.');
    _rawTeaKg += amount;
    if (notify) changed();
  }

  bool startProduction() {
    if (!canStartProduction) return false;
    _rawTeaKg -= FactoryConfig.inputKg;
    _processingInputKg = FactoryConfig.inputKg;
    _productionStartedAt = _now;
    _state = FactoryState.processing;
    changed();
    return true;
  }

  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Süre negatif olamaz.');
    _now += elapsed;
    if (_state != FactoryState.processing) return;
    if (_now - _productionStartedAt! >= productionDuration) {
      _processingInputKg = 0;
      _dryTeaKg += FactoryConfig.outputKg;
      _state = FactoryState.idle;
      completedBatchCount++;
      onProductionCompleted?.call(completedBatchCount);
    }
    changed();
  }

  void changed() => notifyListeners();
  Map<String, Object?> toJson() => {
    'id': id,
    'speedLevel': speedLevel,
    'displayName': displayName,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
    'deliveryX': deliveryInteractionTile.x,
    'deliveryY': deliveryInteractionTile.y,
    'rawTeaKg': rawTeaKg,
    'dryTeaKg': dryTeaKg,
    'processingInputKg': processingInputKg,
    'completedBatchCount': completedBatchCount,
    'state': state.name,
    'productionStartedAtMicros': productionStartedAt?.inMicroseconds,
    'productionDurationMicros': productionDuration.inMicroseconds,
    'simulationTimeMicros': _now.inMicroseconds,
  };
}

const factoryStateNames = {
  FactoryState.idle: 'Bekliyor',
  FactoryState.processing: 'Üretim Yapılıyor',
  FactoryState.outputBlocked: 'Ürün Deposu Dolu',
};
