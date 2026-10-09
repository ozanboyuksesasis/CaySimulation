import 'package:flutter/foundation.dart';

import '../../game/systems/grid_pathfinder.dart';
import '../../game/world/isometric_grid.dart';
import 'transport_config.dart';

enum VehicleState {
  idle,
  movingToField,
  movingToCollectionCenterForLoading,
  movingToFactory,
  loading,
  movingToCollectionCenter,
  unloading,
  returning,
  blocked,
}

class TransportVehicle extends ChangeNotifier {
  TransportVehicle({
    required this.id,
    required this.displayName,
    required this.homePosition,
    int capacityKg = TransportConfig.capacityKg,
    double movementSpeed = TransportConfig.movementSpeed,
  }) : baseCapacityKg = capacityKg,
       baseMovementSpeed = movementSpeed,
       gridPosition = tileCenter(homePosition) {
    if (capacityKg <= 0 || !movementSpeed.isFinite || movementSpeed <= 0) {
      throw ArgumentError('Kapasite ve hız pozitif olmalı.');
    }
  }
  final String id;
  final String displayName;
  final GridTile homePosition;
  final int baseCapacityKg;
  final double baseMovementSpeed;
  int capacityLevel = 1, speedLevel = 1;
  int get capacityKg => baseCapacityKg + 25 * (capacityLevel - 1);
  double get movementSpeed => baseMovementSpeed * (1 + .15 * (speedLevel - 1));
  GridPoint gridPosition;
  VehicleState state = VehicleState.idle;
  String? assignedJobId;
  int _cargoKg = 0;
  int get cargoKg => _cargoKg;
  int get availableCapacityKg => capacityKg - _cargoKg;
  void load(int amount, {bool notify = true}) {
    if (amount < 0 || amount > availableCapacityKg) {
      throw ArgumentError('Araç kapasitesi aşıldı.');
    }
    _cargoKg += amount;
    if (notify) changed();
  }

  void unload(int amount, {bool notify = true}) {
    if (amount < 0 || amount > _cargoKg) {
      throw ArgumentError('Geçersiz yük miktarı.');
    }
    _cargoKg -= amount;
    if (notify) changed();
  }

  void changed() => notifyListeners();
  Map<String, Object?> toJson() => {
    'id': id,
    'capacityLevel': capacityLevel,
    'speedLevel': speedLevel,
    'displayName': displayName,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
    'state': state.name,
    'capacityKg': capacityKg,
    'cargoKg': cargoKg,
    'assignedJobId': assignedJobId,
    'movementSpeed': movementSpeed,
    'homeX': homePosition.x,
    'homeY': homePosition.y,
  };
}

const vehicleStateNames = {
  VehicleState.movingToCollectionCenterForLoading: 'Çay Alım Yerine gidiyor',
  VehicleState.movingToFactory: 'Çay Fabrikasına gidiyor',
  VehicleState.idle: 'Boşta',
  VehicleState.movingToField: 'Tarlaya gidiyor',
  VehicleState.loading: 'Yükleme yapılıyor',
  VehicleState.movingToCollectionCenter: 'Çay Alım Yerine gidiyor',
  VehicleState.unloading: 'Teslimat yapılıyor',
  VehicleState.returning: 'Garaja dönüyor',
  VehicleState.blocked: 'Yol bulunamadı',
};
