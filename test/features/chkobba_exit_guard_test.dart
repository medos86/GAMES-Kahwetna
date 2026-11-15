import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #312 : quitter une partie de Chkobba (bouton Menu) doit demander
/// confirmation, comme les autres jeux.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Chkobba : Menu pendant une partie affiche le popup de sortie',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
        ),
      );
      await tester.pump();

      await tester.tap(find.text(Strings.menuLabel));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(Strings.exitGameTitle), findsOneWidget);
      expect(find.byType(ChkobbaScreen), findsOneWidget);

      await tester.tap(find.text(Strings.exitStay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ChkobbaScreen), findsOneWidget);
    },
  );
}
