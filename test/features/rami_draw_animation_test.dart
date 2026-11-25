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
/// Copies visibles d'une carte : celles sous un [Opacity] à 0 (case en attente d'arrivée) sont exclues.
int visibleCopies(String id) {
  final copies = find
      .byWidgetPredicate((w) => w is RamiCardView && w.card.id == id)
      .evaluate();
  var count = 0;
  for (final element in copies) {
    var hidden = false;
    element.visitAncestorElements((ancestor) {
      final w = ancestor.widget;
      if (w is Opacity && w.opacity == 0) hidden = true;
      return !hidden;
    });
    if (!hidden) count++;
  }
  return count;
}

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
    // Attend la fin de la donne (environ 2 s, #876) avant de mesurer.
    await tester.pump(const Duration(seconds: 3));

    final backs = find.byType(RamiBackView);
    final before = backs.evaluate().length;
    await tester.tap(backs.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // Pendant le vol : au moins une copie de dos en plus à l'écran (#876 : la donne
    // est plus lente, on compare donc à l'avant-pioche et non au total final).
    final during = backs.evaluate().length;
    expect(during, greaterThan(before));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
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
    await tester.pump(const Duration(seconds: 3));

    // Piocher d'abord : la défausse n'est possible qu'ensuite.
    await tester.tap(find.byType(RamiBackView).first);
    await tester.pump(const Duration(seconds: 3));

    // Carte la plus basse à l'écran : celle de la main, pas la défausse.
    final cards = tester.widgetList<RamiCardView>(find.byType(RamiCardView));
    final lowest = cards.reduce(
      (a, b) => tester.getCenter(find.byWidget(a)).dy >=
              tester.getCenter(find.byWidget(b)).dy
          ? a
          : b,
    );
    final id = lowest.card.id;
    await tester.tap(find.byWidget(lowest));
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is RamiCardView && w.selected),
      findsOneWidget,
    );
    // #906 : plus de bouton rouge ; la défausse elle-même reçoit la carte sélectionnée.
    expect(find.byTooltip(Strings.actDiscard), findsNothing);
    final pile = find.byKey(const ValueKey('discard'));
    final pileTap = tester.widget<GestureDetector>(
      find.descendant(of: pile, matching: find.byType(GestureDetector)).first,
    );
    expect(pileTap.onTap, isNotNull);
    pileTap.onTap!();
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
    // Une seule copie visible : les cases masquées (opacité 0) ne comptent pas (#878).
    expect(visibleCopies(id), 1);
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
    // Milieu de la donne (#876 : environ 2 s) : des cartes sont encore en vol.
    await tester.pump(const Duration(milliseconds: 900));
    // Les cartes volent en dos (adversaires) ou de face (moi) : on compte les deux.
    final flying = find.byWidgetPredicate(
      (w) => w is RamiCardView || w is RamiBackView,
    );
    final during = flying.evaluate().length;
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
    final settled = flying.evaluate().length;
    // Pendant la donne, des copies volent en plus des cartes déjà posées.
    expect(during, greaterThan(settled));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
