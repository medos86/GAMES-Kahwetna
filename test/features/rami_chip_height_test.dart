import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pastilles de score : nom et score sur une ligne, état dessous (#422).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Rami : le score est sur la même ligne que le nom du joueur',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
        ),
      );
      await tester.pump();

      final name = tester.getCenter(find.text('TOI'));
      final score = tester.getCenter(find.text('0').first);
      expect((name.dy - score.dy).abs(), lessThan(6));
    },
  );
}
