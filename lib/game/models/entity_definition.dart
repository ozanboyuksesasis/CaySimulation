import 'dart:ui';

import 'package:flame/components.dart';

import '../world/isometric_grid.dart';

enum EntityKind { building, field, character, vehicle, decoration }

class EntityDefinition {
  const EntityDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.gridPosition,
    required this.visualSize,
    this.assetPath,
    this.footprint,
    this.anchor = Anchor.bottomCenter,
    this.visualOffset = Offset.zero,
    this.depthOffset = 0,
  });
  final String id;
  final String name;
  final EntityKind kind;
  final GridPoint gridPosition;
  final Size visualSize;
  final String? assetPath;
  final Footprint? footprint;
  final Anchor anchor;
  final Offset visualOffset;
  final double depthOffset;
}
