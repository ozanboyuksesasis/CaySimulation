import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Missing or invalid PNGs become labelled placeholders; no image is modified.
class AssetCatalog {
  final Images images = Images(prefix: 'assets/images/');
  final Map<String, Sprite?> _sprites = {};
  final List<String> warnings = [];
  Future<void> load(Iterable<String> paths) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();
    for (final path in paths.toSet()) {
      if (!available.contains('assets/images/$path')) {
        warnings.add('Eksik görsel: $path');
        _sprites[path] = null;
        continue;
      }
      try {
        _sprites[path] = Sprite(await images.load(path));
      } catch (error) {
        warnings.add('Görsel yüklenemedi: $path');
        debugPrint('Asset $path: $error');
        _sprites[path] = null;
      }
    }
  }

  Sprite? sprite(String? path) => _sprites[path];
  void dispose() => images.clearCache();
}
