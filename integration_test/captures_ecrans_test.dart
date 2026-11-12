// Captures d'écran sur émulateur (issue #206).
// Lancé par .github/workflows/captures_emulateur.yml via `flutter drive`.
// Chaque écran est ouvert, laissé quelques secondes, puis capturé.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_rules_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/settings/settings_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final ecrans = <String, Widget Function()>{
    'menu': () => const MainMenuScreen(),
    'parametres': () => const SettingsScreen(),
    'chkobba_regles': () => const ChkobbaRulesScreen(),
    'chkobba': () => const ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
  };

  for (final entry in ecrans.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      await tester.pumpWidget(MaterialApp(home: entry.value()));
      // pump et non pumpAndSettle : certains écrans ont des animations en boucle.
      await tester.pump(const Duration(seconds: 3));
      await binding.takeScreenshot(entry.key);
    });
  }
}
