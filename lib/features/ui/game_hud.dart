import 'package:flutter/material.dart';

import '../../game/cay_game.dart';
import '../plantation/tea_field_component.dart';
import 'field_info_panel.dart';
import '../workers/worker_component.dart';
import 'worker_info_panel.dart';
import '../transport/vehicle_component.dart';
import 'transport_info_panel.dart';
import 'factory_info_panel.dart';
import '../buildings/tea_factory.dart';
import '../builder/builder_system.dart';
import 'builder_overlay.dart';
import 'player_panels.dart';
import 'game_navigation.dart';
import 'tutorial_coach.dart';
import 'business_controls.dart';

String formatGold(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]}.',
);

class GameHud extends StatelessWidget {
  const GameHud({required this.game, this.onMapMode, super.key});
  final CayGame game;
  final ValueChanged<GameMapMode>? onMapMode;
  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xEF17332F),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF526C5C)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      game.settlement,
      game.builder,
      game.showGrid,
      game.panels,
      game.automation,
      if (game.tutorial != null) game.tutorial!,
    ]),
    builder: (_, _) => Stack(
      children: [
        Positioned(
          top: 4,
          left: 8,
          right: 8,
          child: Row(
            children: [
              _card(
                const Text(
                  'ÇAY SİMÜLASYONU',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: game.economy,
                builder: (_, _) => _card(
                  Text(
                    'Altın: ${formatGold(game.economy.balance)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD879),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: game.progression,
                builder: (_, _) => _card(
                  Text(
                    'Seviye ${game.progression.level} · ${game.progression.currentXp}/${game.progression.xpForNextLevel} XP',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Geliştirici araçları',
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  if (value == 'automation') {
                    game.automation.enabled = !game.automation.enabled;
                  }
                  if (value == 'grid') {
                    game.showGrid.value = !game.showGrid.value;
                  }
                  if (value == 'dev') onMapMode?.call(GameMapMode.devTest);
                  if (value == 'new') onMapMode?.call(GameMapMode.newGame);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'automation',
                    enabled: game.tutorialRules?.active != true,
                    child: Text(
                      'Otomasyon: ${game.automation.enabled ? 'Açık' : 'Kapalı'}',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'grid',
                    child: Text(
                      game.showGrid.value ? 'Izgarayı gizle' : 'Izgara',
                    ),
                  ),
                  if (onMapMode != null)
                    const PopupMenuItem(
                      value: 'dev',
                      child: Text('Test haritası (yeni oturum)'),
                    ),
                  if (onMapMode != null)
                    const PopupMenuItem(
                      value: 'new',
                      child: Text('Yeni oyun (yeni oturum)'),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (game.showGrid.value &&
            game.panels.panel == GamePanel.none &&
            !game.builder.isPlacing)
          Positioned(
            left: 16,
            right: 205,
            bottom: 78,
            child: IgnorePointer(
              child: _card(
                const Text(
                  'Sürükle: gezin  •  İki parmak: yakınlaş  •  Dokun: seç',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBCD0BD)),
                ),
              ),
            ),
          ),
        if (game.panels.panel == GamePanel.none && !game.builder.isPlacing)
          Positioned(
            right: 16,
            bottom: 76,
            child: _card(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Uzaklaş',
                    onPressed: () => _zoom(0.8),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: 'Haritayı ortala',
                    onPressed: game.navigation.reset,
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                  IconButton(
                    tooltip: 'Yakınlaş',
                    onPressed: () => _zoom(1.25),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 56,
          left: 8,
          bottom: 68,
          child: ValueListenableBuilder(
            valueListenable: game.selectedEntity,
            builder: (_, entity, _) {
              if (entity == null ||
                  game.builder.mode != BuilderMode.inactive ||
                  game.panels.panel != GamePanel.none) {
                return const SizedBox.shrink();
              }
              final footprint = entity.definition.footprint;
              return Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: _card(
                    SizedBox(
                      width: 190,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (game.showGrid.value)
                            const Text(
                              'SEÇİLİ NESNE',
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 1.5,
                                color: Color(0xFFA9C4AE),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entity.definition.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Seçimi kapat',
                                onPressed: () {
                                  entity.selected = false;
                                  game.selectedEntity.value = null;
                                },
                                icon: const Icon(Icons.close),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (game.showGrid.value &&
                              entity is! WorkerComponent &&
                              entity is! VehicleComponent)
                            Text(
                              'Konum: (${entity.gridPosition.x.toStringAsFixed(0)}, ${entity.gridPosition.y.toStringAsFixed(0)})',
                            ),
                          if (game.showGrid.value)
                            Text(
                              footprint == null
                                  ? 'Kapladığı alan: yok'
                                  : 'Kapladığı alan: ${footprint.columns} × ${footprint.rows} karo',
                            ),
                          if (entity is TeaFieldComponent)
                            FieldInfoPanel(
                              manualControls: game.manualControls,
                              field: entity.field,
                              system: game.plantation,
                              jobs: game.jobs,
                              notify: game.notifications.show,
                              showDebug: game.showGrid.value,
                            ),
                          if (entity is WorkerComponent)
                            WorkerInfoPanel(
                              jobs: game.jobs,
                              selectedWorker: entity.worker,
                              workforce: game.workforce,
                              notify: game.notifications.show,
                              showDebug: game.showGrid.value,
                            ),
                          if (entity is TeaFieldComponent)
                            FieldTransportPanel(
                              manualControls: game.manualControls,
                              field: entity.field,
                              transport: game.transport,
                            ),
                          if (entity is VehicleComponent)
                            VehicleInfoPanel(
                              transport: game.transport,
                              showDebug: game.showGrid.value,
                            ),
                          if (entity.definition.id ==
                              game.activeCollectionCenter?.id)
                            CollectionCenterPanel(
                              transport: game.transport,
                              manualControls: game.manualControls,
                            ),
                          if (entity.definition.id == game.activeFactory?.id)
                            FactoryInfoPanel(
                              factory: game.factory,
                              manualControls: game.manualControls,
                            ),
                          if (game.settlement
                                  .byId(entity.definition.id)
                                  ?.item
                                  .movable ==
                              true)
                            ListenableBuilder(
                              listenable: Listenable.merge([
                                game.jobs,
                                game.transport,
                                if (game.activeFactory != null)
                                  game.activeFactory!,
                              ]),
                              builder: (_, _) => GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: game.canMove(entity.definition.id)
                                    ? null
                                    : () {
                                        game.builder.startMove(
                                          entity.definition.id,
                                        );
                                        game.notifications.show(
                                          'Bu nesne şu anda taşınamaz.',
                                        );
                                      },
                                child: OutlinedButton.icon(
                                  onPressed: game.canMove(entity.definition.id)
                                      ? () => game.builder.startMove(
                                          entity.definition.id,
                                        )
                                      : null,
                                  icon: const Icon(Icons.open_with),
                                  label: const Text('Taşı'),
                                ),
                              ),
                            ),
                          BusinessControls(
                            game: game,
                            id: entity.definition.id,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 88,
          right: 16,
          child: ValueListenableBuilder(
            valueListenable: game.showGrid,
            builder: (_, enabled, _) => enabled
                ? _card(
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        game.fps,
                        game.selectedTile,
                        game.jobs,
                        game.transport,
                        if (game.activeFactory != null) game.activeFactory!,
                      ]),
                      builder: (_, _) {
                        final tile = game.selectedTile.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('FPS: ${game.fps.value}  •  20 × 20 karo'),
                            Text('Bekleyen iş: ${game.jobs.queuedCount}'),
                            Text(
                              'Fabrika sevkiyatı: ${game.transport.queuedShipmentCount}',
                            ),
                            Text(
                              'Fabrika: ${game.activeFactory?.rawTeaKg ?? 0} kg yaş / ${game.activeFactory?.dryTeaKg ?? 0} kg kuru',
                            ),
                            Text(
                              '${factoryStateNames[game.activeFactory?.state] ?? 'Fabrika yok'} • %${((game.activeFactory?.progress ?? 0) * 100).floor()}',
                            ),
                            Text(
                              'Bekleyen nakliye: ${game.transport.queuedCount}',
                            ),
                            Text(
                              'Kamyon: ${game.vehicle.gridPosition.x.floor()}, ${game.vehicle.gridPosition.y.floor()} • ${game.vehicle.cargoKg} kg',
                            ),
                            Text(
                              'Tarlalarda: ${game.plantation.fields.fold(0, (sum, f) => sum + f.harvestedStockKg)} kg',
                            ),
                            Text('İşçiler: ${game.workforce.workers.length}'),
                            Text(
                              tile == null
                                  ? 'Karo seçilmedi'
                                  : 'Karo: ${tile.x.toInt()}, ${tile.y.toInt()}',
                            ),
                            const Text(
                              'Mavi: araç yolu • Sarı: işçi yolu',
                              style: TextStyle(fontSize: 10),
                            ),
                            if (game.assetCatalog.warnings.isNotEmpty)
                              Text(
                                '${game.assetCatalog.warnings.length} görsel yerine geçici çizim',
                              ),
                          ],
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(child: PlayerPanels(game: game)),
        TutorialCoach(game: game),
        BuilderOverlay(game: game),
        Positioned(
          top: 48,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: game.notifications,
              builder: (_, _) => game.notifications.message == null
                  ? const SizedBox.shrink()
                  : Center(
                      child: _card(
                        Text(
                          game.notifications.message!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
  void _zoom(double factor) {
    if (!game.isWorldReady) return;
    final size = game.navigation.viewport;
    game.navigation.zoomAt(
      game.navigation.zoom * factor,
      Offset(size.width / 2, size.height / 2),
    );
  }
}
