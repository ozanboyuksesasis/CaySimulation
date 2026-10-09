import 'dart:ui';

import '../features/economy/business_config.dart';
import '../features/buildings/packaging_facility.dart';
import '../features/buildings/tea_shop.dart';
import 'systems/retail_system.dart';
import 'components/customer_component.dart';
import 'systems/upgrade_system.dart';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../features/economy/economy_state.dart';
import '../features/economy/inventory_state.dart';
import '../features/economy/player_inventory.dart';
import '../features/economy/resource_summary.dart';
import '../features/shop/shop_service.dart';
import '../features/ui/game_navigation.dart';
import '../features/ui/game_notifications.dart';
import '../features/buildings/tea_collection_center.dart';
import '../features/buildings/tea_factory.dart';
import '../features/builder/build_catalog.dart';
import '../features/builder/settlement.dart';
import '../features/builder/builder_system.dart';
import '../features/builder/placement_validator.dart';
import '../features/builder/placement_preview.dart';
import '../features/transport/transport_vehicle.dart';
import '../features/transport/transport_system.dart';
import '../features/transport/vehicle_component.dart';
import '../features/plantation/field_visuals.dart';
import '../features/plantation/plantation_system.dart';
import '../features/plantation/tea_field.dart';
import '../features/plantation/tea_field_component.dart';
import '../features/workers/worker.dart';
import '../features/workers/worker_component.dart';
import '../features/workers/worker_prototype.dart';
import '../features/workers/job_system.dart';
import '../features/workers/workforce_state.dart';
import '../features/workers/equipment.dart';
import '../features/workers/turhan_visual.dart';
import '../features/workers/havva_visual.dart';
import '../features/workers/harvest_visual.dart';
import '../features/workers/worker_dialogue.dart';
import 'components/worker_speech_layer.dart';
import 'systems/world_simulation.dart';
import 'systems/tutorial_system.dart';
import 'systems/grid_pathfinder.dart';
import 'models/entity_definition.dart';
import 'camera/management_camera.dart';
import 'components/grid_debug_component.dart';
import 'components/terrain_component.dart';
import 'components/world_entity.dart';
import 'components/world_status_layer.dart';
import 'systems/asset_catalog.dart';
import 'systems/game_assets.dart';
import 'systems/depth_sorter.dart';
import 'world/isometric_grid.dart';
import 'world/prototype_map.dart';
import 'world/road_tiles.dart';
import 'world/map_setup.dart';
import 'systems/automation_system.dart';
import 'systems/objective_system.dart';
import 'systems/tutorial_rules.dart';
import '../features/progression/progression_state.dart';
export '../features/builder/settlement.dart' show GameMapMode;

