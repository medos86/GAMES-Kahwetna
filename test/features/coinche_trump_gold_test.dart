import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_card_view.dart';
import 'package:kahwetne/game/coinche.dart';

/// Issue #734 : les cartes de la couleur d'atout sont dorées.
void main() {
  const heart = CoincheCard(
    suit: CoincheSuit.coupes,
    rank: CoincheRank.ace,
    id: 'as-coupe',
  );
  const spade = CoincheCard(
    suit: CoincheSuit.epees,
    rank: CoincheRank.ace,
    id: 'as-pique',
  );

  test('coincheIsTrump : seule la couleur du contrat est atout', () {
    const contract = Contract(
      seat: Seat.south,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );
    expect(coincheIsTrump(heart, contract), isTrue);
    expect(coincheIsTrump(spade, contract), isFalse);
    expect(coincheIsTrump(heart, null), isFalse);
  });

  testWidgets('carte atout : bordure dorée', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoincheCardView(width: 100, card: heart, trump: true),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('trump-gold')), findsOneWidget);
  });

  testWidgets('carte non atout : pas de dorure', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoincheCardView(width: 100, card: spade),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('trump-gold')), findsNothing);
  });
}
