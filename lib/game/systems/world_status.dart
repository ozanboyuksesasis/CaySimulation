import '../../features/plantation/tea_field.dart';
import '../../features/buildings/tea_factory.dart';
import '../../features/workers/worker.dart';
import '../../features/transport/transport_vehicle.dart';
import '../../features/buildings/factory_config.dart';

/// Read-only presentation snapshots; quantities and clocks stay in the models.
class WorldStatus {
  const WorldStatus(
    this.label, {
    this.progress,
    this.symbol = '',
    this.sack = false,
  });
  final String label, symbol;
  final double? progress;
  final bool sack;

  static WorldStatus? field(
    TeaField field, {
    bool selected = false,
    bool automated = false,
    bool harvestActive = false,
    double? harvestProgress,
    bool transportActive = false,
  }) {
    if (harvestActive) {
      return WorldStatus('Hasat', progress: harvestProgress, symbol: '');
    }
    if (field.harvestedStockKg > 0) {
      return WorldStatus(
        '${field.harvestedStockKg} kg${automated && !transportActive ? ' · Nakliye Bekliyor' : ''}',
        sack: true,
      );
    }
    if (field.state == TeaFieldState.ready) {
      return WorldStatus(
        automated
            ? (harvestActive ? 'Hasat' : 'İşçi Bekliyor')
            : 'Hasada Hazır',
        symbol: '✓',
      );
    }
    if (field.stageDuration != null) {
      return WorldStatus('Büyüyor', progress: field.overallProgress);
    }
    return selected ? const WorldStatus('Boş') : null;
  }

  static WorldStatus? factory(TeaFactory factory, {bool automated = false}) {
    if (factory.state == FactoryState.processing) {
      return WorldStatus('Üretim', progress: factory.progress);
    }
    return factory.dryTeaKg > 0
        ? WorldStatus('${factory.dryTeaKg} kg Kuru Çay', symbol: '✓')
        : automated
        ? WorldStatus(
            '${factory.rawTeaKg} / ${FactoryConfig.inputKg} kg',
            symbol: '•',
          )
        : null;
  }

  static WorldStatus? worker(Worker worker, {bool selected = false}) {
    if (worker.state == WorkerState.working) {
      return const WorldStatus('Hasat', symbol: '✂');
    }
    if (selected) return WorldStatus(worker.name);
    if (worker.state == WorkerState.movingToJob) {
      return const WorldStatus('', symbol: '•');
    }
    return null;
  }

  static WorldStatus? vehicle(
    TransportVehicle vehicle, {
    bool selected = false,
  }) =>
      selected ||
          vehicle.cargoKg > 0 ||
          vehicle.state == VehicleState.loading ||
          vehicle.state == VehicleState.unloading
      ? WorldStatus(
          '${vehicle.cargoKg} / ${vehicle.capacityKg} kg',
          symbol: '▣',
        )
      : null;
}
