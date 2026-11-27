// Domino (#1041) : au-delà de 7 pierres adverses, le 7ème dos porte « +n ».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#1041 : pierres adverses plafonnées à 7 emplacements', (
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

    // En début de partie l'adversaire a 7 pierres : aucun badge « +n ».
    expect(find.textContaining(RegExp(r'^\+\d+$')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
