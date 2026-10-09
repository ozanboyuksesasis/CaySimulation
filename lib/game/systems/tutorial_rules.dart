import '../../features/builder/build_catalog.dart';
import '../../features/plantation/plantation_config.dart';
import '../../features/plantation/tea_field.dart';
import '../../features/workers/equipment.dart';
import '../../features/workers/worker.dart';
import '../../features/workers/workforce_state.dart';
import 'tutorial_system.dart';
import '../world/isometric_grid.dart';

/// One policy for both contextual controls and domain commands. Reading it never
/// advances the tutorial or spends resources.
class TutorialRules {
  TutorialRules(this.tutorial);
  final TutorialSystem tutorial;
  bool get active => tutorial.step != TutorialStep.completed;
  static const lockedMessage = 'Önce mevcut eğitim adımını tamamla.';

  String? acquisition(int cost, String id) {
    if (id == 'field' &&
        tutorial.world.structures.any((s) => s.item.id == 'field') &&
        (tutorial.objectives?.progression.level ?? 1) < 2) {
      return 'Ek tarlalar Seviye 2’de açılır.';
    }
    if (active) {
      final allowed = switch (tutorial.step) {
        TutorialStep.firstField => id == 'field',
        TutorialStep.firstWorker => id == 'turhan' || id == 'havva',
        TutorialStep.plantTea => id == 'plant',
        TutorialStep.buyShears => id == EquipmentType.teaShears.name,
        TutorialStep.hireSecondWorker => id == 'havva',
        TutorialStep.buySecondShears => id == EquipmentType.teaShears.name,
        TutorialStep.buildCollectionCenter =>
          id == 'collection_center' || id == 'road',
        TutorialStep.connectCollectionCenter => id == 'road',
        _ => false,
      };
      if (!allowed) return lockedMessage;
    }
    // Keep future essential purchases affordable, including the first factory
    // after onboarding. No money is awarded or removed by this reservation.
    var reserve = 0;
    for (final required in ['factory', 'packaging', 'tea_shop']) {
      if (id != required &&
          !tutorial.world.structures.any((s) => s.item.id == required)) {
        reserve += catalogItem(required).goldCost;
      }
    }
    if (active) {
      if (tutorial.transport.collectionCenter == null &&
          id != 'collection_center') {
        reserve += catalogItem('collection_center').goldCost;
      }
      if (tutorial.firstWorker == null && id != 'turhan' && id != 'havva') {
        reserve += WorkerOffer.cost;
      }
      if (tutorial.firstWorker?.canHarvest != true &&
          tutorial.inventory.equipmentQuantity(EquipmentType.teaShears) == 0 &&
          id != EquipmentType.teaShears.name) {
        reserve += equipmentDefinition(EquipmentType.teaShears).cost;
      }
      if (id != 'plant' &&
          (tutorial.field == null ||
              tutorial.field!.state == TeaFieldState.empty)) {
        reserve += PlantationConfig.plantingCost;
      }
    }
    final balance = tutorial.plantation.economy.balance;
    if (balance >= cost && balance - cost < reserve) {
      return 'Gerekli yapılar için $reserve Altın ayırmalısın.';
    }
    return null;
  }

  String? plant(TeaField field) =>
      !active ||
          (tutorial.step == TutorialStep.plantTea &&
              field.id == tutorial.firstFieldId)
      ? acquisition(PlantationConfig.plantingCost, 'plant')
      : lockedMessage;

  String? equip(Worker worker, EquipmentType type) =>
      !active ||
          (tutorial.step == TutorialStep.equipWorker &&
              worker.id == tutorial.firstWorkerId &&
              type == EquipmentType.teaShears) ||
          (tutorial.step == TutorialStep.equipSecondWorker &&
              worker.id == 'havva' &&
              type == EquipmentType.teaShears)
      ? null
      : lockedMessage;

  String? placement(BuildCatalogItem item, GridPoint position) {
    if (!active || item.buildType != BuildType.field) return null;
    final access = tutorial.world.roadAccess(position, item.footprint);
    if (access == null ||
        tutorial.transport.pathfinder.findPath(
              tutorial.transport.vehicle.homePosition,
              [access],
            ) ==
            null) {
      return 'İlk tarlanı başlangıç yolunun yanına kur.';
    }
    return null;
  }

  bool get canMove => !active;
}
