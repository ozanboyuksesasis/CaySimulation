import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../features/workers/worker.dart';
import '../features/workers/worker_component.dart';
import '../features/workers/turhan_visual.dart';
import '../features/workers/havva_visual.dart';
import '../features/ui/game_screen.dart';
import 'components/world_entity.dart';
import 'models/entity_definition.dart';
import 'systems/asset_catalog.dart';
import 'systems/depth_sorter.dart';
import 'systems/game_assets.dart';
import 'world/isometric_grid.dart';

/// Isolated observation fixture. Never constructed by normal gameplay.
class TurhanTestScene extends FlameGame {
  TurhanTestScene({this.workerId = 'turhan'});
  final String workerId;
  String get workerName => workerId == 'havva' ? 'Havva' : 'Turhan';
  String get workerAsset =>
      workerId == 'havva' ? GameAssets.farmerFemale : GameAssets.farmerMale;
  final grid = const IsometricGrid();
  final catalog = AssetCatalog();
  late final worker = Worker(
    id: workerId,
    name: workerName,
    gridPosition: const GridPoint(6, 7),
  );
  final status = ValueNotifier('Görseller yükleniyor');
  final objects = <WorldEntity>[];
  late WorkerComponent actor;
  bool running = true;
  bool readyForTest = false;
  static const route = [
    GridPoint(10, 7),
    GridPoint(10, 3),
    GridPoint(6, 3),
    GridPoint(6, 7),
  ];
  int _target = 0;
  double _rest = 1;
  final center = const IsometricGrid().toWorld(const GridPoint(8, 5));
  @override
  Color backgroundColor() => const Color(0xFF385D46);
  @override
  Future<void> onLoad() async {
    await catalog.load([
      workerAsset,
      GameAssets.farmerHouse,
      ...(workerId == 'havva'
              ? HavvaVisualConfig.frames
              : TurhanVisualConfig.frames)
          .values
          .map((f) => f.asset),
    ]);
    await world.add(_RouteGrid(grid));
    final house = WorldEntity(
      definition: const EntityDefinition(
        id: 'test-house',
        name: 'Çiftlik Evi',
        kind: EntityKind.building,
        gridPosition: GridPoint(7, 4),
        footprint: Footprint(2, 2),
        visualSize: ui.Size(245, 235),
        assetPath: GameAssets.farmerHouse,
      ),
      grid: grid,
      sprite: catalog.sprite(GameAssets.farmerHouse),
    );
    actor = WorkerComponent(
      definition: EntityDefinition(
        id: workerId,
        name: workerName,
        kind: EntityKind.character,
        gridPosition: const GridPoint(6, 7),
        footprint: const Footprint(1, 1),
        visualSize: const ui.Size(62, 95),
        assetPath: workerAsset,
      ),
      grid: grid,
      worker: worker,
      catalog: catalog,
      sprite: catalog.sprite(workerAsset),
    );
    objects.addAll([house, actor]);
    await world.addAll(objects);
    camera.viewfinder.position = Vector2(center.dx, center.dy - 30);
    camera.viewfinder.zoom = 1.6;
    readyForTest = true;
  }

  @override
  void update(double dt) {
    if (readyForTest && running) {
      if (_rest > 0) {
        _rest -= dt;
        worker.state = WorkerState.idle;
      } else {
        final target = route[_target];
        final dx = target.x - worker.gridPosition.x,
            dy = target.y - worker.gridPosition.y;
        final distance = math.sqrt(dx * dx + dy * dy);
        final travel = worker.movementSpeed * dt;
        worker.state = WorkerState.movingToJob;
        if (travel >= distance) {
          worker.gridPosition = target;
          _target = (_target + 1) % route.length;
          _rest = .7;
          worker.state = WorkerState.idle;
        } else {
          worker.gridPosition = GridPoint(
            worker.gridPosition.x + dx * travel / distance,
            worker.gridPosition.y + dy * travel / distance,
          );
        }
      }
      worker.changed();
    }
    if (readyForTest) DepthSorter().sort(objects);
    super.update(dt);
    if (readyForTest) {
      final text =
          'Yön: ${actor.visual.direction.name.toUpperCase()} • Görsel: ${actor.visual.state == WorkerVisualState.walk ? 'Yürüyor' : 'Bekliyor'} • Kare: ${actor.visual.frameName}\nSeçili: ${actor.selected ? workerName : 'Yok'} • Yönlü kareler: ${actor.directionalSpritesEnabled ? 'Açık' : 'Kapalı'}';
      if (status.value != text) status.value = text;
    }
  }

  void pick(Offset point) {
    if (!readyForTest) return;
    final worldPoint =
        Offset(camera.viewfinder.position.x, camera.viewfinder.position.y) +
        (point - Offset(size.x / 2, size.y / 2)) / camera.viewfinder.zoom;
    actor.selected = actor.hitTest(worldPoint);
  }

  void disposeState() {
    worker.dispose();
    status.dispose();
    catalog.dispose();
  }
}

class _RouteGrid extends Component {
  _RouteGrid(this.grid) : super(priority: -100);
  final IsometricGrid grid;
  @override
  void render(ui.Canvas canvas) {
    for (var x = 3; x <= 12; x++) {
      for (var y = 1; y <= 10; y++) {
        canvas.drawPath(
          grid.footprintPath(
            GridPoint(x.toDouble(), y.toDouble()),
            const Footprint(1, 1),
          ),
          ui.Paint()
            ..color = const Color(0x337EC89C)
            ..style = ui.PaintingStyle.stroke,
        );
      }
    }
    canvas.drawPath(
      ui.Path()..addPolygon([
        grid.toWorld(const GridPoint(6, 7)),
        ...TurhanTestScene.route.map(grid.toWorld),
      ], true),
      ui.Paint()
        ..color = const Color(0xFFDFD184)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

class TurhanTestScreen extends StatefulWidget {
  const TurhanTestScreen({super.key, this.workerId = 'turhan'});
  final String workerId;
  @override
  State<TurhanTestScreen> createState() => _TurhanTestScreenState();
}

class _TurhanTestScreenState extends State<TurhanTestScreen> {
  late final scene = TurhanTestScene(workerId: widget.workerId);
  @override
  void dispose() {
    scene.pauseEngine();
    scene.disposeState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (event) => scene.pick(event.localPosition),
            child: GameWidget(game: scene),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${scene.workerName.toUpperCase()} • GELİŞTİRME GÖRSEL TESTİ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'SE → NE → NW → SW • 140 ms/kare • Şeffaf final kareler',
                ),
                ValueListenableBuilder(
                  valueListenable: scene.status,
                  builder: (_, value, _) => Text(value),
                ),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () =>
                          setState(() => scene.running = !scene.running),
                      child: Text(scene.running ? 'Duraklat' : 'Devam Et'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        if (scene.readyForTest) {
                          scene.actor.directionalSpritesEnabled =
                              !scene.actor.directionalSpritesEnabled;
                        }
                      },
                      child: const Text('Yönlü kareleri aç/kapat'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const GameScreen(),
                        ),
                      ),
                      child: const Text('Normal Oyuna Dön'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
