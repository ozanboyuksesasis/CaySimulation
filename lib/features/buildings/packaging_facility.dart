import 'package:flutter/foundation.dart';

import '../../game/world/isometric_grid.dart';
import '../economy/business_config.dart';
import 'tea_factory.dart';

class PackagingFacility extends ChangeNotifier {
  PackagingFacility({
    required this.id,
    required this.gridPosition,
    required this.footprint,
  });
  final String id;
  GridPoint gridPosition;
  final Footprint footprint;
  final output = PackagedProductStock(
    capacityUnits: BusinessConfig.packagingCapacity,
  );
  int inputKg = 0, completedBatches = 0, speedLevel = 1;
  Duration elapsed = Duration.zero;
  bool get processing => inputKg > 0;
  Duration get duration => Duration(
    microseconds:
        (BusinessConfig.packagingDuration.inMicroseconds /
                (1 + (speedLevel - 1) * .2))
            .round(),
  );
  Duration get remaining => processing ? duration - elapsed : Duration.zero;
  double get progress => processing
      ? (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0, 1)
      : 0;
  void Function(int)? onCompleted;
  // Internal industrial transfer. Caller verifies a connected road service area.
  bool startFrom(TeaFactory factory) {
    if (processing ||
        factory.dryTeaKg < BusinessConfig.packagingInputKg ||
        output.availableSpace < BusinessConfig.packagingOutputUnits) {
      return false;
    }
    factory.takeDryTea(BusinessConfig.packagingInputKg, notify: false);
    inputKg = BusinessConfig.packagingInputKg;
    elapsed = Duration.zero;
    factory.changed();
    notifyListeners();
    return true;
  }

  void advance(Duration dt) {
    if (dt.isNegative) throw ArgumentError('Süre negatif olamaz.');
    if (!processing) return;
    elapsed += dt;
    if (elapsed >= duration) {
      inputKg = 0;
      output.add(BusinessConfig.packagingOutputUnits);
      completedBatches++;
      onCompleted?.call(completedBatches);
    }
    notifyListeners();
  }

  void changed() => notifyListeners();
  Map<String, Object> toJson() => {
    'id': id,
    'x': gridPosition.x,
    'y': gridPosition.y,
    'inputKg': inputKg,
    'output': output.toJson(),
    'elapsedMicros': elapsed.inMicroseconds,
    'completedBatches': completedBatches,
    'speedLevel': speedLevel,
  };
}
