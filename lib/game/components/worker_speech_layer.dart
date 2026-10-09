import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cay_game.dart';
import '../../features/workers/worker_component.dart';

/// Screen-sized world attachment: camera zoom never shrinks the text.
Rect speechBounds(Offset head, Size textSize, Size viewport) {
  final width = math.min(textSize.width + 20, viewport.width - 24);
  final height = textSize.height + 16;
  return Rect.fromLTWH(
    (head.dx - width / 2).clamp(
      12.0,
      math.max(12.0, viewport.width - width - 12),
    ),
    (head.dy - height - 12).clamp(
      56.0,
      math.max(56.0, viewport.height - height - 76),
    ),
    width,
    height,
  );
}

class WorkerSpeechLayer extends Component {
  WorkerSpeechLayer(this.game) : super(priority: 1000000);
  final CayGame game;
  final _text = TextPainter(textDirection: TextDirection.ltr, maxLines: 3);
  final _paint = Paint();
  String? _cachedText;
  double _cachedWidth = 0;
  @override
  void render(Canvas canvas) {
    final dialogue = game.dialogue, speech = dialogue.active;
    if (speech == null || dialogue.opacity <= 0 || game.dialogueSuppressed) {
      return;
    }
    WorkerComponent? actor;
    for (final e in game.entities) {
      if (e is WorkerComponent && e.worker == speech.worker) {
        actor = e;
        break;
      }
    }
    if (actor == null || actor.previewHidden) return;
    final viewport = game.navigation.viewport, zoom = game.navigation.zoom;
    final head =
        (actor.visualBounds.topCenter - game.navigation.center) * zoom +
        Offset(viewport.width / 2, viewport.height / 2);
    // Don't advertise workers outside the visible world.
    if (!Rect.fromLTWH(0, 0, viewport.width, viewport.height).contains(head)) {
      return;
    }
    final maxWidth = math.min(240.0, viewport.width - 44);
    if (_cachedText != speech.definition.text || _cachedWidth != maxWidth) {
      _cachedText = speech.definition.text;
      _cachedWidth = maxWidth;
      _text.text = TextSpan(
        text: _cachedText,
        style: const TextStyle(
          color: Color(0xFF263B32),
          fontSize: 13,
          height: 1.15,
          fontWeight: FontWeight.w500,
        ),
      );
      _text.layout(maxWidth: maxWidth);
    }
    final bounds = speechBounds(head, _text.size, viewport);
    // Existing contextual cards take precedence over personality feedback.
    if (game.selectedEntity.value != null &&
        bounds.overlaps(const Rect.fromLTWH(0, 48, 265, 290))) {
      return;
    }
    if (game.tutorial?.guided == true &&
        bounds.overlaps(Rect.fromLTWH(viewport.width - 305, 48, 305, 190))) {
      return;
    }
    canvas.saveLayer(
      bounds.inflate(12),
      _paint..color = Color.fromRGBO(255, 255, 255, dialogue.opacity),
    );
    canvas.translate(bounds.center.dx, bounds.bottom);
    canvas.scale(dialogue.scale);
    canvas.translate(-bounds.center.dx, -bounds.bottom);
    final tailX = head.dx.clamp(bounds.left + 12, bounds.right - 12);
    final tail = Path()
      ..moveTo(tailX - 5, bounds.bottom - 1)
      ..lineTo(tailX, bounds.bottom + 8)
      ..lineTo(tailX + 5, bounds.bottom - 1)
      ..close();
    _paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF2DB);
    canvas.drawPath(tail, _paint);
    final rounded = RRect.fromRectAndRadius(bounds, const Radius.circular(9));
    canvas.drawRRect(rounded, _paint);
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFA69B7C);
    canvas.drawRRect(rounded, _paint);
    _paint.style = PaintingStyle.fill;
    _text.paint(canvas, bounds.topLeft + const Offset(10, 8));
    canvas.restore();
  }

  @override
  void onRemove() {
    _text.dispose();
    super.onRemove();
  }
}
