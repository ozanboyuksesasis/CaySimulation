import 'dart:async';
import 'dart:ui';

/// A pan or second finger cancels the hold. Release never commits a move.
class WorldMoveGesture {
  WorldMoveGesture({required this.begin, required this.drag});
  final bool Function(Offset) begin;
  final void Function(Offset) drag;
  static const holdDuration = Duration(milliseconds: 450);
  static const panSlop = 12.0;
  final Set<int> _pointers = {};
  Timer? _timer;
  Offset? _origin;
  bool dragging = false;
  bool suppressTap = false;
  void down(int pointer, Offset point) {
    _pointers.add(pointer);
    if (_pointers.length != 1) {
      _timer?.cancel();
      dragging = false;
      suppressTap = true;
      return;
    }
    suppressTap = false;
    _origin = point;
    _timer = Timer(holdDuration, () {
      dragging = begin(point);
      suppressTap = true;
    });
  }

  void move(int pointer, Offset point) {
    if (_pointers.length != 1) return;
    if (dragging) {
      drag(point);
      return;
    }
    if (_origin != null && (point - _origin!).distance > panSlop) {
      _timer?.cancel();
      suppressTap = true;
    }
  }

  void up(int pointer) {
    _timer?.cancel();
    _pointers.remove(pointer);
    dragging = false;
  }

  void dispose() {
    _timer?.cancel();
    _pointers.clear();
  }
}
