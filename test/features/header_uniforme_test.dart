// En-tête uniforme (#657) : une seule coupe avec le score cible, teintée par la difficulté,
// et plus de pastille de difficulté dans les jeux.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/widgets/difficulty_chip.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('#657 : la coupe prend la couleur de la difficulté choisie', () {
    expect(difficultyTint(Difficulty.facile), const Color(0xFFFFE16B));
    expect(difficultyTint(Difficulty.moyen), const Color(0xFFFF8A4C));
    expect(difficultyTint(Difficulty.difficile), const Color(0xFF9B8CFF));
  });

  testWidgets(
    '#657 : la coupe accepte une teinte',
    (tester) async {
      final tint = difficultyTint(Difficulty.moyen);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrophyBadge(target: 11, tint: tint),
          ),
        ),
      );
      await tester.pump();
      final badge = tester.widget<TrophyBadge>(find.byType(TrophyBadge));
      expect(badge.tint, tint);
    },
  );

  testWidgets(
    '#657 : Rami n\'affiche plus de pastille de difficulté',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
        ),
      );
      await tester.pump();
      expect(find.byType(DifficultyChip), findsNothing);
      expect(find.byType(TrophyBadge), findsOneWidget);
    },
  );

  testWidgets(
    '#657 : Ludo n\'affiche plus de pastille de difficulté',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LudoScreen(difficulty: Difficulty.facile, players: 2),
        ),
      );
      await tester.pump();
      expect(find.byType(DifficultyChip), findsNothing);
    },
  );
}
