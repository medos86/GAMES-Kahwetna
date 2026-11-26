// Tapis Chkobba allégé, comme Rami : feutre plein sans trame de points,
// cartes posées au centre du tapis, sans bouger les autres.
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

  testWidgets('cartes posées au centre du tapis, la première au milieu', (
    tester,
  ) async {
    final a = _card(ChkobbaSuit.coupes, 5);
    final b = _card(ChkobbaSuit.epees, 7);
    await _pumpTable(tester, [
      ChkobbaCardFace(card: a),
      ChkobbaCardFace(card: b),
    ]);
    final table = tester.getRect(find.byType(ChkobbaTable));
    final first = tester.getRect(find.byType(ChkobbaCardFace).at(0));
    final second = tester.getRect(find.byType(ChkobbaCardFace).at(1));
    // Deux cartes sur la même ligne, centrées de part et d'autre du milieu.
    expect(second.top, closeTo(first.top, 0.5));
    expect(first.center.dx, lessThan(table.center.dx));
    expect(second.center.dx, greaterThan(table.center.dx));
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

  test('feutre bleu premium (#955)', () {
    const m = ScobaPalette.tapisBleuMilieu;
    expect(m.b, greaterThan(m.r));
  });
}
