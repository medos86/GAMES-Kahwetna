import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/coinche/coinche_card_view.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/coinche.dart';
import 'package:kahwetne/game/domino.dart';
import 'package:kahwetne/game/rami.dart';

// Rendu des faces et dos de cartes (#167 : couverture des widgets de cartes).
Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  testWidgets('dos et face de carte Chkobba', (tester) async {
    await tester.pumpWidget(_host(const ChkobbaCardBack()));
    expect(find.byType(ChkobbaCardBack), findsOneWidget);

    const card = ChkobbaCard(
      suit: ChkobbaSuit.coupes,
      rank: 7,
      id: 'c7',
    );
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ChkobbaCardFace(
          card: card,
          highlight: true,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(ChkobbaCardFace));
    expect(taps, 1);
  });

  testWidgets('tuile de domino horizontale et verticale', (tester) async {
    await tester.pumpWidget(
      _host(
        const DominoFace(
          first: 3,
          second: 5,
          width: 80,
          height: 40,
          horizontal: true,
          highlight: true,
        ),
      ),
    );
    expect(find.byType(DominoFace), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const DominoFace(
          first: 0,
          second: 6,
          width: 40,
          height: 80,
          horizontal: false,
          highlight: false,
        ),
      ),
    );
    expect(find.byType(DominoFace), findsOneWidget);
  });

  testWidgets('dos de carte Rami', (tester) async {
    await tester.pumpWidget(_host(const RamiBackView(width: 60)));
    expect(find.byType(RamiBackView), findsOneWidget);
  });

  testWidgets('carte Coinche retournée puis visible', (tester) async {
    await tester.pumpWidget(
      _host(const CoincheCardView(width: 60)),
    );
    expect(find.byType(CoincheCardView), findsOneWidget);
  });

  testWidgets('carte Coinche grisée puis touchée', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        CoincheCardView(
          width: 60,
          card: const CoincheCard(
            suit: CoincheSuit.coupes,
            rank: CoincheRank.seven,
            id: 'k7',
          ),
          dimmed: true,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(CoincheCardView));
    expect(taps, 1);
  });

  testWidgets('carte Rami sélectionnée et joker', (tester) async {
    await tester.pumpWidget(
      _host(
        const RamiCardView(
          card: RamiCard(id: 'r12', suit: RamiSuit.epees, rank: 12),
          width: 60,
          selected: true,
        ),
      ),
    );
    expect(find.byType(RamiCardView), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const RamiCardView(
          card: RamiCard(id: 'joker', suit: null, rank: 0),
          width: 60,
        ),
      ),
    );
    expect(find.byType(RamiCardView), findsOneWidget);
  });

  testWidgets('tuile posée sur la chaîne, retournée et en surbrillance',
      (tester) async {
    const tile = PlacedTile(id: 't1', a: 2, b: 4, left: 2, right: 4);
    await tester.pumpWidget(
      _host(
        const ChainTile(
          tile: tile,
          length: 60,
          turn: false,
          reverse: true,
          highlight: true,
        ),
      ),
    );
    expect(find.byType(ChainTile), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const ChainTile(
          tile: tile,
          length: 60,
          turn: true,
          reverse: false,
        ),
      ),
    );
    expect(find.byType(ChainTile), findsOneWidget);
  });
}
