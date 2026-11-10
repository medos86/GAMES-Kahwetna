import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio/sounds.dart';
import 'core/layout/device_metrics.dart';
import 'core/theme/app_colors.dart';
import 'features/chkobba/chkobba_screen.dart';
import 'features/coinche/coinche_screen.dart';
import 'features/domino/domino_screen.dart';
import 'features/ludo/ludo_screen.dart';
import 'features/menu/main_menu_screen.dart';
import 'features/menu/menu_models.dart';
import 'features/splash/splash_screen.dart';

/// Lancer avec `flutter run --dart-define=PROBE=true` pour afficher l'écran de contrôle des tailles.
const bool kSizeProbe = bool.fromEnvironment('PROBE');

final _navigatorKey = GlobalKey<NavigatorState>();

/// Plein écran immersif (barre de navigation Android et barre d'état masquées,
/// elles reviennent au glissement depuis le bord) et portrait uniquement.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Sons chargés dès l'ouverture de l'application, pour qu'ils soient prêts au premier coup.
  Sounds.preload();
  runApp(const KahwetneApp());
}

/// Relie le menu aux écrans de jeu (Chkobba, Domino, Belote = Coinche).
void _onPlay(LaunchRequest request) {
  if (request.game.name == 'Ludo') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => LudoScreen(
          difficulty: request.difficulty,
          players: request.players,
        ),
      ),
    );
    return;
  }
  if (request.game.name == 'Belote') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => CoincheScreen(
          difficulty: request.difficulty,
          targetScore: request.target,
        ),
      ),
    );
    return;
  }
  if (request.game.name == 'Chkobba') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => ChkobbaScreen(
          difficulty: request.difficulty,
          targetScore: request.target,
        ),
      ),
    );
    return;
  }
  if (request.game.name == 'Domino') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => DominoScreen(
          difficulty: request.difficulty,
          targetScore: request.target,
        ),
      ),
    );
    return;
  }
}

class KahwetneApp extends StatelessWidget {
  const KahwetneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Kahwetne',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.destructive,
        ),
      ),
      home: kSizeProbe
          ? const SizeProbeScreen()
          : const SplashScreen(next: MainMenuScreen(onPlay: _onPlay)),
    );
  }
}

/// Écran de contrôle : affiche la taille de l'appareil et les valeurs calculées.
class SizeProbeScreen extends StatelessWidget {
  const SizeProbeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final m = DeviceMetrics(width: size.width, height: size.height);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            '${m.width.toStringAsFixed(0)} × ${m.height.toStringAsFixed(0)}\n'
            'compact : ${m.isCompact}\n'
            'game-unit : ${m.gameUnit.toStringAsFixed(1)}\n'
            'carte Rami : ${m.ramiHandCardWidth.toStringAsFixed(1)}\n'
            'carte Coinche : ${m.coincheCardWidth.toStringAsFixed(1)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.foreground, fontSize: 18, height: 1.5),
          ),
        ),
      ),
    );
  }
}
