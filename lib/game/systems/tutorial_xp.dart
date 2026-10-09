import '../../features/plantation/tea_field.dart';
import '../../features/workers/equipment.dart';
import 'tutorial_system.dart';

/// One-time teaching rewards for real state transitions. Harvest/delivery XP
/// already comes from business events and is never awarded here again.
class TutorialXp {
  TutorialXp(this.tutorial);
  final TutorialSystem tutorial;
  static const rewards = <String, (int, String)>{
    'field': (10, 'İlk tarla kuruldu'),
    'worker': (10, 'İlk işçi işe alındı'),
    'shears': (10, 'Çay Makası alındı'),
    'equip': (10, 'İşçi ekipmanını aldı'),
    'plant': (10, 'İlk çay dikildi'),
    'ready': (5, 'Çay büyüdü'),
    'center': (15, 'Çay Alım Yeri kuruldu'),
    'road': (5, 'Yol bağlantısı hazır'),
    'secondWorker': (10, 'İkinci işçi işe alındı'),
    'secondShears': (10, 'İkinci işçinin makası alındı'),
    'secondEquip': (10, 'İkinci işçi çalışmaya hazır'),
  };
  final Set<String> _seen = {};
  String lastFeedback = '';
  void evaluate() {
    final field = tutorial.field;
    final worker = tutorial.firstWorker;
    final others = tutorial.workforce.workers.where((w) => w.id != worker?.id);
    final second = others.isEmpty ? null : others.first;
    final available = tutorial.inventory.equipmentQuantity(
      EquipmentType.teaShears,
    );
    final ownsShears =
        available > 0 ||
        tutorial.workforce.workers.any(
          (w) => w.equipment == EquipmentType.teaShears,
        );
    final facts = <String, bool>{
      'field': field != null,
      'worker': worker != null,
      'shears': ownsShears,
      'equip': worker?.canHarvest == true,
      'plant': field?.plantedAt != null,
      'ready':
          field?.state == TeaFieldState.ready || (field?.harvestCount ?? 0) > 0,
      'center': tutorial.transport.collectionCenter != null,
      'road': tutorial.collectionRouteValid,
      'secondWorker': second != null,
      'secondShears': second != null && (available > 0 || second.canHarvest),
      'secondEquip': second?.canHarvest == true,
    };
    final messages = <String>[];
    for (final entry in facts.entries) {
      if (!entry.value || !_seen.add(entry.key)) continue;
      final (xp, label) = rewards[entry.key]!;
      if (tutorial.objectives?.progression.award(
            'tutorial:${entry.key}',
            xp,
            label: label,
          ) ==
          true) {
        messages.add('$label: +$xp XP');
      }
    }
    if (messages.isNotEmpty) {
      lastFeedback = messages.join('\n');
      tutorial.onTutorialReward?.call(lastFeedback);
    }
  }
}
