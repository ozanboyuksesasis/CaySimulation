import '../plantation/plantation_system.dart';
import '../transport/transport_system.dart';

/// Read-only projection; no cached or duplicated authoritative inventory.
class ResourceSummary {
  ResourceSummary(this.plantation, this.transport);
  final PlantationSystem plantation;
  final TransportSystem transport;
  int get fieldsKg =>
      plantation.fields.fold(0, (sum, f) => sum + f.harvestedStockKg);
  int get cargoKg => transport.vehicle.cargoKg;
  int get collectionKg => transport.collectionCenter?.receivedTeaKg ?? 0;
  int get factoryRawKg => transport.factory?.rawTeaKg ?? 0;
  int get processingKg => transport.factory?.processingInputKg ?? 0;
  int get dryKg => transport.factory?.dryTeaKg ?? 0;
  int get totalFreshKg =>
      fieldsKg + cargoKg + collectionKg + factoryRawKg + processingKg;
}
