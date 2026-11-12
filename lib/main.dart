import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/game_routes.dart';
import 'core/audio/sounds.dart';
import 'core/layout/device_metrics.dart';
import 'core/services/ad_free_service.dart';
import 'core/services/toast.dart';
import 'core/i18n/app_language.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/comic_theme.dart';
import 'core/theme/game_style.dart';
import 'features/comic_demo/comic_demo_screen.dart';
import 'features/menu/main_menu_screen.dart';
import 'features/menu/menu_models.dart';
import 'features/splash/splash_screen.dart';

/// Lancer avec `flutter run --dart-define=PROBE=true` pour afficher l'écran de contrôle des tailles.
const bool kSizeProbe = bool.fromEnvironment('PROBE');

/// Lancer avec `flutter run --dart-define=COMIC_DEMO=true` pour afficher la page de démo BD (issue #98).
const bool kComicDemo = bool.fromEnvironment('COMIC_DEMO');

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

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
  // Langue sauvegardée relue avant le premier écran (#116).
  await loadLanguage();
  // Échéance du mode sans pub relue avant le premier écran : pas de bannière qui clignote au démarrage.
  await AdFreeService.instance.load();
  runApp(const KahwetneApp());
}

/// Le menu envoie la partie choisie vers sa route ; un jeu sans écran n'est jamais ignoré en silence.
void _onPlay(LaunchRequest request) {
  if (gameForRoute(request.game.route) == null) {
    final messenger = _messengerKey.currentState;
    if (messenger != null) showToastOn(messenger, 'Bientôt disponible');
    return;
  }
  _navigatorKey.currentState?.pushNamed(request.location);
}

class KahwetneApp extends StatelessWidget {
  const KahwetneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => MaterialApp(
        locale: localeOf(language),
        // Arabe : mise en page en RTL. Les cartes et le plateau restent gérés par leurs écrans.
        builder: (context, child) => Directionality(
          textDirection:
              isRtl(language) ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        ),
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        onGenerateRoute: (settings) => buildGameRoute(settings.name),
        debugShowCheckedModeBanner: false,
        title: 'Kahwetne',
        theme: kComicStyle
            ? buildComicTheme()
            : ThemeData(
                brightness: Brightness.dark,
                scaffoldBackgroundColor: AppColors.background,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  secondary: AppColors.secondary,
                  error: AppColors.destructive,
                ),
              ),
        home: kComicDemo
            ? const ComicDemoScreen()
            : kSizeProbe
                ? const SizeProbeScreen()
                : const SplashScreen(next: MainMenuScreen(onPlay: _onPlay)),
      ),
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
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