class CayGame extends FlameGame {
  CayGame({
    this.mapMode = GameMapMode.newGame,
    bool? automationEnabled,
    bool guidedTutorial = true,
    int? initialGold,
  }) {
    economy = EconomyState(
      initialBalance:
          initialGold ??
          (mapMode == GameMapMode.devTest
              ? 10000
              : BusinessConfig.startingGold),
    );
    settlement = createSettlement(mapMode);
    pathfinder = GridPathfinder(
      columns: grid.columns,
      rows: grid.rows,
      blocked: settlement.blocked,
    );
    vehiclePathfinder = GridPathfinder(
      columns: grid.columns,
      rows: grid.rows,
      blocked: settlement.blocked,
      allowed: settlement.roads,
    );
    plantation = PlantationSystem(
      economy: economy,
      inventory: inventory,
      fields: [],
    );
    workforce = WorkforceState(
      economy: economy,
      inventory: playerInventory,
      spawnPosition: _workerSpawn,
      unlocks: unlocks,
    );
    if (mapMode == GameMapMode.devTest) {
      workforce.registerFixture(
        Worker(
          id: prototypeWorker.id,
          name: prototypeWorker.name,
          gridPosition: const GridPoint(6.5, 9.5),
          equipment: EquipmentType.teaShears,
        ),
      );
    }
    jobs = JobSystem(
      workers: () => workforce.workers,
      plantation: plantation,
      pathfinder: pathfinder,
    );
    transport = TransportSystem(
      vehicle: vehicle,
      plantation: plantation,
      pathfinder: vehiclePathfinder,
      pickups: {},
    );
    automation = AutomationSystem(
      workers: jobs,
      transport: transport,
      enabled: automationEnabled ?? mapMode == GameMapMode.newGame,
    );
    retail = RetailSystem(
      economy: economy,
      pedestrians: pathfinder,
      roads: vehiclePathfinder,
      factory: () => activeFactory,
    );
    upgrades = UpgradeSystem(
      world: settlement,
      economy: economy,
      progression: progression,
      plantation: plantation,
      transport: transport,
      retail: retail,
      workforce: workforce,
      canChange: canMove,
      restriction: (cost, id) => tutorialRules?.acquisition(cost, id),
    );
    simulation = WorldSimulation(
      workers: jobs,
      transport: transport,
      automation: automation,
      retail: retail,
    );
    jobs.onHarvestCompleted = (job, worker) =>
        progression.record(BusinessActivity.harvest, job.id);
    transport.onDeliveryCompleted = (job) => progression.record(
      job.isFactoryShipment
          ? BusinessActivity.factoryDelivery
          : BusinessActivity.collectionDelivery,
      job.id,
    );
    progression.addListener(_progressChanged);
    builder = BuilderSystem(
      world: settlement,
      inventory: playerInventory,
      economy: mapMode == GameMapMode.newGame ? economy : null,
      validator: PlacementValidator(settlement, reservedTiles: _reservedTiles),
      canMove: canMove,
      unlocks: unlocks,
    );
    shop = ShopService(
      economy: economy,
      inventory: playerInventory,
      world: settlement,
      unlocks: unlocks,
    );
    settlement.addListener(_syncSettlement);
    builder.addListener(_syncPreview);
    workforce.addListener(_syncWorkforce);
    _syncSettlement();
    builder.events.listen((event) {
      if (event.type == BuildingEventType.factoryPlaced) {
        progression.record(BusinessActivity.factoryBuilt, event.entityId);
      }
    });
    if (mapMode == GameMapMode.newGame) {
      tutorial = TutorialSystem(
        world: settlement,
        inventory: playerInventory,
        workforce: workforce,
        plantation: plantation,
        jobs: jobs,
        transport: transport,
        objectives: objectives,
        guided: guidedTutorial,
        onTutorialReward: notifications.showReward,
      );
      if (guidedTutorial) {
        _lastTutorialStep = tutorial!.step;
        tutorial!.addListener(_tutorialStepChanged);
        tutorialRules = TutorialRules(tutorial!);
        builder.purchaseRestriction = tutorialRules!.acquisition;
        workforce.purchaseRestriction = tutorialRules!.acquisition;
        workforce.starterChoiceAllowed = () =>
            tutorial!.step == TutorialStep.firstWorker;
        workforce.equipmentRestriction = tutorialRules!.equip;
        plantation.plantingRestriction = tutorialRules!.plant;
        shop.purchaseRestriction = (_, _) =>
            'Yapıları Envanterden Kur düğmesiyle yerleştir.';
        builder.placementRestriction = tutorialRules!.placement;
      }
    }
  }
  final GameMapMode mapMode;
  late final dialogue = WorkerDialogueSystem(
    workers: () => workforce.workers,
    jobForWorker: jobs.jobForWorker,
  );
  bool get dialogueSuppressed {
    if (panels.panel != GamePanel.none || builder.isPlacing) return true;
    final step = tutorial?.step;
    return tutorial?.guided == true &&
        step != TutorialStep.completed &&
        !const {
          TutorialStep.waitGrowth,
          TutorialStep.orderHarvest,
          TutorialStep.waitHarvest,
          TutorialStep.orderTransport,
          TutorialStep.waitDelivery,
        }.contains(step);
  }

  TutorialStep? _lastTutorialStep;
  void _tutorialStepChanged() {
    final next = tutorial!.step;
    if (next == _lastTutorialStep) return;
    _lastTutorialStep = next;
    panels.close();
  }

