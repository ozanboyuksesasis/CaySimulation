import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/features/plantation/field_visuals.dart';
import 'package:cay_simulasyonu/game/systems/asset_catalog.dart';
import 'package:cay_simulasyonu/game/systems/game_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Her tarla durumunun PNG dış köşeleri şeffaf ve nesnesi görünür',
    () async {
      for (final path in fieldAssets.values.toSet()) {
        final bytes = await rootBundle.load('assets/images/$path');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final lastRow = (image.height - 1) * image.width;
        for (final pixel in [
          0,
          image.width - 1,
          lastRow,
          lastRow + image.width - 1,
        ]) {
          expect(rgba.getUint8(pixel * 4 + 3), 0, reason: path);
        }
        var visiblePixels = 0;
        for (var i = 3; i < rgba.lengthInBytes; i += 4) {
          if (rgba.getUint8(i) > 0) visiblePixels++;
        }
        expect(visiblePixels, greaterThan(image.width * image.height * 0.2));
        expect(visiblePixels, lessThan(image.width * image.height * 0.9));
        image.dispose();
        codec.dispose();
      }
    },
  );

  test('Kabul edilen parçalar gerçek PNG olarak yüklenir', () async {
    final catalog = AssetCatalog();
    await catalog.load(GameAssets.preparedPieces);
    expect(catalog.warnings, isEmpty);
    for (final path in GameAssets.preparedPieces) {
      expect(catalog.sprite(path), isNotNull, reason: path);
    }
    catalog.dispose();
  });

  test(
    'Runtime manifest master setleri ve reddedilen kırpımları paketlemez',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final paths = manifest.listAssets();
      expect(
        paths.where((p) => p.contains('dev_assets') || p.contains('original/')),
        isEmpty,
      );
      final excluded = RegExp(
        r'(25_DIRT|26_STONE|27_STONE|28_STREAM|29_TEA_SACK|30_TEA_BASKET|37_TEA_PACKAGE|40_DECORATION)',
      );
      expect(paths.where(excluded.hasMatch), isEmpty);
      expect(
        paths.where(
          (p) =>
              p.contains('tea_packages/') ||
              p.contains('tiles/streams/') ||
              p.contains('tiles/walls/'),
        ),
        isEmpty,
      );
      expect(
        paths,
        isNot(contains('assets/images/tiles/roads/road_straight_vertical.png')),
      );
    },
  );
}
