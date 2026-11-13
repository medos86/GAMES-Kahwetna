import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Domino utilise le socle d'en-tête commun (#242) : Menu à gauche, manche au centre.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Domino : en-tête commun, Menu et manche visibles', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
      ),
    );
    await tester.pump();
    expect(find.byType(GameHeader), findsOneWidget);
    expect(find.text(Strings.menuLabel), findsOneWidget);
    expect(find.textContaining('Manche'), findsOneWidget);
  });
}
