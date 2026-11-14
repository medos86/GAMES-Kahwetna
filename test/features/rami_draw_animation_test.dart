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
    // Laisse le chargement asynchrone (restore) finir : la donne démarre alors.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    // Attend la fin de la donne (environ 1,5 s) avant de mesurer.
    await tester.pump(const Duration(seconds: 3));

    final backs = find.byType(RamiBackView);
    await tester.tap(backs.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // Pendant le vol : au moins une copie de dos en plus à l'écran.
    final during = backs.evaluate().length;
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    final settled = backs.evaluate().length;
    expect(during, greaterThan(settled));
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
    // Laisse le chargement asynchrone (restore) finir : la donne démarre alors.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(seconds: 2));

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
    final id = lowest.card.id;
    Finder faceOf() =>
        find.byWidgetPredicate((w) => w is RamiCardView && w.card.id == id);
    await tester.tap(find.byWidget(lowest));
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is RamiCardView && w.selected),
      findsOneWidget,
    );
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
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    // Défaussée : plus aucune carte sélectionnée, et elle est sur la défausse.
    expect(
      find.byWidgetPredicate((w) => w is RamiCardView && w.selected),
      findsNothing,
    );
    print('DBG id=$id');
    print('DBG ${find.byType(RamiCardView).evaluate().length}');
    print('DBG ${tester.widgetList<RamiCardView>(find.byType(RamiCardView)).map((w) => w.card.id).join(',')}');
    expect(faceOf(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('la donne initiale vole depuis la pioche (#238)', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    // Laisse le chargement asynchrone (restore) finir : la donne démarre alors.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final during = find.byType(RamiCardView).evaluate().length;
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    final settled = find.byType(RamiCardView).evaluate().length;
    // Pendant la donne, des copies volent en plus des cartes déjà posées.
    expect(during, greaterThan(settled));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
