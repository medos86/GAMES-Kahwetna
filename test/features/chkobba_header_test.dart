import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/difficulty_chip.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chkobba utilise le socle d'en-tête commun (#242), comme Rami : Menu à gauche,
/// règles et score cible (coupe, #657) à droite.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Chkobba : en-tête commun, Menu visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
        ),
      );
      await tester.pump();
      expect(find.byType(GameScaffold), findsOneWidget);
      expect(find.byType(GameHeader), findsOneWidget);
      expect(find.text(Strings.menuLabel), findsOneWidget);
      // #657 : plus de pastille de difficulté, la coupe porte le score cible.
      expect(
        find.descendant(
          of: find.byType(GameHeader),
          matching: find.byType(DifficultyChip),
        ),
        findsNothing,
      );
      expect(find.byType(TrophyBadge), findsOneWidget);
    },
  );
}
