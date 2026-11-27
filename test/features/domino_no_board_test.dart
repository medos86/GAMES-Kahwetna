// Domino (#1038) : la main est posée directement sur le tapis, sans planche crème.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#1038 : aucune planche crème sous la main du joueur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
      ),
    );
    await tester.pump();

    final planks = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == const Color(0xFFFFF8E7),
    );
    expect(planks, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
