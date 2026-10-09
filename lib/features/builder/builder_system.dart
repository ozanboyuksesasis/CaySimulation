import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/world/isometric_grid.dart';
import '../economy/player_inventory.dart';
import '../economy/economy_state.dart';
import 'build_catalog.dart';
import 'settlement.dart';
import 'placement_validator.dart';
import '../progression/progression_state.dart';

enum BuilderMode { inactive, placingNew, placingRoad, movingExisting }

enum BuildingEventType {
  buildingPlaced,
  fieldPlaced,
  collectionCenterPlaced,
  factoryPlaced,
  buildingMoved,
}

class BuildingEvent {
  const BuildingEvent(this.type, this.entityId);
  final BuildingEventType type;
  final String entityId;
}

class BuilderSystem extends ChangeNotifier {
  BuilderSystem({
    required this.world,
    required this.inventory,
    required this.validator,
    required this.canMove,
    this.economy,
    this.unlocks,
  });
  final Settlement world;
  final UnlockSystem? unlocks;
  final EconomyState? economy;
  String? Function(int cost, String id)? purchaseRestriction;
  String? Function(BuildCatalogItem item, GridPoint position)?
  placementRestriction;
  bool _fromInventory = false;
  bool get paysOnPlacement => economy != null && !_fromInventory;
  final PlayerInventory inventory;
  final PlacementValidator validator;
  final bool Function(String) canMove;
  BuilderMode mode = BuilderMode.inactive;
  BuildCatalogItem? selectedCatalogItem;
  GridPoint previewGridPosition = const GridPoint(6, 5);
  String? movingEntityId;
  GridPoint? originalPosition;
  String? feedback;
  bool previewPinned = false;
  final _events = StreamController<BuildingEvent>.broadcast(sync: true);
  Stream<BuildingEvent> get events => _events.stream;
  bool get isPlacing =>
      mode == BuilderMode.placingNew ||
      mode == BuilderMode.placingRoad ||
      mode == BuilderMode.movingExisting;
  PlacementResult get validationResult {
    if (selectedCatalogItem == null) {
      return const PlacementResult(false, 'Bir yapı seç.');
    }
    if (movingEntityId != null && !canMove(movingEntityId!)) {
      return const PlacementResult(false, 'Bu nesne şu anda taşınamaz.');
    }
    if (movingEntityId == null) {
      final restriction = placementRestriction?.call(
        selectedCatalogItem!,
        previewGridPosition,
      );
      if (restriction != null) return PlacementResult(false, restriction);
    }
    return validator.validate(
      selectedCatalogItem!,
      previewGridPosition,
      movingId: movingEntityId,
    );
  }

  void choose(BuildCatalogItem item, {bool fromInventory = false}) {
    _fromInventory = fromInventory;
    previewPinned = false;
    selectedCatalogItem = item;
    movingEntityId = null;
    originalPosition = null;
    feedback = null;
    mode = item.buildType == BuildType.road
        ? BuilderMode.placingRoad
        : BuilderMode.placingNew;
    notifyListeners();
  }

  void preview(GridPoint point, {bool pin = false}) {
    previewGridPosition = point.tile;
    previewPinned = pin;
    feedback = null;
    notifyListeners();
  }

  bool startMove(String id) {
    final object = world.byId(id);
    if (object == null || !object.item.movable || !canMove(id)) {
      feedback = 'Bu nesne şu anda taşınamaz.';
      notifyListeners();
      return false;
    }
    selectedCatalogItem = object.item;
    movingEntityId = id;
    originalPosition = object.gridPosition;
    previewGridPosition = object.gridPosition;
    previewPinned = false;
    mode = BuilderMode.movingExisting;
    feedback = null;
    notifyListeners();
    return true;
  }

  bool confirm() {
    if (!isPlacing) return false;
    final result = validationResult;
    if (!result.valid) {
      feedback = result.reason;
      notifyListeners();
      return false;
    }
    final item = selectedCatalogItem!;
    if (movingEntityId != null) {
      final id = movingEntityId!;
      world.move(id, previewGridPosition);
      _events.add(BuildingEvent(BuildingEventType.buildingMoved, id));
      cancel();
      return true;
    }
    final levelRestriction =
        (unlocks?.progression.level ?? 1) < item.requiredLevel
        ? "Seviye ${item.requiredLevel}'da açılır"
        : null;
    final restriction =
        levelRestriction ??
        purchaseRestriction?.call(paysOnPlacement ? item.goldCost : 0, item.id);
    if (restriction != null) {
      feedback = restriction;
      notifyListeners();
      return false;
    }
    if (paysOnPlacement
        ? !economy!.spend(item.goldCost)
        : !inventory.takePlaceable(item.id)) {
      feedback = paysOnPlacement
          ? 'Yeterli altının yok.'
          : 'Envanterde bu yapı yok.';
      notifyListeners();
      return false;
    }
    final object = PlacedStructure(
      id: world.nextId(item.id),
      item: item,
      gridPosition: previewGridPosition,
    );
    world.add(object);
    _events.add(BuildingEvent(BuildingEventType.buildingPlaced, object.id));
    final specific = switch (item.buildType) {
      BuildType.field => BuildingEventType.fieldPlaced,
      BuildType.collectionCenter => BuildingEventType.collectionCenterPlaced,
      BuildType.factory => BuildingEventType.factoryPlaced,
      _ => null,
    };
    if (specific != null) _events.add(BuildingEvent(specific, object.id));
    if (mode == BuilderMode.placingRoad) {
      feedback = 'Yol yerleştirildi.';
      notifyListeners();
    } else {
      cancel();
    }
    return true;
  }

  void cancel() {
    mode = BuilderMode.inactive;
    selectedCatalogItem = null;
    movingEntityId = null;
    originalPosition = null;
    feedback = null;
    previewPinned = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
