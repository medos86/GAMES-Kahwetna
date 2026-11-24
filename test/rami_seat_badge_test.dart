import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('distribution : droite, haut, gauche, puis moi en bas', () {
    expect(ramiDealSeatOrder, [1, 2, 3, 0]);
  });

  testWidgets('badge : affiche seulement le nombre de cartes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiSeatBadge(name: 'Ali', cards: 6),
      ),
    );
    expect(find.text('×6'), findsOneWidget);
    expect(find.text('Ali'), findsNothing);
  });

  testWidgets('badge : le pseudo reste accessible aux lecteurs d\'écran',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiSeatBadge(name: 'Ali', cards: 6),
      ),
    );
    expect(find.bySemanticsLabel('Ali, 6 cartes'), findsOneWidget);
  });
}
