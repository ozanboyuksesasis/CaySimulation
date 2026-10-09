import 'package:flutter/foundation.dart';

import '../../features/builder/build_catalog.dart';
import '../../features/builder/settlement.dart';
import '../../features/buildings/tea_factory.dart';
import '../../features/buildings/factory_config.dart';
import '../../features/economy/player_inventory.dart';
import '../../features/plantation/plantation_system.dart';
import '../../features/plantation/tea_field.dart';
import '../../features/transport/transport_system.dart';
import '../../features/workers/job_system.dart';
import '../../features/workers/workforce_state.dart';
import '../../features/workers/worker.dart';
import 'objective_system.dart';
import 'tutorial_xp.dart';

enum ProgressionStep {
  buildFactory,
  connectFactory,
  accumulateInput,
  startProduction,
  producing,
  completed,
}

enum TutorialStep {
  welcome,
  firstField,
  firstWorker,
  buyShears,
  equipWorker,
  plantTea,
  waitGrowth,
  orderHarvest,
  waitHarvest,
  buildCollectionCenter,
  connectCollectionCenter,
  orderTransport,
  waitDelivery,
  hireSecondWorker,
  buySecondShears,
  equipSecondWorker,
  deliveryComplete,
  buildFactory,
  connectFactory,
  accumulateInput,
  shipToFactory,
  startProduction,
  waitProduction,
  firstDryTea,
  completed,
}

/// Domain notifications are the event source. Objectives are derived from real
/// ownership, jobs and physical stock, including actions done ahead of the guide.
class TutorialSystem extends ChangeNotifier {
  TutorialSystem({
    required this.world,
    required this.inventory,
    required this.workforce,
    required this.plantation,
    required this.jobs,
    required this.transport,
    this.objectives,
    this.guided = false,
    this.onTutorialReward,
  }) {
    world.addListener(_bind);
    for (final source in [inventory, workforce, jobs, transport]) {
      source.addListener(evaluate);
    }
    _bind();
    objectives?.progression.addListener(evaluate);
  }
  final Settlement world;
  final PlayerInventory inventory;
  final WorkforceState workforce;
  final PlantationSystem plantation;
  final JobSystem jobs;
  final TransportSystem transport;
  final ObjectiveSystem? objectives;
  final bool guided;
  final void Function(String message)? onTutorialReward;
  late final tutorialXp = TutorialXp(this);
  bool _evaluating = false;
  final Set<ChangeNotifier> _observed = {};
  TutorialStep step = TutorialStep.welcome;
  String? firstFieldId, firstWorkerId;
  String _lastPresentation = '';
  TeaField? get field {
    for (final f in plantation.fields) {
      if (f.id == firstFieldId) return f;
    }
    return null;
  }

  Worker? get firstWorker => workforce.byId(firstWorkerId);
  int get factoryInputKg => transport.factory?.rawTeaKg ?? 0;
  void begin() {
    if (step == TutorialStep.welcome) {
      step = TutorialStep.firstField;
      evaluate();
    }
  }

  void finish() {
    if (step != TutorialStep.deliveryComplete) return;
    step = TutorialStep.completed;
    notifyListeners();
  }

  void _bind() {
    for (final source in <ChangeNotifier>[
      ...plantation.fields,
      if (transport.collectionCenter != null) transport.collectionCenter!,
      if (transport.factory != null) transport.factory!,
    ]) {
      if (_observed.add(source)) source.addListener(evaluate);
    }
    evaluate();
  }

  bool get collectionRouteValid {
    final f = field, center = transport.collectionCenter;
    if (f == null || center == null) return false;
    final pickup = transport.pickups[f.id];
    return pickup != null &&
        transport.pathfinder.findPath(transport.vehicle.homePosition, [
              pickup,
            ]) !=
            null &&
        transport.pathfinder.findPath(pickup, [
              center.deliveryInteractionTile,
            ]) !=
            null;
  }

  bool get factoryRouteValid {
    final center = transport.collectionCenter, factory = transport.factory;
    return center != null &&
        factory != null &&
        transport.pathfinder.findPath(center.deliveryInteractionTile, [
              factory.deliveryInteractionTile,
            ]) !=
            null;
  }

