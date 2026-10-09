import 'equipment.dart';

class WorkerConfig {
  static const idlePause = Duration(seconds: 4);
  static const idleStep = Duration(milliseconds: 100);
  static const idleRadius = 2;
  static const movementSpeed = 2.0; // Logical tiles per simulation second.
  static Duration get harvestDuration =>
      equipmentDefinition(EquipmentType.teaShears).duration;
}
