import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/ui/game_screen.dart';
import 'game/cay_game.dart' show GameMapMode;
import 'game/turhan_test_scene.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const CayApp());
}

class CayApp extends StatelessWidget {
  const CayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Çay Simülasyonu',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF83AE82),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    ),
    home:
        const [
          'turhan',
          'havva',
        ].contains(Uri.base.queryParameters['visualTest'])
        ? TurhanTestScreen(workerId: Uri.base.queryParameters['visualTest']!)
        : GameScreen(
            mapMode: Uri.base.queryParameters['map'] == 'dev'
                ? GameMapMode.devTest
                : GameMapMode.newGame,
          ),
  );
}
