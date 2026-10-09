import 'dart:ui';

import 'package:flame/components.dart';

import '../../game/systems/asset_catalog.dart';

import '../../game/components/world_entity.dart';
import '../../game/world/isometric_grid.dart';
import 'worker.dart';
import 'turhan_visual.dart';
import 'havva_visual.dart';

class WorkerComponent extends WorldEntity {
  WorkerComponent({
    required super.definition,
    required super.grid,
    required super.sprite,
    required this.worker,
    this.catalog,
    this.directionalSpritesEnabled = true,
  });
  final Worker worker;
  final AssetCatalog? catalog;
  bool directionalSpritesEnabled;
  late final WorkerDirectionalVisual visual = worker.id == 'havva'
      ? WorkerDirectionalVisual(
          worker.gridPosition,
          frames: HavvaVisualConfig.frames,
          walkCycle: HavvaVisualConfig.walkCycle,
        )
      : TurhanVisual(worker.gridPosition);
  bool get usesDirectionalSprites =>
      (worker.id == 'turhan' || worker.id == 'havva') &&
      directionalSpritesEnabled &&
      catalog != null;
  @override
  void update(double dt) {
    visual.update(
      worker.gridPosition,
      moving:
          worker.state == WorkerState.movingToJob ||
          worker.state == WorkerState.returning ||
          worker.isStrolling,
      dt: dt,
      grid: grid,
    );
    final target = worker.workFacingTarget;
    if (worker.state == WorkerState.working && target != null) {
      visual.faceTarget(worker.gridPosition, target, grid);
    }
    super.update(dt);
  }

  @override
  void renderSprite(Canvas canvas) {
    if (!usesDirectionalSprites) {
      super.renderSprite(canvas);
      return;
    }
    final frame = visual.frame;
    final artwork = catalog!.sprite(frame.asset);
    if (artwork == null) {
      super.renderSprite(canvas);
      return;
    }
    final scale = frame.scaleFor(size.y);
    // Stable render/hit box; clipping empty margins does not edit the PNG.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    artwork.render(
      canvas,
      position: Vector2(
        size.x / 2 - frame.feetX * scale,
        size.y - frame.feetY * scale,
      ),
      size: artwork.srcSize * scale,
    );
    canvas.restore();
  }

  @override
  Offset get groundPosition => grid.toWorld(worker.gridPosition);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    worker.addListener(_sync);
    _sync();
  }

  void _sync() => setGridPosition(
    GridPoint(worker.gridPosition.x - 0.5, worker.gridPosition.y - 0.5),
  );
  @override
  void onRemove() {
    worker.removeListener(_sync);
    super.onRemove();
  }
}
