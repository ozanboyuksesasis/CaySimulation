import 'dart:math' as math;
import 'dart:ui';

import 'equipment.dart';
import 'harvest_job.dart';
import 'worker.dart';
import 'worker_visual.dart';

abstract final class HarvestVisualConfig {
  static const shearsCycleSeconds = .56;
  static const motorCycleSeconds = .32;
  static const maxParticles = 10;
  static const particleLifetime = .52;
  static const detailZoom = .65;
  static const completionSeconds = 1.8;
  // Coordinates in the existing 62 x 95 worker render box, never logical space.
  static const hands = {
    WorkerVisualDirection.se: Offset(43, 57),
    WorkerVisualDirection.sw: Offset(19, 57),
    WorkerVisualDirection.ne: Offset(43, 52),
    WorkerVisualDirection.nw: Offset(19, 52),
  };
  static Offset hand(WorkerVisualDirection direction, String workerId) =>
      hands[direction]! +
      (workerId == 'havva' ? const Offset(0, 3) : Offset.zero);
}

/// Read-only projection of a real job. There is no secondary harvest clock.
class HarvestVisual {
  HarvestVisual(this.worker, this.currentJob);
  final Worker worker;
  final HarvestJob? Function() currentJob;
  HarvestJob? get activeJob {
    final job = currentJob();
    return worker.state == WorkerState.working &&
            worker.canHarvest &&
            job?.status == JobStatus.inProgress &&
            job?.id == worker.assignedJobId &&
            job?.assignedWorkerId == worker.id
        ? job
        : null;
  }

  bool get active => activeJob != null;
  bool get motor => worker.equipment == EquipmentType.teaHarvesterMotor;
  double get seconds => (activeJob?.worked.inMicroseconds ?? 0) / 1e6;
  double get progress {
    final j = activeJob;
    return j == null || j.harvestDuration.inMicroseconds <= 0
        ? 0
        : (j.worked.inMicroseconds / j.harvestDuration.inMicroseconds).clamp(
            0.0,
            1.0,
          );
  }

  double get cycleSeconds => motor
      ? HarvestVisualConfig.motorCycleSeconds
      : HarvestVisualConfig.shearsCycleSeconds;
  double get phase => seconds / cycleSeconds % 1;
  double get pulse => active ? (1 - math.cos(phase * math.pi * 2)) / 2 : 0;
  int particleCount(double zoom) =>
      !active || zoom < HarvestVisualConfig.detailZoom
      ? 0
      : motor
      ? HarvestVisualConfig.maxParticles
      : 6;
  double particleAge(int slot) =>
      (seconds - cycleSeconds * .35 - slot * .012) % cycleSeconds;
}

/// Fixed bounded procedural drawing: no spawned components, timers or assets.
class HarvestEffectPainter {
  final Paint _paint = Paint();
  final Path _leaf = Path()
    ..moveTo(-3, 0)
    ..quadraticBezierTo(0, -3, 4, 0)
    ..quadraticBezierTo(0, 3, -3, 0)
    ..close();

  void render(
    Canvas canvas,
    HarvestVisual v,
    WorkerVisualDirection direction,
    double zoom,
    String workerId,
  ) {
    if (!v.active) return;
    final hand = HarvestVisualConfig.hand(direction, workerId);
    final right =
        direction == WorkerVisualDirection.se ||
        direction == WorkerVisualDirection.ne;
    final rear =
        direction == WorkerVisualDirection.ne ||
        direction == WorkerVisualDirection.nw;
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.scale(right ? 1 : -1, 1);
    canvas.rotate(rear ? -.35 : .25);
    // Local foliage response at the cutting point; the field itself never shifts.
    _paint.style = PaintingStyle.fill;
    _paint.color = Color.fromRGBO(136, 207, 91, .12 + v.pulse * .15);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(15, 5),
        width: 22 + v.pulse * 4,
        height: 8,
      ),
      _paint,
    );
    if (v.motor) {
      final vibration = math.sin(v.seconds * 95) * .7;
      canvas.translate(0, vibration);
      _paint.color = const Color(0xFFB55835);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -4, 10, 8),
          const Radius.circular(2),
        ),
        _paint,
      );
      _paint.color = const Color(0xFFCDD5C0);
      canvas.drawRect(const Rect.fromLTWH(6, -2, 18, 4), _paint);
      _paint.strokeWidth = 1.5;
      for (var i = 0; i < 6; i++) {
        final x = 7.0 + i * 3;
        canvas.drawLine(Offset(x, 1), Offset(x + 1, 4 + v.pulse), _paint);
      }
      _paint.color = const Color(0xFF263B35);
      canvas.drawCircle(const Offset(1, 0), 2, _paint);
    } else {
      _paint.strokeWidth = 2;
      _paint.strokeCap = StrokeCap.round;
      final gap = 1.0 + (1 - v.pulse) * 5;
      _paint.color = const Color(0xFFD8E2D7);
      canvas.drawLine(const Offset(0, 0), Offset(17, -gap), _paint);
      canvas.drawLine(const Offset(0, 0), Offset(17, gap), _paint);
      _paint.color = const Color(0xFFA56F3E);
      canvas.drawLine(const Offset(-6, -3), const Offset(0, 0), _paint);
      canvas.drawLine(const Offset(-6, 3), const Offset(0, 0), _paint);
      _paint.color = const Color(0xFF566853);
      canvas.drawCircle(Offset.zero, 2, _paint);
    }
    final count = v.particleCount(zoom);
    for (var i = 0; i < count; i++) {
      if (v.seconds < v.cycleSeconds * .35 + i * .012) continue;
      final age = v.particleAge(i),
          life = age / HarvestVisualConfig.particleLifetime;
      if (life >= 1) continue;
      canvas.save();
      canvas.translate(
        14 + (i % 3 - 1) * 4 + age * (i.isEven ? 9 : -8),
        3 - age * (22 + i % 4 * 4) + age * age * 18,
      );
      canvas.rotate(i + age * 3);
      _paint.color = Color.fromRGBO(
        i.isEven ? 123 : 77,
        i.isEven ? 192 : 154,
        65,
        (1 - life) * .85,
      );
      canvas.drawPath(_leaf, _paint);
      canvas.restore();
    }
    canvas.restore();
  }
}
