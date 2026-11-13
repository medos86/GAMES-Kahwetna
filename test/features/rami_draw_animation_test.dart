import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pioche de Rami avec animation : la carte vole pendant l'action puis
// disparaît à l'arrivée sur la vraie carte de la main (#224, #238).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('la pioche lance un vol qui se termine sur la main', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    final backs = find.byType(RamiBackView);
    final before = backs.evaluate().length;
    await tester.tap(backs.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // Une carte de plus pendant le vol (la copie qui vole).
    expect(backs.evaluate().length, before + 1);

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(backs.evaluate().length, before);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('la défausse lance un vol vers la défausse', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Piocher d'abord : la défausse n'est possible qu'ensuite.
    await tester.tap(find.byType(RamiBackView).first);
    await tester.pump(const Duration(seconds: 1));

    // Carte la plus basse à l'écran : celle de la main, pas la défausse.
    final cards = tester.widgetList<RamiCardView>(find.byType(RamiCardView));
    final lowest = cards.reduce(
      (a, b) => tester.getCenter(find.byWidget(a)).dy >=
              tester.getCenter(find.byWidget(b)).dy
          ? a
          : b,
    );
    await tester.tap(find.byWidget(lowest));
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is RamiCardView && w.selected),
      findsOneWidget,
    );
    final before = find.byType(RamiCardView).evaluate().length;
    expect(find.text(Strings.actDiscard), findsOneWidget);
    // Déclenche le bouton directement : le tap est masqué par la main (layout).
    final discardButton = tester.widget<InkWell>(
      find.ancestor(
        of: find.text(Strings.actDiscard),
        matching: find.byType(InkWell),
      ),
    );
    expect(discardButton.onTap, isNotNull);
    discardButton.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // Main -1 et copie qui vole +1 : le total ne change pas pendant le vol.
    expect(find.byType(RamiCardView).evaluate().length, before);

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    // La défausse n'affiche que la carte du dessus : total = before - 1.
    expect(find.byType(RamiCardView).evaluate().length, before - 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
