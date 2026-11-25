import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';
import 'package:kahwetne/game/rami.dart';

void main() {
  test('#589 : le joueur suivant de moi est à ma gauche', () {
    expect(ramiSeatAlignment(nextSeat(0)), Alignment.centerLeft);
  });

  test('#589 : ordre horaire, gauche puis haut puis droite', () {
    expect(ramiSeatAlignment(1), Alignment.centerLeft);
    expect(ramiSeatAlignment(2), Alignment.topCenter);
    expect(ramiSeatAlignment(3), Alignment.centerRight);
  });

  test('#861 : mon badge est en bas à droite, près de la défausse', () {
    expect(ramiSeatAlignment(0), Alignment.bottomRight);
  });

  test('#666 : sièges latéraux écrits verticalement, haut horizontal', () {
    expect(ramiSeatQuarterTurns(1), 3);
    expect(ramiSeatQuarterTurns(3), 1);
    expect(ramiSeatQuarterTurns(2), 0);
  });

  testWidgets(
    '#666 : le badge latéral est tourné, celui du haut non',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RamiSeatBadge(name: 'Ali', cards: 5, quarterTurns: 3),
                RamiSeatBadge(name: 'Karim', cards: 4),
              ],
            ),
          ),
        ),
      );
      final turns = tester
          .widgetList<RotatedBox>(find.byType(RotatedBox))
          .map((r) => r.quarterTurns)
          .toList();
      expect(turns, [3]);
      expect(find.text('×5'), findsNothing);
    },
  );
}
