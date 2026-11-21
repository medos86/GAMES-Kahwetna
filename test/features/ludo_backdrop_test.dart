// Fond du Ludo : dés discrets sur le dégradé bleu (#690).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/ludo_backdrop_palette.dart';
import 'package:kahwetne/features/ludo/ludo_backdrop.dart';

void main() {
  test('#690 : le motif de dés est déterministe', () {
    final a = ludoDicePlacements(400, 800);
    final b = ludoDicePlacements(400, 800);
    expect(a.length, b.length);
    expect(a.first.centre, b.first.centre);
    expect(a.last.value, b.last.value);
  });

  test('#690 : le motif couvre le fond sans le surcharger', () {
    final dice = ludoDicePlacements(400, 800);
    expect(dice.length, greaterThan(20));
    expect(dice.length, lessThan(200));
  });

  test('#690 : chaque face a autant de points que sa valeur', () {
    for (var value = 1; value <= 6; value++) {
      expect(ludoPipOffsets(value).length, value);
    }
  });

  test('#690 : les points restent dans la face', () {
    for (var value = 1; value <= 6; value++) {
      for (final p in ludoPipOffsets(value)) {
        expect(p.dx.abs(), lessThanOrEqualTo(0.25));
        expect(p.dy.abs(), lessThanOrEqualTo(0.25));
      }
    }
  });

  test('#690 : traits discrets, jamais noir plein', () {
    expect(LudoBackdropPalette.diceStroke.a, lessThan(0.5));
    expect(LudoBackdropPalette.diceStroke, isNot(const Color(0xFF000000)));
    expect(LudoBackdropPalette.pip.a, lessThan(0.5));
  });

  testWidgets('#690 : le fond du Ludo se peint sans erreur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 360, height: 640, child: LudoBackdrop()),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
