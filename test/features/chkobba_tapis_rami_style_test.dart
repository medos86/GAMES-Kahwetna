// Tapis Chkobba allégé, comme Rami : feutre plein sans trame de points,
// cartes rangées depuis le haut à gauche, sans cases vides.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/game/chkobba.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

Future<void> _pumpTable(WidgetTester tester, List<Widget?> cards) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 300,
          child: ChkobbaTable(cards: cards, columns: 4),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pas de trame de points sur le feutre', (tester) async {
    await _pumpTable(tester, [null, null, null, null]);
    // Le motif de points (CustomPaint) a été retiré : le feutre est uni.
    expect(
      find.descendant(
        of: find.byType(ChkobbaTable),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cartes rangées depuis le haut à gauche, sans case vide', (
    tester,
  ) async {
    final a = _card(ChkobbaSuit.coupes, 5);
    final b = _card(ChkobbaSuit.epees, 7);
    // Deux cartes seulement, avec des emplacements vides entre elles.
    await _pumpTable(tester, [
      ChkobbaCardFace(card: a),
      null,
      null,
      ChkobbaCardFace(card: b),
    ]);
    final first = tester.getTopLeft(find.byType(ChkobbaCardFace).at(0));
    final second = tester.getTopLeft(find.byType(ChkobbaCardFace).at(1));
    // La deuxième carte suit la première sur la même ligne (pas de trou).
    expect(second.dy, closeTo(first.dy, 0.5));
    expect(second.dx, greaterThan(first.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('largeur de carte plafonnée pour un tapis plus léger', (
    tester,
  ) async {
    await _pumpTable(tester, [
      ChkobbaCardFace(card: _card(ChkobbaSuit.batons, 3)),
    ]);
    final size = tester.getSize(find.byType(ChkobbaCardFace));
    expect(size.width, closeTo(kChkobbaTableCardWidth, 0.5));
    expect(size.width / size.height, closeTo(5 / 7, 0.02));
    expect(tester.takeException(), isNull);
  });

  test('feutre toujours vert', () {
    expect(ScobaPalette.tapisVert.g, greaterThan(ScobaPalette.tapisVert.r));
  });
}
