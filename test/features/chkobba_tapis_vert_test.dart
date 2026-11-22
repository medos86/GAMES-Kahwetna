// Tapis Chkobba en vert BD (#745) : feutre vert, pas de livre des règles,
// pioche côté du starter, avatar joueur plus bas, cartes à contour noir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state(Player starter) => ChkobbaState(
      targetScore: 11,
      deck: [_card(ChkobbaSuit.epees, 3), _card(ChkobbaSuit.coupes, 4)],
      hands: {
        Player.player: [_card(ChkobbaSuit.batons, 5)],
        Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
      },
      table: [_card(ChkobbaSuit.coupes, 5)],
      won: {Player.player: [], Player.opponent: []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
      lastCapturer: null,
      turn: starter,
      starter: starter,
      round: 1,
      winner: null,
    );

Future<void> _pump(WidgetTester tester, Player starter) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: _state(starter),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('#745 : le feutre du tapis est vert', () {
    expect(ScobaPalette.tapisVert, isNot(ScobaPalette.tapisBleu));
    expect(ScobaPalette.tapisVert.g, greaterThan(ScobaPalette.tapisVert.r));
    expect(ScobaPalette.tapisVert.g, greaterThan(ScobaPalette.tapisVert.b));
  });

  testWidgets('#745 : le tapis de cartes est peint en vert', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: ChkobbaTable(cards: [null, null, null, null], columns: 4),
          ),
        ),
      ),
    );
    final boxes = find.descendant(
      of: find.byType(ChkobbaTable),
      matching: find.byType(DecoratedBox),
    );
    final decorations = tester
        .widgetList<DecoratedBox>(boxes)
        .map((b) => b.decoration)
        .whereType<BoxDecoration>();
    expect(decorations.any((d) => d.color == ScobaPalette.tapisVert), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#745 : plus de livre des règles dans la barre', (tester) async {
    await _pump(tester, Player.player);
    expect(find.byIcon(Icons.menu_book), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#745 : pioche côté adversaire quand il commence', (
    tester,
  ) async {
    await _pump(tester, Player.opponent);
    final deck = tester.getCenter(find.byType(ChkobbaDeckPile));
    final table = tester.getCenter(find.byType(ChkobbaTable));
    expect(deck.dy, lessThan(table.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#745 : pioche côté joueur quand il commence', (tester) async {
    await _pump(tester, Player.player);
    final deck = tester.getCenter(find.byType(ChkobbaDeckPile));
    final table = tester.getCenter(find.byType(ChkobbaTable));
    expect(deck.dy, greaterThan(table.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#745 : avatar joueur plus bas, adversaire plus haut', (
    tester,
  ) async {
    await _pump(tester, Player.player);
    // Premier avatar = adversaire (panneau de gauche dans l'arbre), second = joueur.
    final avatars = find.byType(TurnAvatar);
    final opp = tester.getTopLeft(avatars.at(0));
    final me = tester.getTopLeft(avatars.at(1));
    expect(me.dy, greaterThan(opp.dy + 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#745 : cartes avec contour noir épais', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              child: ChkobbaCardFace(card: _card(ChkobbaSuit.coupes, 5)),
            ),
          ),
        ),
      ),
    );
    final faceBoxes = find.descendant(
      of: find.byType(ChkobbaCardFace),
      matching: find.byType(DecoratedBox),
    );
    final box = tester.widget<DecoratedBox>(faceBoxes.first);
    final deco = box.decoration as BoxDecoration;
    expect(deco.border!.top.color, Colors.black);
    expect(deco.border!.top.width, greaterThanOrEqualTo(2.5));
    expect(deco.boxShadow!.first.offset.dy, greaterThanOrEqualTo(4));
  });
}
