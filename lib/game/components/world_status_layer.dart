import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cay_game.dart';
import '../systems/world_status.dart';
import '../systems/game_assets.dart';
import '../../features/plantation/tea_field_component.dart';
import '../../features/workers/worker_component.dart';
import '../../features/workers/harvest_job.dart' show JobStatus;
import '../../features/transport/vehicle_component.dart';

/// A separate overlay keeps small labels above sprites without changing depth.
class WorldStatusLayer extends Component {
  WorldStatusLayer(this.game) : super(priority: 900000);
  final CayGame game;
  final _text = TextPainter(textDirection: TextDirection.ltr);
  @override
  void render(Canvas canvas) {
    final zoom = game.navigation.zoom;
    for (final entity in game.entities) {
      if (entity.previewHidden) continue;
      final WorldStatus? status;
      if (entity is TeaFieldComponent) {
        final job = game.jobs.jobForField(entity.field.id);
        status = entity.completionRemaining > 0
            ? WorldStatus('+${entity.completedKg} kg Yaş Çay', sack: true)
            : WorldStatus.field(
                entity.field,
                automated: game.automation.enabled,
                harvestProgress: job?.status == JobStatus.inProgress
                    ? game.jobs.progress(job!)
                    : null,
                harvestActive:
                    game.jobs.jobForField(entity.field.id)?.status ==
                    JobStatus.inProgress,
                transportActive:
                    game.transport.jobForField(entity.field.id)?.isActive ==
                        true &&
                    game.transport.jobForField(entity.field.id)?.status !=
                        JobStatus.queued,
                selected:
                    entity.selected ||
                    game.tutorial?.targetEntityId == entity.definition.id,
              );
      } else if (entity is WorkerComponent) {
        status = entity.harvest.active && !entity.selected
            ? null
            : WorldStatus.worker(entity.worker, selected: entity.selected);
      } else if (entity is VehicleComponent) {
        status = WorldStatus.vehicle(entity.vehicle, selected: entity.selected);
      } else if (entity.definition.id == game.retail.packaging?.id) {
        final p = game.retail.packaging!;
        status = WorldStatus(
          p.processing ? 'Paketleme' : '${p.output.quantityUnits} paket',
          progress: p.processing ? p.progress : null,
          symbol: '•',
        );
      } else if (entity.definition.id == game.retail.shop?.id) {
        final s = game.retail.shop!;
        status = WorldStatus(
          s.saleFeedbackRemaining > Duration.zero
              ? '+150 Altın'
              : s.shelf.stockUnits == 0
              ? 'Stok Yok'
              : 'Reyon ${s.shelf.stockUnits}/${s.shelf.capacityUnits}',
          symbol: '•',
        );
      } else if (entity.definition.id == game.activeFactory?.id) {
        status = WorldStatus.factory(
          game.activeFactory!,
          automated: game.automation.enabled,
        );
      } else if (entity.definition.id == game.activeCollectionCenter?.id &&
          game.collectionCenter.receivedTeaKg > 0) {
        status = WorldStatus(
          game.activeFactory == null
              ? 'Fabrika Gerekli'
              : '${game.collectionCenter.receivedTeaKg} kg · Sevkiyat',
          symbol: '•',
        );
      } else {
        status = null;
      }
      if (status == null) continue;
      final detailed = zoom >= .6;
      final label = detailed ? status.label : '';
      final icon = status.symbol.isNotEmpty || status.sack;
      if (!detailed && !icon && status.progress == null) {
        continue;
      }
      final p = entity.visualBounds.topCenter;
      canvas.save();
      canvas.translate(p.dx, p.dy - 8 / zoom);
      canvas.scale(1 / zoom);
      _text.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFFFEDBC),
          fontWeight: FontWeight.w600,
        ),
      );
      _text.layout();
      final width = (status.progress != null
          ? 72.0
          : _text.width + (icon ? 22 : 0) + 12);
      final height = detailed ? (status.progress != null ? 27.0 : 22.0) : 16.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-width / 2, -height, width, height),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xE617332F),
      );
      if (status.sack) {
        game.assetCatalog
            .sprite(GameAssets.teaSackFull)
            ?.render(
              canvas,
              position: Vector2(-width / 2 + 3, -height + 2),
              size: Vector2.all(height - 4),
            );
      } else if (status.symbol.isNotEmpty) {
        final x = -width / 2 + 6, y = -height / 2;
        final paint = Paint()
          ..color = const Color(0xFFADE29C)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        if (status.symbol == '✓') {
          canvas.drawLine(Offset(x, y), Offset(x + 4, y + 4), paint);
          canvas.drawLine(Offset(x + 4, y + 4), Offset(x + 11, y - 4), paint);
        } else {
          canvas.drawCircle(Offset(x + 5, y), 3, paint);
        }
      }
      if (label.isNotEmpty) {
        _text.paint(
          canvas,
          Offset(-_text.width / 2 + (icon ? 8 : 0), -height + 3),
        );
      }
      if (status.progress != null) {
        final bar = Rect.fromLTWH(-width / 2 + 5, -7, width - 10, 4);
        canvas.drawRect(bar, Paint()..color = const Color(0xFF4E655A));
        canvas.drawRect(
          Rect.fromLTWH(
            bar.left,
            bar.top,
            bar.width * status.progress!,
            bar.height,
          ),
          Paint()..color = const Color(0xFFADE29C),
        );
      }
      canvas.restore();
    }
  }

  @override
  void onRemove() {
    _text.dispose();
    super.onRemove();
  }
}
