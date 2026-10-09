import '../../game/world/isometric_grid.dart';
import 'worker_visual.dart';
export 'worker_visual.dart';

typedef TurhanFrameDefinition = WorkerFrameDefinition;

/// Source pixels remain untouched. These source-space landmarks align the hat
/// top and lowest boot contact to a shared logical render height.
abstract final class TurhanVisualConfig {
  static const frameDuration = WorkerVisualConfig.frameDuration;
  static const root = 'characters/turhan';
  static const frames = {
    'SE_IDLE': TurhanFrameDefinition(
      '$root/idle/TURHAN IDLE SE.png',
      143,
      570,
      1304,
    ),
    'SE_A': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK SE A.png',
      146,
      560,
      1284,
    ),
    'SE_B': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK SE B.png',
      143,
      570,
      1289,
    ),
    'SW_IDLE': TurhanFrameDefinition(
      '$root/idle/TURHAN IDLE SW.png',
      140,
      510,
      1317,
    ),
    'SW_A': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK SW A.png',
      170,
      500,
      1286,
    ),
    'SW_B': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK SW B.png',
      145,
      520,
      1288,
    ),
    'NE_IDLE': TurhanFrameDefinition(
      '$root/idle/TURHAN IDLE NE.png',
      104,
      560,
      1295,
    ),
    'NE_A': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK NE A.png',
      70,
      534,
      1292,
    ),
    'NE_B': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK NE B.png',
      100,
      560,
      1307,
    ),
    'NW_IDLE': TurhanFrameDefinition(
      '$root/idle/TURHAN IDLE NW.png',
      159,
      480,
      1290,
    ),
    'NW_A': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK NW A.png',
      151,
      464,
      1319,
    ),
    'NW_B': TurhanFrameDefinition(
      '$root/walk/TURHAN WALK NW B.png',
      168,
      500,
      1286,
    ),
  };
}

/// Compatibility entry point; Turhan retains his exact metadata and four-step cycle.
class TurhanVisual extends WorkerDirectionalVisual {
  TurhanVisual(super.initial)
    : super(
        frames: TurhanVisualConfig.frames,
        walkCycle: const ['A', 'IDLE', 'B', 'IDLE'],
      );
  static WorkerVisualDirection directionFor(
    GridPoint delta,
    IsometricGrid grid,
  ) => WorkerDirectionalVisual.directionFor(delta, grid);
}
