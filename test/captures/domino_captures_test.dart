// Captures du Domino (#1050, #1051, #1052) : FR et AR, 360×780 dp.
// Hors shards de test/ (voir analyze.yml) : seul le workflow « Captures Domino » les exécute.
// Les PNG sont générés par la CI, pas en local.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpDomino(WidgetTester tester, AppLanguage language) async {
    appLanguage.value = language;
    // 360×780 dp : physique = 720×1560 à dpr 2.
    tester.view.physicalSize = const Size(360 * 2, 780 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('capture Domino en français', (tester) async {
    await pumpDomino(tester, AppLanguage.fr);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/domino_fr.png'),
    );
  });

  testWidgets('capture Domino en arabe', (tester) async {
    await pumpDomino(tester, AppLanguage.ar);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/domino_ar.png'),
    );
  });
}