  TutorialRules? tutorialRules;
  final progression = BusinessProgression();
  late final unlocks = UnlockSystem(progression);
  late final AutomationSystem automation;
  late final objectives = ObjectiveSystem(
    progression,
    transport,
    retail: retail,
    hasSecondWorker: () => workforce.workers.length >= 2,
    fieldCount: () => plantation.fields.length,
    workerDeveloped: () =>
        workforce.workers.any((w) => w.harvestPoints + w.movementPoints > 0),
    motorOwned: () =>
        playerInventory.equipmentQuantity(EquipmentType.teaHarvesterMotor) >
            0 ||
        workforce.workers.any(
          (w) => w.equipment == EquipmentType.teaHarvesterMotor,
        ),
  );
  bool get manualControls => !automation.enabled;
  int _announcedLevel = 1;
  void _progressChanged() {
    final levelUp = progression.level > _announcedLevel;
    final unlocked = [
      for (final item in workerCatalog)
        if (item.requiredLevel > _announcedLevel &&
            item.requiredLevel <= progression.level)
          item.name,
      for (final item in equipmentCatalog)
        if (item.requiredLevel > _announcedLevel &&
            item.requiredLevel <= progression.level)
          item.name,
    ];
    _announcedLevel = progression.level;
    notifications.showReward(
      '${progression.lastRewardText}${levelUp ? '\nSEVİYE ATLADIN! Seviye ${progression.level}' : ''}${unlocked.isNotEmpty ? '\nAçıldı: ${unlocked.join(', ')}' : ''}',
    );
  }

  final grid = const IsometricGrid();
  late final EconomyState economy;
  late final RetailSystem retail;
  late final UpgradeSystem upgrades;
  final inventory = InventoryState();
  final playerInventory = PlayerInventory();
  late final ShopService shop;
  late final panels = GameNavigation(beforeOpen: builder.cancel);
  final notifications = GameNotifications();
  late final resources = ResourceSummary(plantation, transport);
  final vehicle = TransportVehicle(
    id: 'truck-01',
    displayName: 'Çay Kamyonu',
    homePosition: truckHomeTile,
  );
  late final WorkforceState workforce;
  TutorialSystem? tutorial;
  Worker get worker => workforce.workers.first;
  late final Settlement settlement;
  late final BuilderSystem builder;
  late final GridPathfinder pathfinder, vehiclePathfinder;
  late final PlantationSystem plantation;
  late final JobSystem jobs;
  late final TransportSystem transport;
  late final WorldSimulation simulation;
  TeaCollectionCenter? get activeCollectionCenter => transport.collectionCenter;
  TeaFactory? get activeFactory => transport.factory;
  // Existing dev-map callers keep their non-null API; player UI uses optional models.
  TeaCollectionCenter get collectionCenter => transport.center;
  TeaFactory get factory => transport.factory!;
  final assetCatalog = AssetCatalog();
  final showGrid = ValueNotifier(false);
  final selectedEntity = ValueNotifier<WorldEntity?>(null);
  final selectedTile = ValueNotifier<GridPoint?>(null);
  final fps = ValueNotifier(0);
  final entities = <WorldEntity>[];
  final _sorter = DepthSorter();
  late final navigation = ManagementCamera(
    camera,
    grid,
    initialFocus: mapMode == GameMapMode.newGame ? const GridPoint(7, 8) : null,
  );
  TerrainComponent? _terrain;
  bool _assetsLoaded = false;
  double _elapsed = 0;
  int _frames = 0;
  bool isWorldReady = false;

  Set<GridTile> _reservedTiles() => {
    ...retail.reservedTiles,
    settlement.homeTile,
    for (final w in workforce.workers) tileAt(w.gridPosition),
    ...jobs.remainingPath,
    if (jobs.currentJob?.targetPosition != null)
      jobs.currentJob!.targetPosition!,
    if (activeCollectionCenter != null) tileAt(vehicle.gridPosition),
    ...transport.remainingPath,
  };

  bool canMove(String id) {
    if (tutorialRules?.canMove == false) return false;
    if (id == retail.packaging?.id && retail.packaging!.processing) {
      return false;
    }
    if (id == retail.shop?.id && retail.shopBusy) return false;
    final object = settlement.byId(id);
    if (object == null || !object.item.movable) return false;
    if (jobs.jobs.any((j) => j.fieldId == id && j.isActive)) return false;
    if (activeFactory?.id == id &&
        activeFactory?.state == FactoryState.processing) {
      return false;
    }
    return !transport.jobs.any(
      (j) =>
          (j.isActive ||
              (vehicle.assignedJobId == j.id && vehicle.cargoKg > 0)) &&
          (j.sourceId == id || j.destinationId == id),
    );
  }

  GridTile? _access(PlacedStructure s) =>
      settlement.roadAccess(s.gridPosition, s.item.footprint, ignoreId: s.id);