  TutorialStep _currentObjective() {
    if (transport.jobs.any((j) => !j.isFactoryShipment && j.deliveredKg > 0)) {
      return TutorialStep.deliveryComplete;
    }
    if (field == null) return TutorialStep.firstField;
    if (firstWorker == null) return TutorialStep.firstWorker;
    if (!firstWorker!.canHarvest) {
      return inventory.equipment.values.any((q) => q > 0)
          ? TutorialStep.equipWorker
          : TutorialStep.buyShears;
    }
    final f = field!;
    if (f.harvestCount == 0) {
      if (f.state == TeaFieldState.empty) return TutorialStep.plantTea;
      if (jobs.jobForField(f.id)?.isActive == true) {
        return TutorialStep.waitHarvest;
      }
      if (f.state == TeaFieldState.ready) return TutorialStep.orderHarvest;
      return TutorialStep.waitGrowth;
    }
    if (transport.collectionCenter == null) {
      return TutorialStep.buildCollectionCenter;
    }
    if (!collectionRouteValid) return TutorialStep.connectCollectionCenter;
    if (!transport.jobs.any((j) => !j.isFactoryShipment && j.deliveredKg > 0)) {
      return transport.jobForField(f.id)?.isActive == true
          ? TutorialStep.waitDelivery
          : TutorialStep.orderTransport;
    }
    return TutorialStep.deliveryComplete;
  }

  // Optional post-onboarding objective; values come from the physical factory.
  ProgressionStep get progression {
    final factory = transport.factory;
    if (factory == null) return ProgressionStep.buildFactory;
    if (factory.dryTeaKg >= FactoryConfig.outputKg) {
      return ProgressionStep.completed;
    }
    if (factory.state == FactoryState.processing) {
      return ProgressionStep.producing;
    }
    if (factory.rawTeaKg >= FactoryConfig.inputKg) {
      return ProgressionStep.startProduction;
    }
    if (!factoryRouteValid) return ProgressionStep.connectFactory;
    return ProgressionStep.accumulateInput;
  }

  TutorialStep get effectiveStep => step;

  void evaluate() {
    if (_evaluating) return;
    _evaluating = true;
    try {
      if (firstFieldId == null && plantation.fields.isNotEmpty) {
        firstFieldId = plantation.fields.first.id;
      }
      if (firstWorkerId == null && workforce.workers.isNotEmpty) {
        firstWorkerId = workforce.workers.first.id;
      }
      if (guided && step != TutorialStep.welcome) tutorialXp.evaluate();
      if (step != TutorialStep.welcome && step != TutorialStep.completed) {
        step = _currentObjective();
      }
      final presentation =
          '${step.name}|$message|$factoryInputKg|$targetEntityId';
      if (_lastPresentation != presentation) {
        _lastPresentation = presentation;
        notifyListeners();
      }
    } finally {
      _evaluating = false;
    }
  }

  BuildCategory? get category {
    if (step == TutorialStep.completed && objectives != null) {
      return switch (objectives!.current) {
        BusinessObjective.secondWorker => BuildCategory.workers,
        BusinessObjective.factory ||
        BusinessObjective.packaging => BuildCategory.production,
        BusinessObjective.shop => BuildCategory.logistics,
        BusinessObjective.motorUnlock ||
        BusinessObjective.motorPurchase => BuildCategory.equipment,
        BusinessObjective.secondField => BuildCategory.agriculture,
        BusinessObjective.workerUpgrade => null,
        _ => null,
      };
    }
    return switch (effectiveStep) {
      TutorialStep.firstField => BuildCategory.agriculture,
      TutorialStep.firstWorker ||
      TutorialStep.hireSecondWorker => BuildCategory.workers,
      TutorialStep.buyShears ||
      TutorialStep.buySecondShears => BuildCategory.equipment,
      TutorialStep.buildCollectionCenter => BuildCategory.logistics,
      TutorialStep.buildFactory => BuildCategory.production,
      TutorialStep.connectCollectionCenter ||
      TutorialStep.connectFactory => BuildCategory.infrastructure,
      _ => null,
    };
  }

