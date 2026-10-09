import '../../features/builder/settlement.dart';
import '../../features/economy/business_config.dart';
import '../../features/economy/economy_state.dart';
import '../../features/plantation/plantation_system.dart';
import '../../features/progression/progression_state.dart';
import '../../features/transport/transport_system.dart';
import '../../features/workers/worker.dart';
import '../../features/workers/workforce_state.dart';
import 'retail_system.dart';

abstract final class UpgradeConfig {
  static const maxLevel = 3;
  static const baseCosts = {
    'growth': 300,
    'collectionCapacity': 500,
    'truckCapacity': 750,
    'truckSpeed': 750,
    'factorySpeed': 1000,
    'packagingSpeed': 600,
    'shelfCapacity': 400,
  };
  static int cost(String id, int level) => baseCosts[id]! * (1 << (level - 1));
}

class UpgradeOption {
  UpgradeOption(
    this.id,
    this.label,
    this.level,
    this.current,
    this.next,
    this.requiredLevel,
    this.apply,
  );
  final String id, label, current, next;
  final int level, requiredLevel;
  final void Function() apply;
  int get cost => UpgradeConfig.cost(id, level);
}

/// Revalidates level, busy state, budget and price at the transaction boundary.
class UpgradeSystem {
  UpgradeSystem({
    required this.world,
    required this.economy,
    required this.progression,
    required this.plantation,
    required this.transport,
    required this.retail,
    required this.workforce,
    required this.canChange,
    required this.restriction,
  });
  final Settlement world;
  final EconomyState economy;
  final ProgressionState progression;
  final PlantationSystem plantation;
  final TransportSystem transport;
  final RetailSystem retail;
  final WorkforceState workforce;
  final bool Function(String) canChange;
  final String? Function(int, String) restriction;
  List<UpgradeOption> options(String id) {
    final result = <UpgradeOption>[];
    for (final f in plantation.fields.where((f) => f.id == id)) {
      result.add(
        UpgradeOption(
          'growth',
          'Büyüme Hızı',
          f.growthLevel,
          '+${(f.growthLevel - 1) * 15}%',
          '+${f.growthLevel * 15}%',
          2,
          () {
            f.growthLevel++;
            f.stockChanged();
          },
        ),
      );
    }
    final c = transport.collectionCenter;
    if (c?.id == id) {
      result.add(
        UpgradeOption(
          'collectionCapacity',
          'Alım Yeri Kapasitesi',
          c!.capacityLevel,
          '${c.capacityKg} kg',
          '${c.capacityKg + 500} kg',
          2,
          () {
            c.capacityLevel++;
            c.changed();
          },
        ),
      );
    }
    final v = transport.vehicle;
    if (v.id == id && transport.collectionCenter != null) {
      result.add(
        UpgradeOption(
          'truckCapacity',
          'Kamyon Kapasitesi',
          v.capacityLevel,
          '${v.capacityKg} kg',
          '${v.capacityKg + 25} kg',
          BusinessConfig.truckUpgradeLevel,
          () {
            v.capacityLevel++;
            v.changed();
          },
        ),
      );
      result.add(
        UpgradeOption(
          'truckSpeed',
          'Kamyon Hızı',
          v.speedLevel,
          '+${(v.speedLevel - 1) * 15}%',
          '+${v.speedLevel * 15}%',
          BusinessConfig.truckUpgradeLevel,
          () {
            v.speedLevel++;
            v.changed();
          },
        ),
      );
    }
    final f = transport.factory;
    if (f?.id == id) {
      result.add(
        UpgradeOption(
          'factorySpeed',
          'Üretim Hızı',
          f!.speedLevel,
          '+${(f.speedLevel - 1) * 20}%',
          '+${f.speedLevel * 20}%',
          2,
          () {
            f.speedLevel++;
            f.changed();
          },
        ),
      );
    }
    final p = retail.packaging;
    if (p?.id == id) {
      result.add(
        UpgradeOption(
          'packagingSpeed',
          'Paketleme Hızı',
          p!.speedLevel,
          '+${(p.speedLevel - 1) * 20}%',
          '+${p.speedLevel * 20}%',
          2,
          () {
            p.speedLevel++;
            p.changed();
          },
        ),
      );
    }
    final s = retail.shop;
    if (s?.id == id) {
      result.add(
        UpgradeOption(
          'shelfCapacity',
          'Reyon Kapasitesi',
          s!.shelfLevel,
          '${s.shelf.capacityUnits} paket',
          '${s.shelf.capacityUnits + 5} paket',
          2,
          () {
            s.shelfLevel++;
            s.shelf.capacityUnits += 5;
            s.changed();
          },
        ),
      );
    }
    return result;
  }

  String? blocked(String entityId, UpgradeOption option) {
    if (option.level >= UpgradeConfig.maxLevel) return 'En yüksek seviye';
    if (progression.level < option.requiredLevel) {
      return 'Seviye ${option.requiredLevel} gerekli.';
    }
    if (entityId != transport.vehicle.id &&
        entityId != retail.shop?.id &&
        !canChange(entityId)) {
      return 'İşlem sürüyor; tamamlanmasını bekle.';
    }
    return restriction(option.cost, 'upgrade');
  }

  String buy(String entityId, String optionId) {
    final matches = options(entityId).where((o) => o.id == optionId);
    if (matches.isEmpty) return 'Geliştirme bulunamadı.';
    final o = matches.single, error = blocked(entityId, o);
    if (error != null) return error;
    if (!economy.spend(o.cost)) return 'Yeterli altının yok.';
    o.apply();
    return '${o.label} geliştirildi.';
  }

  String developWorker(String id, {required bool harvest}) {
    if (progression.level < BusinessConfig.workerUpgradeLevel) {
      return 'İşçi geliştirme Seviye 3’te açılır.';
    }
    final error = restriction(0, 'upgrade');
    if (error != null) return error;
    final worker = workforce.byId(id);
    if (worker == null || worker.state != WorkerState.idle) {
      return 'İşçinin boşta olmasını bekle.';
    }
    return worker.develop(harvest: harvest)
        ? 'Gelişim puanı kullanıldı.'
        : 'Gelişim puanın yok.';
  }
}
