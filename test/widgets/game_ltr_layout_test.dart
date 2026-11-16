import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #241 : en arabe (RTL), la mise en page des écrans de jeu reste en LTR :
/// les boutons gardent leur place d'un écran à l'autre.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget rtl(Widget home) => Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(home: home),
      );

  testWidgets('GameScaffold reste en LTR sous une app RTL', (tester) async {
    await tester.pumpWidget(
      rtl(
        const GameScaffold(
          showAd: false,
          child: Text('contenu'),
        ),
      ),
    );
    final direction = Directionality.of(
      tester.element(find.text('contenu')),
    );
    expect(direction, TextDirection.ltr);
  });

  testWidgets('Rami reste en LTR sous une app RTL', (tester) async {
    await tester.pumpWidget(
      rtl(
        const RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();
    final direction = Directionality.of(
      tester.element(find.textContaining('Ouverture min.')),
    );
    expect(direction, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });
}
