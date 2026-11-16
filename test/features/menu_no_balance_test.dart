import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #118 : la somme d'argent fictive n'est plus affichée dans le menu principal.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('menu principal sans solde de pièces', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainMenuScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 250'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