  GridPoint? _workerSpawn() {
    final candidates =
        <GridTile>[
          for (var x = 0; x < grid.columns; x++)
            for (var y = 0; y < grid.rows; y++) (x: x, y: y),
        ]..sort((a, b) {
          final distance = ((a.x - 6).abs() + (a.y - 9).abs()).compareTo(
            (b.x - 6).abs() + (b.y - 9).abs(),
          );
          return distance != 0
              ? distance
              : (a.x * grid.rows + a.y).compareTo(b.x * grid.rows + b.y);
        });
    for (final tile in candidates) {
      if (!settlement.blocked.contains(tile) &&
          tile != settlement.homeTile &&
          !workforce.workers.any((w) => tileAt(w.gridPosition) == tile)) {
        return tileCenter(tile);
      }
    }
    return null;
  }

  void _syncWorkforce() {
    if (!_assetsLoaded) return;
    for (final w in workforce.workers) {
      if (entities.any((e) => e.definition.id == w.id)) continue;
      _addEntity(
        EntityDefinition(
          id: w.id,
          name: w.name,
          kind: EntityKind.character,
          gridPosition: w.gridPosition,
          visualSize: prototypeWorker.visualSize,
          footprint: prototypeWorker.footprint,
          assetPath: w.assetPath,
        ),
      );
    }
  }

  void _syncSettlement() {
    pathfinder.updateTopology(blocked: settlement.blocked);
    vehiclePathfinder.updateTopology(
      blocked: settlement.blocked,
      allowed: settlement.roads,
    );
    for (final s in settlement.structures) {
      final type = s.item.buildType;
      if (type == BuildType.field) {
        final matches = plantation.fields.where((f) => f.id == s.id);
        if (matches.isEmpty) {
          plantation.register(
            TeaField(
              id: s.id,
              gridPosition: s.gridPosition,
              footprint: s.item.footprint,
            ),
          );
          final pickup = mapMode == GameMapMode.devTest
              ? fieldPickupTiles[s.id] ?? _access(s)
              : _access(s);
          if (pickup != null) transport.pickups[s.id] = pickup;
        } else {
          final field = matches.single;
          if (field.gridPosition != s.gridPosition) {
            field.gridPosition = s.gridPosition;
            transport.pickups.remove(s.id);
            field.stockChanged();
          }
          if (!transport.pickups.containsKey(s.id)) {
            final pickup = _access(s);
            if (pickup != null) transport.pickups[s.id] = pickup;
          }
        }
      } else if (type == BuildType.collectionCenter) {
        if (activeCollectionCenter == null) {
          transport.collectionCenter = TeaCollectionCenter(
            id: s.id,
            gridPosition: s.gridPosition,
            footprint: s.item.footprint,
            deliveryInteractionTile: mapMode == GameMapMode.devTest
                ? collectionDeliveryTile
                : _access(s)!,
          );
        } else if (collectionCenter.gridPosition != s.gridPosition) {
          collectionCenter.gridPosition = s.gridPosition;
          collectionCenter.deliveryInteractionTile = _access(s)!;
          collectionCenter.changed();
        }
      } else if (type == BuildType.factory) {
        if (activeFactory == null) {
          transport.factory = TeaFactory(
            id: s.id,
            gridPosition: s.gridPosition,
            footprint: s.item.footprint,
            deliveryInteractionTile: mapMode == GameMapMode.devTest
                ? factoryDeliveryTile
                : _access(s)!,
          );
          factory.advance(plantation.simulationTime);
          factory.onProductionCompleted = (batch) => progression.record(
            BusinessActivity.production,
            '${factory.id}:$batch',
          );
        } else if (factory.gridPosition != s.gridPosition) {
          factory.gridPosition = s.gridPosition;
          factory.deliveryInteractionTile = _access(s)!;
          factory.changed();
        }
      } else if (type == BuildType.packaging) {
        retail.packaging ??=
            PackagingFacility(
                id: s.id,
                gridPosition: s.gridPosition,
                footprint: s.item.footprint,
              )
              ..onCompleted = (batch) => progression.record(
                BusinessActivity.packaging,
                '${s.id}:$batch',
              );
        retail.packaging!.gridPosition = s.gridPosition;
      } else if (type == BuildType.teaShop) {
        retail.shop ??= TeaShop(
          id: s.id,
          gridPosition: s.gridPosition,
          footprint: s.item.footprint,
        )..onPurchase = (id) => progression.record(BusinessActivity.sale, id);
        retail.shop!.gridPosition = s.gridPosition;
      }
      if (_assetsLoaded && type != BuildType.road) {
        final existing = entities.where((e) => e.definition.id == s.id);
        if (existing.isEmpty) {
          _addEntity(structureDefinition(s));
        } else {
          existing.single.setGridPosition(s.gridPosition);
        }
      }
    }
    if (_assetsLoaded &&
        activeCollectionCenter != null &&
        !entities.any((e) => e.definition.id == vehicle.id)) {
      _addEntity(prototypeEntities.singleWhere((e) => e.id == vehicle.id));
    }
    _terrain?.invalidate();
    _sorter.sort(entities);
  }

