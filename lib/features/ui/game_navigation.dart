import 'dart:async';

import 'package:flutter/foundation.dart';

import '../builder/build_catalog.dart';

enum GamePanel { none, shop, inventory, business }

class GameNavigation extends ChangeNotifier {
  GameNavigation({required this.beforeOpen});
  final VoidCallback beforeOpen;
  GamePanel _panel = GamePanel.none;
  GamePanel get panel => _panel;
  BuildCategory category = BuildCategory.agriculture;
  void openCatalog(BuildCategory value) {
    category = value;
    open(GamePanel.inventory);
  }

  void selectCategory(BuildCategory value) {
    category = value;
    notifyListeners();
  }

  final _opened = StreamController<GamePanel>.broadcast(sync: true);
  Stream<GamePanel> get opened => _opened.stream;
  void open(GamePanel panel) {
    beforeOpen();
    _panel = panel;
    _opened.add(panel);
    notifyListeners();
  }

  void close() {
    if (_panel == GamePanel.none) return;
    _panel = GamePanel.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _opened.close();
    super.dispose();
  }
}
