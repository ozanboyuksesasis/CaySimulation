import 'dart:ui';

import '../../game/models/entity_definition.dart';
import '../../game/world/isometric_grid.dart';

const prototypeFields = [
  EntityDefinition(
    id: 'field-01',
    name: 'Çay Tarlası',
    kind: EntityKind.field,
    gridPosition: GridPoint(2, 2),
    visualSize: Size(240, 155),
    footprint: Footprint(2, 2),
  ),
  EntityDefinition(
    id: 'field-02',
    name: 'Çay Tarlası',
    kind: EntityKind.field,
    gridPosition: GridPoint(5, 2),
    visualSize: Size(240, 155),
    footprint: Footprint(2, 2),
  ),
  EntityDefinition(
    id: 'field-03',
    name: 'Çay Tarlası',
    kind: EntityKind.field,
    gridPosition: GridPoint(2, 5),
    visualSize: Size(240, 155),
    footprint: Footprint(2, 2),
  ),
];
