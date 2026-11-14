import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/card_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Coinche : la donne passe par le moteur commun (#266).
// Les cartes de la main restent vides tant qu'elles volent vers leur place.
Finder hiddenSlots() =>
    find.byWidgetPredicate((w) => w is MaskedSlot && w.hidden);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('donne : les cartes arrivent dans la main, puis tout se pose', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CoincheScreen(
          difficulty: Difficulty.facile,
          targetScore: 1000,
        ),
      ),
    );
    // Laisse le chargement asynchrone finir : la donne démarre alors.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump();
    // Pendant la donne : au moins une carte est encore en route.
    expect(hiddenSlots(), findsWidgets);
    expect(tester.takeException(), isNull);

    // Une image par tranche : chaque vol démarre à l'image suivante.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(hiddenSlots(), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
