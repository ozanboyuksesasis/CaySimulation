import 'package:flutter/foundation.dart';

import '../../game/world/isometric_grid.dart';
import 'plantation_config.dart';

enum TeaFieldState { empty, planted, growing1, growing2, ready, harvested }

/// Time is elapsed simulation time, not wall time. Pausing the game pauses growth.
/// No sprites, components, economy or inventory are stored in this model.
class TeaField extends ChangeNotifier {
  TeaField({
    required this.id,
    required this.gridPosition,
    required this.footprint,
  });
  final String id;
  GridPoint gridPosition;
  final Footprint footprint;
  TeaFieldState _state = TeaFieldState.empty;
  TeaFieldState get state => _state;
  Duration? _plantedAt;
  Duration? get plantedAt => _plantedAt;
  Duration _stateStartedAt = Duration.zero;
  Duration get stateStartedAt => _stateStartedAt;
  Duration _now = Duration.zero;
  int _harvestCount = 0;
  int get harvestCount => _harvestCount;
  int get yieldAmount => PlantationConfig.yieldKg;
  int _harvestedStockKg = 0;
  int get harvestedStockKg => _harvestedStockKg;

  int growthLevel = 1;
  Duration? get stageDuration {
    final base = _baseDuration;
    return base == null
        ? null
        : Duration(
            microseconds: (base.inMicroseconds / (1 + (growthLevel - 1) * .15))
                .round(),
          );
  }

  Duration? get _baseDuration => switch (_state) {
    TeaFieldState.planted => PlantationConfig.plantedDuration,
    TeaFieldState.growing1 => PlantationConfig.growing1Duration,
    TeaFieldState.growing2 => PlantationConfig.growing2Duration,
    TeaFieldState.harvested =>
      _harvestedStockKg == 0 ? PlantationConfig.regenerationDuration : null,
    _ => null,
  };
  Duration get remaining {
    final duration = stageDuration;
    if (duration == null) return Duration.zero;
    final difference = duration - (_now - _stateStartedAt);
    return difference.isNegative ? Duration.zero : difference;
  }

  int get remainingSeconds =>
      (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  double get progress {
    final duration = stageDuration;
    if (duration == null) return _state == TeaFieldState.ready ? 1 : 0;
    return ((_now - _stateStartedAt).inMicroseconds / duration.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  /// Continuous crop progress, weighted by the configured stage durations.
  /// Regeneration replaces planting after the first harvest.
  double get overallProgress {
    if (_state == TeaFieldState.ready) return 1;
    if (_state == TeaFieldState.empty || harvestedStockKg > 0) return 0;
    final first =
        (harvestCount == 0
                ? PlantationConfig.plantedDuration
                : PlantationConfig.regenerationDuration)
            .inMicroseconds;
    final middle = PlantationConfig.growing1Duration.inMicroseconds;
    final last = PlantationConfig.growing2Duration.inMicroseconds;
    final elapsed = switch (_state) {
      TeaFieldState.planted || TeaFieldState.harvested => first * progress,
      TeaFieldState.growing1 => first + middle * progress,
      TeaFieldState.growing2 => first + middle + last * progress,
      _ => 0.0,
    };
    return (elapsed / (first + middle + last)).clamp(0.0, 1.0);
  }

  bool plant(Duration now) {
    if (_state != TeaFieldState.empty) return false;
    _checkTime(now);
    _plantedAt = now;
    _stateStartedAt = _now = now;
    _state = TeaFieldState.planted;
    notifyListeners();
    return true;
  }

  /// Called by completed work, not by the player's harvest-order button.
  bool completeHarvest(Duration now) {
    if (_state != TeaFieldState.ready) return false;
    _checkTime(now);
    _stateStartedAt = _now = now;
    _state = TeaFieldState.harvested;
    _harvestCount++;
    _harvestedStockKg += yieldAmount;
    notifyListeners();
    return true;
  }

  /// Emptying stock starts regeneration at the current
  /// simulation time; partial collection never restarts growth.
  void removeHarvestedStock(int amount, {bool notify = true}) {
    if (amount < 0 || amount > _harvestedStockKg) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Geçersiz tarla stok miktarı.',
      );
    }
    if (amount == 0) return;
    _harvestedStockKg -= amount;
    if (_harvestedStockKg == 0) _stateStartedAt = _now;
    if (notify) stockChanged();
  }

  /// Publish only after both sides of a physical transfer have been updated.
  void stockChanged() => notifyListeners();

  void _checkTime(Duration now) {
    if (now < _now) throw ArgumentError('Oyun zamanı geriye gidemez.');
  }

  void advanceTo(Duration now) {
    _checkTime(now);
    final oldState = _state;
    final oldTick =
        _now.inMicroseconds ~/
        PlantationConfig.notificationInterval.inMicroseconds;
    _now = now;
    // Preserve overflow across transitions, even after a long/slow frame.
    while (stageDuration != null && _now - _stateStartedAt >= stageDuration!) {
      _stateStartedAt += stageDuration!;
      _state = switch (_state) {
        TeaFieldState.planted ||
        TeaFieldState.harvested => TeaFieldState.growing1,
        TeaFieldState.growing1 => TeaFieldState.growing2,
        TeaFieldState.growing2 => TeaFieldState.ready,
        _ => _state,
      };
    }
    final newTick =
        _now.inMicroseconds ~/
        PlantationConfig.notificationInterval.inMicroseconds;
    if (_state != oldState || (stageDuration != null && newTick != oldTick)) {
      notifyListeners();
    }
  }

  /// A data snapshot only; persistence and restoration are intentionally absent.
  Map<String, Object?> toJson() => {
    'id': id,
    'growthLevel': growthLevel,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
    'footprintColumns': footprint.columns,
    'footprintRows': footprint.rows,
    'state': _state.name,
    'plantedAtMicros': _plantedAt?.inMicroseconds,
    'stateStartedAtMicros': _stateStartedAt.inMicroseconds,
    'simulationTimeMicros': _now.inMicroseconds,
    'harvestCount': _harvestCount,
    'yieldAmountKg': yieldAmount,
    'harvestedStockKg': _harvestedStockKg,
  };
}
