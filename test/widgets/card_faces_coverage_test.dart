import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/coinche/coinche_card_view.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/game/chkobba.dart';

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
}
