import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

void main() {
  test("#998 : chaque face se pose face à l'écran à la fin", () {
    for (var v = 1; v <= 6; v++) {
      expect(ludoDieFrontFace(ludoDieCubeMatrix(v, 1.0)), v);
    }
  });

  test('#998 : plusieurs faces défilent pendant le lancer', () {
    final seen = <int>{};
    for (var i = 0; i < 10; i++) {
      seen.add(ludoDieFrontFace(ludoDieCubeMatrix(4, i / 10)));
    }
    expect(seen.length, greaterThanOrEqualTo(3));
  });

  test('#998 : la durée du lancer correspond au son dice.wav', () {
    expect(kLudoDieRollDuration.inMilliseconds, 1090);
  });

  testWidgets('#998 : le lancer 3D se pose sans erreur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LudoDie(value: 4, tone: Colors.red, animate: true),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LudoDie), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.byType(LudoDie), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
