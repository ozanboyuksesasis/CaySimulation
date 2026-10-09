import 'package:flame/game.dart';

import '../features/plantation/tea_field_component.dart';

import 'package:flutter/material.dart';

import 'cay_game.dart';
import 'systems/game_assets.dart';
import 'world/isometric_grid.dart';
import '../features/builder/build_catalog.dart';
import '../features/plantation/plantation_config.dart';
import '../features/workers/worker.dart';
import '../features/workers/worker_component.dart';
import '../features/workers/equipment.dart';
import '../features/ui/game_screen.dart';

/// Development fixture using actual jobs. Normal acquisition is untouched.
class HarvestTestGame extends CayGame {
  HarvestTestGame(this.mode)
    : super(guidedTutorial: false, automationEnabled: false) {
    progression.award('visual-fixture', 100);
    for (final point in [const GridPoint(5, 5), const GridPoint(5, 8)]) {
      builder.choose(catalogItem('field'));
      builder.preview(point);
      if (!builder.confirm()) {
        throw StateError(builder.feedback ?? 'Test tarlası yerleştirilemedi.');
      }
    }
    for (var i = 0; i < 2; i++) {
      workforce.registerFixture(
        Worker(
          id: i == 0 ? 'turhan' : 'havva',
          name: i == 0 ? 'Turhan' : 'Havva',
          assetPath: i == 0 ? GameAssets.farmerMale : GameAssets.farmerFemale,
          gridPosition: i == 0
              ? const GridPoint(3.5, 6.5)
              : const GridPoint(7.5, 9.5),
          equipment: mode == 'Motor' || (mode == 'Karma' && i == 1)
              ? EquipmentType.teaHarvesterMotor
              : EquipmentType.teaShears,
        ),
      );
    }
    for (final field in plantation.fields) {
      plantation.plant(field);
    }
    plantation.advance(PlantationConfig.growthDuration);
    for (final field in plantation.fields) {
      jobs.requestHarvest(field);
    }
  }
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _focus();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isWorldReady) _focus();
  }

  void _focus() {
    camera.viewfinder.zoom = size.y < 450 ? .82 : 1.15;
    camera.viewfinder.position = Vector2(-96, size.y < 450 ? 370 : 400);
  }

  final String mode;
  bool running = false, effects = true;
  final status = ValueNotifier('Başlat düğmesine dokun.');
  @override
  void update(double dt) {
    super.update(running ? dt : 0);
    if (!isWorldReady) return;
    final labels = <String>[];
    for (final field in entities.whereType<TeaFieldComponent>()) {
      field.harvestEffectsEnabled = effects;
    }
    for (final actor in entities.whereType<WorkerComponent>()) {
      actor.harvestEffectsEnabled = effects;
      final label = actor.harvest.active
          ? 'Hasat %${(actor.harvest.progress * 100).round()}'
          : workerStateNames[actor.worker.state]!;
      labels.add(
        '${actor.worker.name}: $label · ${actor.visual.direction.name.toUpperCase()}',
      );
    }
    final stock = plantation.fields.fold(0, (s, f) => s + f.harvestedStockKg);
    labels.add('Tarla stoğu: $stock kg');
    final next = labels.join(' | ');
    if (status.value != next) status.value = next;
  }

  @override
  void disposeState() {
    status.dispose();
    super.disposeState();
  }
}

class HarvestTestScreen extends StatefulWidget {
  const HarvestTestScreen({super.key});
  @override
  State<HarvestTestScreen> createState() => _HarvestTestScreenState();
}

class _HarvestTestScreenState extends State<HarvestTestScreen> {
  HarvestTestGame game = HarvestTestGame('Makas');
  void restart(String mode) {
    final old = game;
    old.pauseEngine();
    setState(() => game = HarvestTestGame(mode));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      old.disposeState();
    });
  }

  @override
  void dispose() {
    game.pauseEngine();
    game.disposeState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (e) => game.selectAt(e.localPosition),
            child: GameWidget(key: ObjectKey(game), game: game),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xDD17332F),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HASAT GÖRSEL TESTİ · Gerçek görevler'),
                  ValueListenableBuilder(
                    valueListenable: game.status,
                    builder: (_, value, _) =>
                        Text(value, style: const TextStyle(fontSize: 12)),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final mode in ['Makas', 'Motor', 'Karma'])
                          TextButton(
                            onPressed: () => restart(mode),
                            child: Text(mode),
                          ),
                        TextButton(
                          onPressed: () => restart(game.mode),
                          child: const Text('Yeniden'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              setState(() => game.running = !game.running),
                          child: Text(game.running ? 'Duraklat' : 'Başlat'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => game.effects = !game.effects),
                          child: Text(
                            'Efektler: ${game.effects ? 'Açık' : 'Kapalı'}',
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GameScreen(),
                                ),
                              ),
                          child: const Text('Normal Oyun'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
