import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #313 : pioche et défausse forment une barre horizontale (côte à côte).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Rami : pioche et défausse côte à côte sur la même ligne',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
        ),
      );
      await tester.pump();

      final pioche = tester.getRect(find.byType(RamiBackView).first);
      final defausse = tester.getRect(find.byType(RamiCardView).first);

      expect(pioche.center.dx, lessThan(defausse.center.dx));
      expect((pioche.center.dy - defausse.center.dy).abs(), lessThan(4));
    },
  );

  testWidgets(
    'Rami : pioche et défausse placées à gauche du tapis',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
        ),
      );
      await tester.pump();

      final pioche = tester.getRect(find.byType(RamiBackView).first);
      final width = tester.getSize(find.byType(MaterialApp)).width;
      expect(pioche.center.dx, lessThan(width / 2));
    },
  );
}
