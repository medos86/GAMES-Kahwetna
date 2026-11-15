import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #370 : le score tient sur la ligne du nom, la bande de scores reste basse.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : score des joueurs sur une seule ligne', (tester) async {
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

    final score = tester.widget<Text>(find.text('0').first);
    expect(score.style?.fontSize, 15);
    expect(tester.getSize(find.text('0').first).height, lessThan(24));
    expect(tester.takeException(), isNull);
  });
}
