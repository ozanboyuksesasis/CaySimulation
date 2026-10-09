import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cay_simulasyonu/game/cay_game.dart';
import 'package:cay_simulasyonu/features/builder/build_catalog.dart';
import 'package:cay_simulasyonu/features/ui/player_panels.dart';
import 'package:cay_simulasyonu/features/ui/factory_info_panel.dart';

void main() {
  testWidgets(
    'Motor stays visible and disabled until level six, then updates live',
    (tester) async {
      final game = CayGame(initialGold: 10000, guidedTutorial: false);
      addTearDown(game.disposeState);
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      game.panels.openCatalog(BuildCategory.equipment);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerPanels(game: game)),
        ),
      );
      final button = find.byKey(const ValueKey('acquire-teaHarvesterMotor'));
      expect(find.text("Seviye 6'da açılır"), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(find.text('Mağaza'), findsNothing);
      game.progression.award('test-unlock', 1250);
      await tester.pump();
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
      expect(find.text("Seviye 6'da açılır"), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Automatic building panels expose stock but no repetitive commands',
    (tester) async {
      final game = CayGame(
        initialGold: 10000,
        guidedTutorial: false,
        mapMode: GameMapMode.devTest,
        automationEnabled: true,
      );
      addTearDown(game.disposeState);
      game.collectionCenter.receive(25);
      game.factory.receiveRawTea(100);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CollectionCenterPanel(
                  transport: game.transport,
                  manualControls: game.manualControls,
                ),
                FactoryInfoPanel(
                  factory: game.factory,
                  manualControls: game.manualControls,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Fabrikaya Sevk Et'), findsNothing);
      expect(find.text('Üretimi Başlat'), findsNothing);
      expect(find.text('Yaş Çay Stoğu: 100 kg'), findsOneWidget);
      expect(find.text('Teslim Alınan Yaş Çay: 25 kg'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
