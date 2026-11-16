import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/settings/settings_screen.dart';
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
      tester.element(find.byKey(const Key('ramiMinOpeningShield'))),
    );
    expect(direction, TextDirection.ltr);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Paramètres : interrupteur à la même place', (tester) async {
    Future<Offset> switchCenter(AppLanguage language) async {
      appLanguage.value = language;
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pump();
      return tester.getCenter(find.byType(Switch));
    }

    final fr = await switchCenter(AppLanguage.fr);
    final ar = await switchCenter(AppLanguage.ar);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold).first)),
      TextDirection.ltr,
    );
    expect(ar, fr);
    appLanguage.value = AppLanguage.fr;
  });
}
