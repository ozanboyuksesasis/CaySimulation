import 'dart:ui';

import '../../game/models/entity_definition.dart';
import '../../game/systems/game_assets.dart';
import '../../game/world/isometric_grid.dart';

const prototypeWorker = EntityDefinition(
  id: 'worker-01',
  name: 'Mehmet',
  kind: EntityKind.character,
  gridPosition: GridPoint(6, 9),
  visualSize: Size(62, 95),
  footprint: Footprint(1, 1),
  assetPath: GameAssets.farmerMale,
);
