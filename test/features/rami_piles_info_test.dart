import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
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
}
