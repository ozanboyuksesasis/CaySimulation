import 'package:flutter/material.dart';

import '../../game/cay_game.dart';
import '../workers/worker.dart';

class BusinessControls extends StatelessWidget {
  const BusinessControls({required this.game, required this.id, super.key});
  final CayGame game;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      game.retail,
      game.economy,
      game.progression,
      game.jobs,
      game.transport,
      if (game.retail.packaging != null) game.retail.packaging!,
      if (game.retail.shop != null) game.retail.shop!,
    ]),
    builder: (_, _) {
      final p = game.retail.packaging,
          s = game.retail.shop,
          w = game.workforce.byId(id);
      final options = game.upgrades.options(id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p?.id == id) ...[
            Text(
              p!.processing
                  ? 'Paketleme · %${(p.progress * 100).floor()}'
                  : p.output.availableSpace < 20
                  ? 'Paket deposu dolu'
                  : game.retail.industrialConnected
                  ? 'Kuru çay bekliyor'
                  : 'Fabrika yol bağlantısı gerekli',
            ),
            if (p.processing) LinearProgressIndicator(value: p.progress),
            Text('İşlenen: ${p.inputKg} kg'),
            Text(
              'Paket stok: ${p.output.quantityUnits} / ${p.output.capacityUnits}',
            ),
            const Text(
              '20 kg → 20 × 1 kg · Tesis içi aktarım',
              style: TextStyle(fontSize: 11),
            ),
          ],
          if (s?.id == id) ...[
            Text('Reyon: ${s!.shelf.stockUnits} / ${s.shelf.capacityUnits}'),
            Text('Satılan: ${s.soldUnits} paket'),
            Text('Satış geliri: ${s.revenue} Altın'),
            if (!game.retail.retailConnected)
              const Text('Paketleme yol bağlantısı gerekli'),
          ],
          if (w != null) Text('Gelişim Puanı: ${w.developmentPoints}'),
          if (options.isNotEmpty || w != null)
            OutlinedButton(
              key: const ValueKey('open-upgrades'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                builder: (_) => _UpgradeSheet(game: game, id: id),
              ),
              child: const Text('Geliştir'),
            ),
        ],
      );
    },
  );
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({required this.game, required this.id});
  final CayGame game;
  final String id;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      game.economy,
      game.progression,
      game.jobs,
      game.transport,
      game.retail,
      if (game.workforce.byId(id) != null) game.workforce.byId(id)!,
    ]),
    builder: (_, _) {
      final w = game.workforce.byId(id);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              children: [
                const Expanded(child: Text('Geliştirmeler')),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Kapat',
                ),
              ],
            ),
            if (w != null) ...[
              Text('${w.name} · ${w.developmentPoints} Gelişim Puanı'),
              if (game.progression.level < 3)
                const Text('İşçi geliştirme Seviye 3’te açılır.'),
              for (final harvest in [true, false])
                ListTile(
                  title: Text(harvest ? 'Hasat Hızı +%3' : 'Hareket Hızı +%2'),
                  subtitle: const Text('1 Gelişim Puanı'),
                  trailing: FilledButton(
                    onPressed:
                        game.progression.level < 3 ||
                            w.developmentPoints <= 0 ||
                            w.state != WorkerState.idle
                        ? null
                        : () => game.notifications.show(
                            game.upgrades.developWorker(id, harvest: harvest),
                          ),
                    child: const Text('Geliştir'),
                  ),
                ),
            ],
            for (final option in game.upgrades.options(id))
              ListTile(
                title: Text('${option.label} · Sv. ${option.level}'),
                subtitle: Text(
                  game.upgrades.blocked(id, option) ??
                      '${option.current} → ${option.next}\n${option.cost} Altın',
                ),
                trailing: FilledButton(
                  onPressed: game.upgrades.blocked(id, option) != null
                      ? null
                      : () {
                          game.notifications.show(
                            game.upgrades.buy(id, option.id),
                          );
                          Navigator.pop(context);
                        },
                  child: const Text('Geliştir'),
                ),
              ),
          ],
        ),
      );
    },
  );
}
