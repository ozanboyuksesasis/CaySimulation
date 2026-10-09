import 'package:flutter/material.dart';

import '../buildings/tea_factory.dart';
import '../transport/transport_job.dart';
import '../transport/transport_system.dart';

class FactoryInfoPanel extends StatelessWidget {
  const FactoryInfoPanel({
    required this.factory,
    this.manualControls = true,
    super.key,
  });
  final bool manualControls;
  final TeaFactory factory;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: factory,
    builder: (_, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Durum: ${factory.canStartProduction ? 'Üretime Hazır' : factoryStateNames[factory.state]}',
        ),
        Text('Yaş Çay Stoğu: ${factory.rawTeaKg} kg'),
        Text('Kuru Çay Stoğu: ${factory.dryTeaKg} kg'),
        if (factory.state == FactoryState.processing) ...[
          const SizedBox(height: 6),
          const Text('Üretim'),
          LinearProgressIndicator(
            value: factory.progress,
            semanticsLabel: 'Üretim ilerlemesi',
          ),
          Text(
            '%${(factory.progress * 100).floor()} • Kalan süre: ${(factory.remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil()} sn',
          ),
        ] else ...[
          const SizedBox(height: 6),
          if (factory.missingInputKg > 0)
            Text(
              'Üretim için ${factory.missingInputKg} kg daha yaş çay gerekiyor.',
            ),
          if (manualControls && factory.canStartProduction)
            FilledButton(
              key: const ValueKey('start-production'),
              onPressed: factory.startProduction,
              child: const Text('Üretimi Başlat'),
            ),
        ],
      ],
    ),
  );
}

class CollectionCenterPanel extends StatelessWidget {
  const CollectionCenterPanel({
    required this.transport,
    this.manualControls = true,
    super.key,
  });
  final bool manualControls;
  final TransportSystem transport;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([transport, transport.center]),
    builder: (_, _) {
      final job = transport.latestShipment;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Durum: Açık'),
          Text('Teslim Alınan Yaş Çay: ${transport.center.receivedTeaKg} kg'),
          if (transport.factory == null) const Text('Çay Fabrikası gerekli.'),
          if (manualControls &&
              transport.factory != null &&
              transport.center.receivedTeaKg > 0 &&
              !transport.shipmentPending)
            FilledButton(
              key: const ValueKey('ship-to-factory'),
              onPressed: transport.requestFactoryShipment,
              child: const Text('Fabrikaya Sevk Et'),
            ),
          if (job?.isActive == true) ...[
            Text(switch (job!.status) {
              JobStatus.queued => 'Sevkiyat: Taşıma sırası bekliyor',
              JobStatus.movingToSource ||
              JobStatus.assigned => 'Sevkiyat: Çay Kamyonu geliyor',
              JobStatus.loading => 'Sevkiyat: Yükleniyor',
              JobStatus.movingToDestination =>
                'Sevkiyat: Çay Fabrikasına gidiyor',
              JobStatus.unloading => 'Sevkiyat: Fabrikaya teslim ediliyor',
              _ => 'Sevkiyat: Kamyon bekleniyor',
            }),
            Text('Sevk miktarı: ${job.requestedAmountKg} kg'),
            if (job.status == JobStatus.loading)
              LinearProgressIndicator(
                value: transport.progress(job),
                semanticsLabel: 'Sevkiyat yükleme ilerlemesi',
              ),
          ],
          if (job?.status == JobStatus.failed) Text(job!.failureMessage!),
        ],
      );
    },
  );
}
