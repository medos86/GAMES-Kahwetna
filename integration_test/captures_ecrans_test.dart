// Captures d'écran sur émulateur (issue #206).
// Lancé par .github/workflows/captures_emulateur.yml via `flutter drive`.
// Chaque écran est ouvert, laissé quelques secondes, puis capturé.
// Encoche simulée : une marge haute de 36 px est imposée à MediaQuery, comme le ferait
// une caméra découpée. Les écrans doivent la respecter (boutons sous la caméra, pas dessous).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_rules_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/settings/settings_screen.dart';

const _encocheHaute = 36.0;

Widget _avecEncoche(Widget ecran) {
  return MaterialApp(
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final padding = EdgeInsets.only(top: _encocheHaute);
      return MediaQuery(
        data: media.copyWith(padding: padding, viewPadding: padding),
        child: child!,
      );
    },
    home: ecran,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final ecrans = <String, Widget Function()>{
    'menu': () => const MainMenuScreen(),
    'parametres': () => const SettingsScreen(),
    'chkobba_regles': () => const ChkobbaRulesScreen(),
    'chkobba': () =>
        const ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
  };

  for (final entry in ecrans.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await tester.pumpWidget(_avecEncoche(entry.value()));
      // pump et non pumpAndSettle : certains écrans ont des animations en boucle.
      await tester.pump(const Duration(seconds: 3));
      // Obligatoire sur Android avant une capture (#214).
      await binding.convertFlutterSurfaceToImage();
      await binding.takeScreenshot(entry.key);
    });
  }
}
