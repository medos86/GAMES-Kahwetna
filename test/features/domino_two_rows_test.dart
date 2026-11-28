import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Domino : la main (pierres) est sur une rangée, avatar/score/pioche sur une autre (#1062).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Domino : libellé de la main au-dessus de la rangée avatar/score',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
        ),
      );
      await tester.pump();

      final handLabel = find.textContaining('PIERRES');
      final seatName = find.text(t('you'));
      expect(handLabel, findsOneWidget);
      expect(seatName, findsWidgets);

      // La rangée de la main (défilement horizontal) est entièrement au-dessus du score.
      final handRowBottom =
          tester.getBottomLeft(find.byType(ListView).first).dy;
      final seatTop = tester.getTopLeft(seatName.first).dy;
      expect(seatTop, greaterThan(handRowBottom));
    },
  );
}
