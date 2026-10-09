import 'worker_visual.dart';

/// Source-space scarf top and boot-ground landmarks. PNG bytes are untouched.
abstract final class HavvaVisualConfig {
  static const frameDuration = WorkerVisualConfig.frameDuration;
  static const walkCycle = ['A', 'IDLE', 'A', 'IDLE'];
  static const root = 'characters/havva';
  static const frames = {
    'SE_IDLE': WorkerFrameDefinition(
      '$root/idle/HAVVA_IDLE_SE.png',
      38,
      640,
      1200,
    ),
    'SE_A': WorkerFrameDefinition(
      '$root/walk/HAVVA_WALK_SE_A.png',
      47,
      660,
      1188,
    ),
    'SW_IDLE': WorkerFrameDefinition(
      '$root/idle/HAVVA_IDLE_SW.png',
      53,
      640,
      1188,
    ),
    'SW_A': WorkerFrameDefinition(
      '$root/walk/HAVVA_WALK_SW_A.png',
      55,
      620,
      1180,
    ),
    'NE_IDLE': WorkerFrameDefinition(
      '$root/idle/HAVVA_IDLE_NE.png',
      45,
      620,
      1178,
    ),
    'NE_A': WorkerFrameDefinition(
      '$root/walk/HAVVA_WALK_NE_A.png',
      46,
      650,
      1178,
    ),
    'NW_IDLE': WorkerFrameDefinition(
      '$root/idle/HAVVA_IDLE_NW.png',
      41,
      620,
      1193,
    ),
    'NW_A': WorkerFrameDefinition(
      '$root/walk/HAVVA_WALK_NW_A.png',
      42,
      610,
      1188,
    ),
  };
}
