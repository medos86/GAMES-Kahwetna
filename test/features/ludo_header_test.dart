import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ludo utilise le socle d'en-tête commun (#242) : Menu à gauche, joueurs au centre.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Ludo : en-tête commun, Menu visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LudoScreen(difficulty: Difficulty.facile, players: 2),
        ),
      );
      await tester.pump();
      expect(find.byType(GameScaffold), findsOneWidget);
      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text(Strings.menuLabel), findsOneWidget);
    },
  );
}
