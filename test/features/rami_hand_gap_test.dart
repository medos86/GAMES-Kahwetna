import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #319 : la main est collée à la zone de jeu (écart réduit, pas de chevauchement).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : écran sans dépassement avec la main serrée', (
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

    expect(find.byType(RamiScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
