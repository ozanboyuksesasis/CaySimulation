import '../../game/systems/grid_pathfinder.dart';

import '../../game/models/job.dart';
import 'equipment.dart';
export '../../game/models/job.dart';

class HarvestJob extends Job {
  HarvestJob({
    required super.id,
    required super.createdAt,
    required this.fieldId,
  });
  final String fieldId;
  String? assignedWorkerId;
  GridTile? targetPosition;
  Duration worked = Duration.zero;
  Duration harvestDuration = equipmentDefinition(EquipmentType.teaShears)
      .duration;
  Map<String, Object?> toJson() => {
    'id': id,
    'fieldId': fieldId,
    'status': status.name,
    'assignedWorkerId': assignedWorkerId,
    'createdAtMicros': createdAt.inMicroseconds,
    'targetX': targetPosition?.x,
    'targetY': targetPosition?.y,
    'workedMicros': worked.inMicroseconds,
    'harvestDurationMicros': harvestDuration.inMicroseconds,
    'failureMessage': failureMessage,
  };
}
