import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rami utilise le socle d'en-tête commun (#242) : Menu à gauche, manche au centre, règles et score à droite.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Rami : en-tête commun, Menu visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
        ),
      );
      await tester.pump();
      expect(find.byType(GameScaffold), findsOneWidget);
      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text(Strings.menuLabel), findsOneWidget);
    },
  );
}
