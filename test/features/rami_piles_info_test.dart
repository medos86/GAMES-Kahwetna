import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #414 : pas de compteur sur pioche ni défausse ; l'ouverture min. est près des piles.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : compteurs retirés, ouverture min. en bas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Pioche ·'), findsNothing);
    expect(find.textContaining('Défausse ·'), findsNothing);
    expect(find.byKey(const Key('ramiMinOpeningShield')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rami : bouclier lisible, à droite de la défausse (#880, #886)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();

    final shield = find.byKey(const Key('ramiMinOpeningShield'));
    final stock = find.byType(RamiBackView).first;
    expect(shield, findsOneWidget);
    expect(stock, findsOneWidget);
    // Taille réelle (pas de réduction) : à droite de la pioche et de la défausse (#886).
    expect(tester.getSize(shield).width, greaterThanOrEqualTo(30));
    expect(tester.getTopLeft(shield).dx,
        greaterThan(tester.getTopRight(stock).dx));
    expect(tester.getTopLeft(stock).dy, greaterThan(0));
  });
}
