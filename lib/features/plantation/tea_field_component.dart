import 'dart:ui';
import 'dart:math' as math;

import '../workers/harvest_job.dart';
import '../../game/components/world_entity.dart';
import '../../game/systems/asset_catalog.dart';
import 'field_visuals.dart';
import 'tea_field.dart';
import '../workers/harvest_visual.dart';

class TeaFieldComponent extends WorldEntity {
  TeaFieldComponent({
    required super.definition,
    required super.grid,
    required this.field,
    required this.catalog,
    this.currentJob,
    this.workerGround,
    this.actionCycle,
  });
  final TeaField field;
  final HarvestJob? Function()? currentJob;
  final Offset? Function()? workerGround;
  final double Function()? actionCycle;
  bool harvestEffectsEnabled = true;
  final _reactionPaint = Paint();
  @override
  void renderSprite(Canvas canvas) {
    super.renderSprite(canvas);
    final job = currentJob?.call();
    if (!harvestEffectsEnabled || job?.status != JobStatus.inProgress) return;
    final point = workerGround?.call();
    if (point == null) return;
    final x = (point.dx - visualBounds.left).clamp(size.x * .28, size.x * .72);
    final y = (point.dy - visualBounds.top - 30).clamp(
      size.y * .25,
      size.y * .57,
    );
    final phase =
        job!.worked.inMicroseconds /
        1e6 /
        (actionCycle?.call() ?? HarvestVisualConfig.shearsCycleSeconds);
    final pulse = (1 - math.cos(phase * math.pi * 2)) / 2;
    _reactionPaint.color = Color.fromRGBO(181, 235, 111, .08 + pulse * .19);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + (i - 1) * 9, y + (i % 2) * 4),
          width: 12 + pulse * 3,
          height: 6,
        ),
        _reactionPaint,
      );
    }
  }

  final AssetCatalog catalog;
  int _lastCount = 0, _lastStock = 0;
  int completedKg = 0;
  double completionRemaining = 0;
  @override
  void update(double dt) {
    completionRemaining = (completionRemaining - dt).clamp(
      0.0,
      HarvestVisualConfig.completionSeconds,
    );
    super.update(dt);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _lastCount = field.harvestCount;
    _lastStock = field.harvestedStockKg;
    field.addListener(_syncSprite);
    _syncSprite();
  }

  void _syncSprite() {
    if (field.harvestCount > _lastCount) {
      completedKg = field.harvestedStockKg - _lastStock;
      completionRemaining = HarvestVisualConfig.completionSeconds;
    }
    _lastCount = field.harvestCount;
    _lastStock = field.harvestedStockKg;
    sprite = catalog.sprite(fieldAssets[field.state]);
  }

  @override
  void onRemove() {
    field.removeListener(_syncSprite);
    super.onRemove();
  }
}
