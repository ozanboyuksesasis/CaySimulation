import 'package:flutter/foundation.dart';

import '../../game/world/isometric_grid.dart';
import '../../game/systems/game_assets.dart';
import 'worker_config.dart';
import 'equipment.dart';
import '../progression/progression_state.dart';

enum WorkerState { idle, movingToJob, working, returning, blocked }

class Worker extends ChangeNotifier {
  Worker({
    required this.id,
    required this.name,
    required this.gridPosition,
    double movementSpeed = WorkerConfig.movementSpeed,
    this.assetPath = GameAssets.farmerMale,
    this.equipment = EquipmentType.none,
    GridPoint? homePosition,
  }) : baseMovementSpeed = movementSpeed,
       homePosition = homePosition ?? gridPosition {
    if (!movementSpeed.isFinite || movementSpeed <= 0) {
      throw ArgumentError('İşçi hızı pozitif olmalı.');
    }
  }
  final String id;
  final String name;
  final String assetPath;
  final GridPoint homePosition;
  EquipmentType equipment;
  bool get canHarvest => equipment != EquipmentType.none;
  final experience = ProgressionState(
    threshold: ProgressionConfig.workerThreshold,
  );
  int get workerLevel => experience.level;
  int get workerXp => experience.currentXp;
  int get workerXpForNextLevel => experience.xpForNextLevel;
  Duration get harvestDuration => canHarvest
      ? Duration(
          microseconds:
              (equipmentDefinition(equipment).duration.inMicroseconds /
                      (ProgressionConfig.harvestMultiplier(workerLevel) +
                          harvestPoints *
                              ProgressionConfig.workerHarvestPointBonus))
                  .round(),
        )
      : Duration.zero;
  void rewardHarvest(String jobId) {
    experience.award(jobId, ProgressionConfig.workerHarvestXp);
    changed();
  }

  final double baseMovementSpeed;
  int harvestPoints = 0, movementPoints = 0;
  int get developmentPoints => workerLevel - 1 - harvestPoints - movementPoints;
  double get movementSpeed =>
      baseMovementSpeed *
      (1 + movementPoints * ProgressionConfig.workerMovementPointBonus);
  bool develop({required bool harvest}) {
    if (developmentPoints <= 0 || state != WorkerState.idle) return false;
    if (harvest) {
      harvestPoints++;
    } else {
      movementPoints++;
    }
    changed();
    return true;
  }

  GridPoint gridPosition; // Continuous logical center of the worker's feet.
  WorkerState state = WorkerState.idle;
  String? assignedJobId;
  GridPoint? workFacingTarget;
  bool isStrolling = false;
  void changed() => notifyListeners();
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'assetPath': assetPath,
    'equipment': equipment.name,
    'homeX': homePosition.x,
    'homeY': homePosition.y,
    'gridX': gridPosition.x,
    'gridY': gridPosition.y,
    'state': state.name,
    'assignedJobId': assignedJobId,
    'movementSpeed': movementSpeed,
    'experience': experience.toJson(),
    'harvestPoints': harvestPoints,
    'movementPoints': movementPoints,
  };
  @override
  void dispose() {
    experience.dispose();
    super.dispose();
  }
}

const workerStateNames = {
  WorkerState.idle: 'Boşta',
  WorkerState.movingToJob: 'Tarlaya gidiyor',
  WorkerState.working: 'Çay topluyor',
  WorkerState.returning: 'Geri dönüyor',
  WorkerState.blocked: 'Yol kapalı',
};