  void _syncPreview() {
    if (builder.isPlacing) panels.close();
    for (final e in entities) {
      e.previewHidden = e.definition.id == builder.movingEntityId;
    }
  }

  void _addEntity(EntityDefinition definition) {
    final fields = plantation.fields.where((f) => f.id == definition.id);
    final WorldEntity entity;
    if (fields.isNotEmpty) {
      entity = TeaFieldComponent(
        definition: definition,
        grid: grid,
        field: fields.single,
        currentJob: () => jobs.jobForField(definition.id),
        workerGround: () {
          final w = jobs.assignedWorker(jobs.jobForField(definition.id));
          return w == null ? null : grid.toWorld(w.gridPosition);
        },
        actionCycle: () =>
            jobs.assignedWorker(jobs.jobForField(definition.id))?.equipment ==
                EquipmentType.teaHarvesterMotor
            ? HarvestVisualConfig.motorCycleSeconds
            : HarvestVisualConfig.shearsCycleSeconds,
        catalog: assetCatalog,
      );
    } else if (workforce.byId(definition.id) != null) {
      entity = WorkerComponent(
        definition: definition,
        grid: grid,
        worker: workforce.byId(definition.id)!,
        currentJob: () => jobs.jobForWorker(workforce.byId(definition.id)!),
        zoom: () => navigation.zoom,
        catalog: assetCatalog,
        sprite: assetCatalog.sprite(definition.assetPath),
      );
    } else if (definition.id == vehicle.id) {
      entity = VehicleComponent(
        definition: definition,
        grid: grid,
        vehicle: vehicle,
        sprite: assetCatalog.sprite(definition.assetPath),
      );
    } else {
      entity = WorldEntity(
        definition: definition,
        grid: grid,
        sprite: assetCatalog.sprite(definition.assetPath),
      );
    }
    entities.add(entity);
    world.add(entity);
  }

