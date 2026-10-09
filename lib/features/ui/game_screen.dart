import 'package:flame/game.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/cay_game.dart';
import 'game_hud.dart';
import 'world_move_gesture.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.mapMode = GameMapMode.newGame,
    this.guidedTutorial = true,
    this.initialGold,
    super.key,
  });
  final bool guidedTutorial;
  final int? initialGold;
  final GameMapMode mapMode;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final game = CayGame(
    mapMode: widget.mapMode,
    guidedTutorial: widget.guidedTutorial,
    initialGold: widget.initialGold,
  );
  double _startZoom = 1;
  Offset? _previousFocal;
  late final _moveGesture = WorldMoveGesture(
    begin: game.beginTouchMove,
    drag: game.dragTouchMove,
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      game.builder.cancel();
      return true;
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      game.resumeEngine();
    } else {
      game.pauseEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    game.pauseEngine();
    _moveGesture.dispose();
    game.disposeState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        game.builder.cancel();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MouseRegion(
              onHover: (event) => game.previewAt(event.localPosition),
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == kSecondaryMouseButton) {
                    game.builder.cancel();
                  } else {
                    _moveGesture.down(event.pointer, event.localPosition);
                  }
                },
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent && game.isWorldReady) {
                    GestureBinding.instance.pointerSignalResolver.register(
                      event,
                      (signal) {
                        game.navigation.wheel(
                          event.scrollDelta.dy,
                          event.localPosition,
                        );
                      },
                    );
                  }
                },
                onPointerMove: (event) =>
                    _moveGesture.move(event.pointer, event.localPosition),
                onPointerUp: (event) => _moveGesture.up(event.pointer),
                onPointerCancel: (event) => _moveGesture.up(event.pointer),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (event) {
                    if (!_moveGesture.suppressTap) {
                      game.tapAt(event.localPosition);
                    }
                  },
                  onScaleStart: (event) {
                    _startZoom = game.navigation.zoom;
                    _previousFocal = event.localFocalPoint;
                  },
                  onScaleUpdate: (event) {
                    if (!game.isWorldReady) return;
                    if (_moveGesture.dragging) {
                      _previousFocal = event.localFocalPoint;
                      return;
                    }
                    final previous = _previousFocal;
                    if (previous != null) {
                      game.navigation.pan(event.localFocalPoint - previous);
                    }
                    game.navigation.zoomAt(
                      _startZoom * event.scale,
                      event.localFocalPoint,
                    );
                    _previousFocal = event.localFocalPoint;
                  },
                  onScaleEnd: (_) => _previousFocal = null,
                  child: GameWidget(
                    game: game,
                    loadingBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, error) =>
                        Center(child: Text('Dünya yüklenemedi: $error')),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: GameHud(
                game: game,
                onMapMode: (mode) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(mapMode: mode),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
