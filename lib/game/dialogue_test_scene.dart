import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'cay_game.dart';
import 'world/isometric_grid.dart';
import 'systems/game_assets.dart';
import '../features/builder/build_catalog.dart';
import '../features/plantation/plantation_config.dart';
import '../features/workers/equipment.dart';
import '../features/workers/worker.dart';
import '../features/ui/game_screen.dart';

/// Preview buttons are development-only. Walking/harvesting use real jobs.
class DialogueTestGame extends CayGame {
  DialogueTestGame(this.mode)
    : super(guidedTutorial: false, automationEnabled: false) {
    builder.choose(catalogItem('field'));
    builder.preview(const GridPoint(5, 5));
    if (!builder.confirm()) throw StateError('Test tarlası yerleştirilemedi.');
    workforce.registerFixture(
      Worker(
        id: 'turhan',
        name: 'Turhan',
        gridPosition: mode == 'Yürüyüş'
            ? const GridPoint(.5, 7.5)
            : const GridPoint(4.5, 7.5),
        equipment: EquipmentType.teaShears,
      ),
    );
    workforce.registerFixture(
      Worker(
        id: 'havva',
        name: 'Havva',
        assetPath: GameAssets.farmerFemale,
        gridPosition: mode == 'Yürüyüş'
            ? const GridPoint(.5, 9.5)
            : const GridPoint(4.5, 8.5),
        equipment: EquipmentType.teaShears,
      ),
    );
    final f = plantation.fields.single;
    plantation.plant(f);
    plantation.advance(PlantationConfig.growthDuration);
    if (mode == 'Yürüyüş' || mode == 'Hasat') jobs.requestHarvest(f);
  }
  final String mode;
  bool running = true, _previewed = false;
  final status = ValueNotifier('Konuşma bekleniyor');
  final history = <String>[];
  Object? _lastSpeech;
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
    camera.viewfinder.zoom = .95;
    camera.viewfinder.position = Vector2(-150, 330);
  }

  @override
  void update(double dt) {
    super.update(running ? dt : 0);
    if (!isWorldReady) return;
    if (!_previewed && mode != 'Doğal') {
      final phrase = switch (mode) {
        'Turhan' => 'love',
        'Havva' => 'drizzle',
        'Yakında' => 'nearby',
        'Yürüyüş' => 'walk',
        _ => 'tired',
      };
      final id = mode == 'Havva' || mode == 'Yakında' ? 'havva' : 'turhan';
      _previewed = dialogue.preview(id, phrase);
    }
    final s = dialogue.active;
    if (s != null && !identical(_lastSpeech, s)) {
      history.add('${s.worker.name}: ${s.definition.text}');
      _lastSpeech = s;
    }
    final next = s == null
        ? 'Konuşma bekleniyor'
        : '${s.worker.name}: ${s.definition.text}';
    if (status.value != next) status.value = next;
  }

  @override
  void disposeState() {
    status.dispose();
    super.disposeState();
  }
}

class DialogueTestScreen extends StatefulWidget {
  const DialogueTestScreen({super.key});
  @override
  State<DialogueTestScreen> createState() => _DialogueTestScreenState();
}

class _DialogueTestScreenState extends State<DialogueTestScreen> {
  DialogueTestGame game = DialogueTestGame('Doğal');
  void restart(String mode) {
    final old = game;
    old.pauseEngine();
    setState(() => game = DialogueTestGame(mode));
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
            alignment: Alignment.bottomCenter,
            child: Container(
              color: const Color(0xEE17332F),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: game.status,
                    builder: (_, text, _) =>
                        Text(text, style: const TextStyle(fontSize: 12)),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in [
                          'Doğal',
                          'Turhan',
                          'Havva',
                          'Yakında',
                          'Yürüyüş',
                          'Hasat',
                        ])
                          TextButton(
                            onPressed: () => restart(m),
                            child: Text(m),
                          ),
                        TextButton(
                          onPressed: () =>
                              setState(() => game.running = !game.running),
                          child: Text(game.running ? 'Duraklat' : 'Devam Et'),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () =>
                                game.dialogue.enabled = !game.dialogue.enabled,
                          ),
                          child: Text(
                            'Konuşmalar: ${game.dialogue.enabled ? 'Açık' : 'Kapalı'}',
                          ),
                        ),
                        TextButton(
                          onPressed: () => game.camera.viewfinder.zoom = .45,
                          child: const Text('Uzak'),
                        ),
                        TextButton(
                          onPressed: () => game.camera.viewfinder.zoom = .95,
                          child: const Text('Normal'),
                        ),
                        TextButton(
                          onPressed: () => game.camera.viewfinder.zoom = 1.8,
                          child: const Text('Yakın'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GameScreen(),
                                ),
                              ),
                          child: const Text('Oyuna Dön'),
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
