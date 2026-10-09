import 'package:flutter/painting.dart';

import '../../game/components/world_entity.dart';
import '../../game/world/isometric_grid.dart';
import 'transport_vehicle.dart';

class VehicleComponent extends WorldEntity {
  VehicleComponent({
    required super.definition,
    required super.grid,
    required super.sprite,
    required this.vehicle,
  });
  final TransportVehicle vehicle;
  @override
  Offset get groundPosition => grid.toWorld(vehicle.gridPosition);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    vehicle.addListener(_sync);
    _sync();
  }

  void _sync() => setGridPosition(
    GridPoint(vehicle.gridPosition.x - 0.5, vehicle.gridPosition.y - 0.5),
  );
  @override
  void onRemove() {
    vehicle.removeListener(_sync);
    super.onRemove();
  }
}