  String? get targetEntityId {
    if (step == TutorialStep.completed &&
        objectives?.current == BusinessObjective.workerUpgrade) {
      final eligible = workforce.workers.where((w) => w.developmentPoints > 0);
      return eligible.isEmpty ? firstWorkerId : eligible.first.id;
    }
    return switch (effectiveStep) {
      TutorialStep.equipWorker => firstWorkerId,
      TutorialStep.equipSecondWorker => 'havva',
      TutorialStep.shipToFactory => transport.collectionCenter?.id,
      TutorialStep.startProduction ||
      TutorialStep.waitProduction => transport.factory?.id,
      TutorialStep.plantTea ||
      TutorialStep.waitGrowth ||
      TutorialStep.orderHarvest ||
      TutorialStep.waitHarvest ||
      TutorialStep.orderTransport ||
      TutorialStep.waitDelivery ||
      TutorialStep.accumulateInput => firstFieldId,
      _ => null,
    };
  }

  String get message {
    if (step == TutorialStep.completed && objectives != null) {
      return objectives!.message;
    }
    final name = firstWorker?.name ?? 'İşçi';
    return switch (effectiveStep) {
      TutorialStep.welcome =>
        'Çay işine hoş geldin!\nİlk çayını birlikte yetiştirelim.',
      TutorialStep.firstField => 'İlk çay bahçeni kur.',
      TutorialStep.firstWorker => 'Bir işçi işe almamız gerekiyor.',
      TutorialStep.hireSecondWorker =>
        'Seviye 2! Havva açıldı.\nArtık ikinci bir işçi işe alabilirsin.',
      TutorialStep.buySecondShears => 'İkinci işçin için bir Çay Makası al.',
      TutorialStep.equipSecondWorker => 'Çay Makasını Havva’ya ver.',
      TutorialStep.buyShears => '$name için Çay Makası al.',
      TutorialStep.equipWorker => 'Çay Makasını $name adlı işçiye ver.',
      TutorialStep.plantTea => 'İlk çayını dik.',
      TutorialStep.waitGrowth =>
        'İşçin hazır çayı otomatik toplayacak.\nİşletmen çalışmaya başladı.',
      TutorialStep.orderHarvest => 'İşçin otomatik hasada hazırlanıyor.',
      TutorialStep.waitHarvest => '$name çayı topluyor.',
      TutorialStep.buildCollectionCenter => 'Bir Çay Alım Yeri kur.',
      TutorialStep.connectCollectionCenter =>
        'Tarlayı ve Alım Yerini yola bağla.',
      TutorialStep.orderTransport =>
        'Ürünlerin uygun olduğunda otomatik taşınır.',
      TutorialStep.waitDelivery => 'İlk teslimatı bekle.',
      TutorialStep.buildFactory => 'Çay Fabrikası Kur',
      TutorialStep.connectFactory => 'Fabrikayı yol ağına bağla.',
      TutorialStep.shipToFactory =>
        'Yaş çay otomatik sevk edilir.\n$factoryInputKg / ${FactoryConfig.inputKg} kg',
      TutorialStep.accumulateInput =>
        'Fabrikaya ${FactoryConfig.inputKg} kg Yaş Çay Ulaştır\n$factoryInputKg / ${FactoryConfig.inputKg} kg',
      TutorialStep.startProduction => 'İlk Kuru Çayını Üret',
      TutorialStep.waitProduction => 'İlk üretim devam ediyor.',
      TutorialStep.firstDryTea => 'İlk kuru çayın hazır! ✓',
      TutorialStep.deliveryComplete => 'İlk çayını başarıyla teslim ettin!\nİşletmen artık otomatik çalışıyor. Senin görevin onu büyütmek ve geliştirmek.',
      TutorialStep.completed => 'Serbest oyun',
    };
  }

  @override
  void dispose() {
    objectives?.progression.removeListener(evaluate);
    world.removeListener(_bind);
    for (final source in [inventory, workforce, jobs, transport]) {
      source.removeListener(evaluate);
    }
    for (final source in _observed) {
      source.removeListener(evaluate);
    }
    super.dispose();
  }
}
