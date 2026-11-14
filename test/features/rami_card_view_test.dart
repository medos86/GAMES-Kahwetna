import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/game/rami.dart';

// Images des cartes Rami (#137) : chaque carte du jeu doit avoir son fichier PNG.

const List<RamiSuit> _suits = RamiSuit.values;

/// Les 54 cartes d'un jeu : 4 couleurs x 13 valeurs, plus 2 jokers.
List<RamiCard> _fullDeck() => [
      for (final suit in _suits)
        for (var rank = 1; rank <= 13; rank++)
          RamiCard(id: '${suit.name}-$rank', suit: suit, rank: rank),
      const RamiCard(id: 'joker-0', suit: null, rank: 0),
      const RamiCard(id: 'joker-1', suit: null, rank: 0),
    ];

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

/// Nom de l'asset affiché : l'image est enveloppée dans un ResizeImage (cacheWidth).
String _shownAsset(WidgetTester tester) {
  var provider = tester.widget<Image>(find.byType(Image)).image;
  if (provider is ResizeImage) provider = provider.imageProvider;
  return (provider as AssetImage).assetName;
}

void main() {
  test('chaque carte du jeu a un fichier PNG existant', () {
    final deck = _fullDeck();
    expect(deck, hasLength(54));
    for (final card in deck) {
      final path = ramiCardAsset(card);
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('le dos de carte existe', () {
    expect(File(ramiCardBackAsset).existsSync(), isTrue);
  });

  test('noms de fichiers des cartes', () {
    expect(
      ramiCardAsset(const RamiCard(id: 'a', suit: RamiSuit.epees, rank: 1)),
      'assets/images/cards_rami/ace_of_spades.png',
    );
    expect(
      ramiCardAsset(const RamiCard(id: 'b', suit: RamiSuit.batons, rank: 10)),
      'assets/images/cards_rami/10_of_clubs.png',
    );
    expect(
      ramiCardAsset(const RamiCard(id: 'c', suit: RamiSuit.coupes, rank: 13)),
      'assets/images/cards_rami/king_of_hearts.png',
    );
    expect(
      ramiCardAsset(const RamiCard(id: 'd', suit: RamiSuit.deniers, rank: 12)),
      'assets/images/cards_rami/queen_of_diamonds.png',
    );
  });

  test('les deux jokers ont chacun leur image', () {
    expect(
      ramiCardAsset(const RamiCard(id: 'joker-0', suit: null, rank: 0)),
      'assets/images/cards_rami/black_joker.png',
    );
    expect(
      ramiCardAsset(const RamiCard(id: 'joker-1', suit: null, rank: 0)),
      'assets/images/cards_rami/red_joker.png',
    );
  });

  testWidgets('RamiCardView affiche l\'image de la carte', (tester) async {
    await tester.pumpWidget(
      _host(
        const RamiCardView(
          card: RamiCard(id: 'x', suit: RamiSuit.epees, rank: 1),
          width: 60,
        ),
      ),
    );
    expect(
      _shownAsset(tester),
      'assets/images/cards_rami/ace_of_spades.png',
    );
    expect(find.bySemanticsLabel('A ♠'), findsOneWidget);
  });

  testWidgets('RamiBackView affiche le dos rouge', (tester) async {
    await tester.pumpWidget(_host(const RamiBackView(width: 60)));
    expect(_shownAsset(tester), ramiCardBackAsset);
  });
}
