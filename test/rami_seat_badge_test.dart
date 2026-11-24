import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_seat_badge.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('distribution : droite, haut, gauche, puis moi en bas', () {
    expect(ramiDealSeatOrder, [1, 2, 3, 0]);
  });

  testWidgets('badge : n\'affiche plus le nombre de cartes à côté de l\'avatar',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiSeatBadge(name: 'Ali', cards: 6),
      ),
    );
    expect(find.text('×6'), findsNothing);
    expect(find.text('Ali'), findsOneWidget);
  });

  testWidgets('badge : toucher l\'avatar ouvre le popup du siège (#887)',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RamiSeatBadge(
          name: 'Ali',
          cards: 6,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Ali'));
    expect(taps, 1);
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
