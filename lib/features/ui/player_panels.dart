import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/cay_game.dart';
import '../builder/build_catalog.dart';
import '../buildings/tea_factory.dart';
import '../workers/workforce_state.dart';
import '../workers/equipment.dart';
import 'game_navigation.dart';
import 'game_hud.dart' show formatGold;

class PlayerPanels extends StatefulWidget {
  const PlayerPanels({required this.game, super.key});
  final CayGame game;
  @override
  State<PlayerPanels> createState() => _PlayerPanelsState();
}

class _PlayerPanelsState extends State<PlayerPanels> {
  BuildCategory get category => game.panels.category;
  bool get unified => game.mapMode == GameMapMode.newGame;
  CayGame get game => widget.game;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      game.panels,
      game.builder,
      game.playerInventory,
      game.economy,
      game.settlement,
      game.workforce,
      game.retail,
      game.progression,
      if (game.tutorial != null) game.tutorial!,
    ]),
    builder: (_, _) {
      if (game.builder.isPlacing) return const SizedBox.shrink();
      final panel = game.panels.panel;
      return Stack(
        children: [
          if (panel != GamePanel.none)
            Positioned(
              left: 12,
              right: 12,
              bottom: 62,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Material(
                    color: const Color(0xFA17332F),
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: math.min(
                        216,
                        (MediaQuery.sizeOf(context).height -
                                MediaQuery.paddingOf(context).vertical) *
                            (MediaQuery.sizeOf(context).height < 450
                                ? .42
                                : .36),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 48,
                              child: Row(
                                children: [
                                  if (panel == GamePanel.business)
                                    const Text('İşletme Özeti'),
                                  if (panel == GamePanel.shop ||
                                      (unified && panel == GamePanel.inventory))
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            for (final value
                                                in BuildCategory.values)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: ChoiceChip(
                                                  label: Text(
                                                    categoryNames[value]!,
                                                  ),
                                                  selected: category == value,
                                                  onSelected: (_) => game.panels
                                                      .selectCategory(value),
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .padded,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!(panel == GamePanel.shop ||
                                      (unified &&
                                          panel == GamePanel.inventory)))
                                    const Spacer(),
                                  IconButton(
                                    tooltip: 'Paneli kapat',
                                    onPressed: game.panels.close,
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: switch (panel) {
                                GamePanel.shop => _catalog(false),
                                GamePanel.inventory =>
                                  unified ? _unifiedCatalog() : _catalog(true),
                                _ => BusinessPanel(game: game),
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Center(
              child: Material(
                color: const Color(0xF517332F),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!unified)
                        _nav(GamePanel.shop, 'Mağaza', Icons.storefront),
                      _nav(
                        GamePanel.inventory,
                        'Envanter',
                        Icons.inventory_2_outlined,
                      ),
                      _nav(GamePanel.business, 'İşletme', Icons.query_stats),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  Widget _nav(GamePanel panel, String title, IconData icon) => TextButton.icon(
    key: ValueKey('nav-${panel.name}'),
    style: TextButton.styleFrom(
      minimumSize: const Size(112, 48),
      backgroundColor: game.panels.panel == panel
          ? const Color(0xFF385B48)
          : Colors.transparent,
    ),
    onPressed: () => game.panels.panel == panel
        ? game.panels.close()
        : game.panels.open(panel),
    icon: Icon(icon, size: 22),
    label: Text(title),
  );
  Widget _catalog(bool inventory) {
    final items = game.shop.catalog
        .where(
          (item) => inventory
              ? game.playerInventory.quantity(item.id) > 0
              : item.category == category,
        )
        .toList();
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Envanterin boş. Mağazadan bir yapı satın al.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final item = items[index];
        final owned = game.shop.ownedCount(item);
        final limit = game.shop.atLimit(item);
        return Container(
          key: ValueKey('${inventory ? 'inventory' : 'shop'}-${item.id}'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF27443A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/${item.assetPath}',
                width: 72,
                height: 78,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      inventory
                          ? 'Adet: ${game.playerInventory.quantity(item.id)}'
                          : '${formatGold(item.goldCost)} Altın',
                      style: const TextStyle(color: Color(0xFFFFD879)),
                    ),
                    if (!inventory)
                      Text(
                        'Sahip olunan: $owned${item.uniqueLimit != null ? ' • Sınır: ${item.uniqueLimit}' : ''}',
                      ),
                    if (!inventory)
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: ValueKey('${inventory ? 'place' : 'buy'}-${item.id}'),
                onPressed: !inventory && limit
                    ? null
                    : () {
                        if (inventory) {
                          game.builder.choose(item);
                          game.notifications.show(
                            'Yerleştirme için uygun alan seç.',
                          );
                        } else {
                          final result = game.shop.buy(item.id);
                          game.notifications.show(result.message);
                        }
                      },
                child: Text(
                  inventory
                      ? 'Yerleştir'
                      : limit
                      ? 'Zaten sahip'
                      : 'Satın Al',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _unifiedCatalog() {
    final cards = <Widget>[];
    if (category == BuildCategory.workers) {
      for (final offer in workerCatalog) {
        final locked = game.workforce.hireRestriction(offer);
        final owned = game.workforce.byId(offer.id) != null;
        cards.add(
          _acquisitionCard(
            offer.id,
            offer.name,
            offer.assetPath,
            WorkerOffer.cost,
            locked ?? (owned ? 'İşletmede' : 'İşe alınabilir'),
            owned
                ? 'İşletmede'
                : locked != null
                ? 'Kilitli'
                : 'İşe Al',
            owned || locked != null
                ? null
                : () {
                    game.notifications.show(
                      game.workforce.hire(offer.id).message,
                    );
                  },
          ),
        );
      }
    } else if (category == BuildCategory.equipment) {
      for (final item in equipmentCatalog) {
        final locked =
            game.unlocks.restriction(item.requiredLevel) ??
            game.workforce.purchaseRestriction?.call(item.cost, item.type.name);
        final available = game.playerInventory.equipmentQuantity(item.type);
        final used = game.workforce.workers
            .where((w) => w.equipment == item.type)
            .length;
        cards.add(
          _acquisitionCard(
            item.type.name,
            item.name,
            item.assetPath,
            item.cost,
            locked ??
                'Sahip: ${available + used} • Kullanımda: $used • Boşta: $available',
            locked == null ? 'Satın Al' : 'Kilitli',
            locked != null
                ? null
                : () => game.notifications.show(
                    game.workforce.buyEquipment(item.type).message,
                  ),
          ),
        );
      }
    } else {
      for (final item in game.shop.catalog.where(
        (i) => i.category == category,
      )) {
        final count = game.settlement.structures
            .where((s) => s.item.id == item.id)
            .length;
        final limit = item.uniqueLimit != null && count >= item.uniqueLimit!;
        final locked =
            game.unlocks.restriction(item.requiredLevel) ??
            game.builder.purchaseRestriction?.call(item.goldCost, item.id);
        cards.add(
          _acquisitionCard(
            item.id,
            item.displayName,
            item.assetPath,
            item.goldCost,
            locked ??
                'Kurulu: $count${item.uniqueLimit == null ? '' : ' / ${item.uniqueLimit}'}',
            locked != null
                ? 'Kilitli'
                : limit
                ? 'Sınıra Ulaşıldı'
                : item.buildType == BuildType.road
                ? 'İnşa Et'
                : 'Kur',
            limit || locked != null
                ? null
                : () {
                    game.builder.choose(item);
                    game.notifications.show('Yerleştirme için uygun alan seç.');
                  },
          ),
        );
      }
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      children: cards,
    );
  }

  Widget _acquisitionCard(
    String id,
    String name,
    String asset,
    int cost,
    String description,
    String action,
    VoidCallback? onPressed,
  ) => Container(
    key: ValueKey('catalog-$id'),
    width: 310,
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF27443A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: SingleChildScrollView(
      child: Row(
        children: [
          Image.asset(
            'assets/images/$asset',
            width: 58,
            height: 64,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${formatGold(cost)} Altın',
                  style: const TextStyle(color: Color(0xFFFFD879)),
                ),
                Text(description, style: const TextStyle(fontSize: 11)),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: ValueKey('acquire-$id'),
                    onPressed: onPressed,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(90, 44),
                    ),
                    child: Text(action),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class BusinessPanel extends StatelessWidget {
  const BusinessPanel({required this.game, super.key});
  final CayGame game;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      game.retail,
      game.transport,
      game.economy,
      game.workforce,
      ...game.plantation.fields,
      if (game.activeFactory != null) game.activeFactory!,
      if (game.activeCollectionCenter != null) game.activeCollectionCenter!,
    ]),
    builder: (_, _) {
      final r = game.resources;
      return ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _line('Altın', formatGold(game.economy.balance)),
          _line('Çay Tarlası sayısı', '${game.plantation.fields.length}'),
          _line('İşçi sayısı', '${game.workforce.workers.length}'),
          _line('Araç sayısı', game.activeCollectionCenter == null ? '0' : '1'),
          _line(
            'Paketlemede Kuru Çay',
            '${game.retail.packaging?.inputKg ?? 0} kg',
          ),
          _line(
            'Paketleme Deposu',
            '${game.retail.packaging?.output.quantityUnits ?? 0} paket',
          ),
          _line('Reyonda', '${game.retail.shop?.shelf.stockUnits ?? 0} paket'),
          _line(
            'Müşteri Satışları',
            '${game.retail.shop?.soldUnits ?? 0} paket · ${game.retail.shop?.revenue ?? 0} Altın',
          ),
          const Divider(),
          _line('Toplam Yaş Çay', '${r.totalFreshKg} kg'),
          _line('Tarlalarda', '${r.fieldsKg} kg'),
          _line('Nakliyede', '${r.cargoKg} kg'),
          _line('Alım Yerinde', '${r.collectionKg} kg'),
          _line('Fabrikada Yaş Çay', '${r.factoryRawKg} kg'),
          _line('Üretimde İşlenen Yaş Çay', '${r.processingKg} kg'),
          _line('Fabrikada Kuru Çay', '${r.dryKg} kg'),
          if (game.activeFactory?.state == FactoryState.processing)
            const Text('Üretim devam ediyor'),
          const SizedBox(height: 8),
          const Text(
            'Çay, bulunduğu tarla, araç veya işletmede tutulur.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    },
  );
  Widget _line(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
