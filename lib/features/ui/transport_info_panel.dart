import 'package:flutter/material.dart';

import '../plantation/tea_field.dart';
import '../transport/transport_system.dart';
import '../transport/transport_job.dart';
import '../transport/transport_vehicle.dart';

class FieldTransportPanel extends StatelessWidget {
  const FieldTransportPanel({
    required this.field,
    this.manualControls = true,
    required this.transport,
    super.key,
  });
  final TeaField field;
  final bool manualControls;
  final TransportSystem transport;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([field, transport]),
    builder: (_, _) {
      final job = transport.jobForField(field.id);
      final active = job?.isActive == true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.harvestedStockKg > 0 && !transport.hasCollectionCenter)
            const Text('Çay Alım Yeri gerekli.'),
          if (field.harvestedStockKg > 0 &&
              transport.hasCollectionCenter &&
              !transport.pickups.containsKey(field.id))
            const Text('Yol bağlantısı gerekli.'),
          if (!manualControls &&
              field.harvestedStockKg > 0 &&
              !active &&
              transport.hasCollectionCenter)
            const Text('Nakliye Bekliyor'),
          if (manualControls &&
              field.harvestedStockKg > 0 &&
              !active &&
              transport.hasCollectionCenter &&
              transport.pickups.containsKey(field.id))
            FilledButton(
              key: const ValueKey('transport-field'),
              onPressed: () => transport.requestTransport(field),
              child: const Text('Taşıma Emri Ver'),
            ),
          if (active) ...[
            const SizedBox(height: 6),
            Text(switch (job!.status) {
              JobStatus.queued => 'Nakliye: Taşıma sırası bekliyor',
              JobStatus.movingToSource ||
              JobStatus.assigned => 'Nakliye: Çay Kamyonu geliyor',
              JobStatus.loading => 'Nakliye: Yükleniyor',
              JobStatus.movingToDestination =>
                'Nakliye: Çay Alım Yerine gidiyor',
              JobStatus.unloading => 'Nakliye: Teslimat yapılıyor',
              _ => 'Nakliye: Kamyon bekleniyor',
            }),
            if (job.status == JobStatus.loading)
              LinearProgressIndicator(
                value: transport.progress(job),
                semanticsLabel: 'Yükleme ilerlemesi',
              ),
          ],
          if (job?.status == JobStatus.failed) Text(job!.failureMessage!),
        ],
      );
    },
  );
}

class VehicleInfoPanel extends StatelessWidget {
  const VehicleInfoPanel({
    required this.transport,
    this.showDebug = false,
    super.key,
  });
  final TransportSystem transport;
  final bool showDebug;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: transport,
    builder: (_, _) {
      final vehicle = transport.vehicle;
      final job = transport.currentJob;
      final loading = vehicle.state == VehicleState.loading;
      final unloading = vehicle.state == VehicleState.unloading;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (showDebug)
            Text(
              'Konum: (${vehicle.gridPosition.x.floor()}, ${vehicle.gridPosition.y.floor()})',
            ),
          Text(
            'Durum: ${loading && job?.isFactoryShipment == true ? 'Alım Yerinde yükleme yapılıyor' : vehicleStateNames[vehicle.state]}',
          ),
          if (showDebug) Text('Kapasite: ${vehicle.capacityKg} kg'),
          Text('Yük: ${vehicle.cargoKg} / ${vehicle.capacityKg} kg'),
          if (showDebug)
            Text(
              'Görev: ${job == null
                  ? 'Yok'
                  : job.isFactoryShipment
                  ? 'Fabrikaya yaş çay sevkiyatı'
                  : 'Yaş çay toplama'}',
            ),
          if (showDebug && job != null) ...[
            Text(
              'Kaynak: ${job.isFactoryShipment ? 'Çay Alım Yeri' : 'Çay Tarlası'}',
            ),
            Text(
              'Teslim noktası: ${job.isFactoryShipment ? 'Çay Fabrikası' : 'Çay Alım Yeri'}',
            ),
          ],
          if ((loading || unloading) && job != null) ...[
            Text(loading ? 'Yükleme' : 'Teslimat'),
            LinearProgressIndicator(
              value: transport.progress(job),
              semanticsLabel: loading
                  ? 'Yükleme ilerlemesi'
                  : 'Teslimat ilerlemesi',
            ),
            Text(
              '%${(transport.progress(job) * 100).floor()} • Kalan süre: ${((transport.timeToNextEvent?.inMilliseconds ?? 0) / 1000).ceil()} sn',
            ),
          ],
          if (vehicle.state == VehicleState.blocked) ...[
            Text(
              transport.failureMessage ?? 'Kamyon için uygun yol bulunamadı.',
            ),
            FilledButton(
              onPressed: transport.retryRoute,
              child: const Text('Yolu tekrar dene'),
            ),
          ],
        ],
      );
    },
  );
}
