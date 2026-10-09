import 'dart:async';

import 'package:flutter/foundation.dart';

class GameNotifications extends ChangeNotifier {
  String? message;
  Timer? _timer;
  bool _rewardInCurrentAction = false;

  /// Keep the earned XP visible when the same UI action also reports success.
  void showReward(String text) {
    _rewardInCurrentAction = false;
    show(text);
    _rewardInCurrentAction = true;
    scheduleMicrotask(() => _rewardInCurrentAction = false);
  }

  void show(String text) {
    if (_rewardInCurrentAction) return;
    _timer?.cancel();
    message = text;
    notifyListeners();
    _timer = Timer(const Duration(seconds: 3), () {
      message = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