  @override
  Color backgroundColor() => const Color(0xFF203A36);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await assetCatalog.load([
      ...prototypeEntities.map((e) => e.assetPath).whereType<String>(),
      ...buildCatalog.map((e) => e.assetPath),
      ...fieldAssets.values,
      ...workerCatalog.map((w) => w.assetPath),
      ...equipmentCatalog.map((e) => e.assetPath),
      ...TurhanVisualConfig.frames.values.map((f) => f.asset),
      ...HavvaVisualConfig.frames.values.map((f) => f.asset),
      GameAssets.teaSackFull,
      GameAssets.customer,
    ]);
    _terrain = TerrainComponent(
      grid,
      settlement: settlement,
      devMap: mapMode == GameMapMode.devTest,
    );
    await world.add(_terrain!);
    _assetsLoaded = true;
    _syncSettlement();
    _syncWorkforce();
    _sorter.sort(entities);
    await world.add(GridDebugComponent(this));
    await world.add(PlacementPreview(this));
    await world.add(WorldStatusLayer(this));
    await camera.viewport.add(WorkerSpeechLayer(this));
    navigation.resize(Size(size.x, size.y));
    navigation.reset();
    for (final issue in transport.validateRoutes()) {
      debugPrint(issue);
    }
    isWorldReady = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    navigation.resize(Size(size.x, size.y));
  }

  @override
  void update(double dt) {
    if (isWorldReady && dt > 0) {
      simulation.advance(
        Duration(microseconds: (dt * Duration.microsecondsPerSecond).round()),
      );
    }
    if (isWorldReady) _syncCustomers();
    if (isWorldReady) {
      dialogue.update(
        plantation.simulationTime,
        suppressed: dialogueSuppressed,
        zoom: navigation.zoom,
      );
    }
    _sorter.sort(entities);
    super.update(dt);
    _elapsed += dt;
    _frames++;
    if (_elapsed >= 0.5) {
      fps.value = (_frames / _elapsed).round();
      _elapsed = 0;
      _frames = 0;
    }
  }

  void _syncCustomers() {
    final ids = retail.customers.map((c) => c.id).toSet();
    for (final entity in entities.whereType<CustomerComponent>().toList()) {
      if (!ids.contains(entity.customer.id)) {
        if (selectedEntity.value == entity) selectedEntity.value = null;
        entity.removeFromParent();
        entities.remove(entity);
      }
    }
    for (final c in retail.customers) {
      if (entities.any((e) => e.definition.id == c.id)) continue;
      final component = CustomerComponent(
        customer: c,
        grid: grid,
        sprite: assetCatalog.sprite(GameAssets.customer),
      );
      entities.add(component);
      world.add(component);
    }
  }

  void previewAt(Offset screen, {bool pin = false}) {
    if (!isWorldReady || !builder.isPlacing) return;
    if (!pin && builder.previewPinned) return;
    builder.preview(
      grid.toGrid(navigation.screenToWorld(screen)).tile,
      pin: pin && builder.mode != BuilderMode.placingRoad,
    );
  }

  void tapAt(Offset screen) {
    if (builder.isPlacing) {
      previewAt(screen, pin: true);
      if (builder.mode == BuilderMode.placingRoad) builder.confirm();
    } else {
      selectAt(screen);
    }
  }

  GridPoint? _moveGrab;
  bool beginTouchMove(Offset screen) {
    if (!isWorldReady || builder.isPlacing) return false;
    selectAt(screen);
    final entity = selectedEntity.value;
    if (entity == null ||
        settlement.byId(entity.definition.id)?.item.movable != true) {
      return false;
    }
    if (!builder.startMove(entity.definition.id)) {
      notifications.show('Bu nesne şu anda taşınamaz.');
      return false;
    }
    _moveGrab = grid.toGrid(navigation.screenToWorld(screen));
    notifications.show('Taşımak için sürükle, ardından onayla.');
    return true;
  }

  void dragTouchMove(Offset screen) {
    if (builder.mode != BuilderMode.movingExisting || _moveGrab == null) return;
    final point = grid.toGrid(navigation.screenToWorld(screen));
    final origin = builder.originalPosition!;
    builder.preview(
      GridPoint(
        origin.x + point.x - _moveGrab!.x,
        origin.y + point.y - _moveGrab!.y,
      ),
      pin: true,
    );
  }

  void selectAt(Offset screen) {
    if (!isWorldReady) return;
    final point = navigation.screenToWorld(screen);
    final tile = grid.toGrid(point).tile;
    selectedTile.value = grid.contains(tile) ? tile : null;
    final frontFirst = [...entities]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    WorldEntity? hit;
    for (final entity in frontFirst) {
      if (entity.hitTest(point)) {
        hit = entity;
        break;
      }
    }
    selectedEntity.value?.selected = false;
    if (hit != null) hit.selected = true;
    selectedEntity.value = hit;
  }

  void focusEntity(String id) {
    final matches = entities.where((e) => e.definition.id == id);
    if (matches.isEmpty) return;
    final entity = matches.single;
    selectedEntity.value?.selected = false;
    entity.selected = true;
    selectedEntity.value = entity;
    final point = entity.groundPosition;
    camera.viewfinder.position = Vector2(point.dx, point.dy);
    navigation.clamp();
  }

  void disposeState() {
    retail.dispose();
    automation.dispose();
    progression.removeListener(_progressChanged);
    progression.dispose();
    tutorial?.removeListener(_tutorialStepChanged);
    tutorial?.dispose();
    settlement.removeListener(_syncSettlement);
    builder.removeListener(_syncPreview);
    builder.dispose();
    shop.dispose();
    panels.dispose();
    notifications.dispose();
    playerInventory.dispose();
    settlement.dispose();
    transport.dispose();
    vehicle.dispose();
    activeCollectionCenter?.dispose();
    activeFactory?.dispose();
    jobs.dispose();
    workforce.removeListener(_syncWorkforce);
    workforce.dispose();
    plantation.dispose();
    inventory.dispose();
    economy.dispose();
    showGrid.dispose();
    selectedEntity.dispose();
    selectedTile.dispose();
    fps.dispose();
    assetCatalog.dispose();
  }
}
