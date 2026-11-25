// Le tapis Chkobba ne bouge pas quand le tour change d'avatar (#954).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state(Player turn) => ChkobbaState(
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
      turn: turn,
      starter: turn,
      round: 1,
      winner: null,
    );

Future<Rect> _feltRect(WidgetTester tester, Player turn) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: _state(turn),
      ),
    ),
  );
  await tester.pump();
  return tester.getRect(find.byKey(const ValueKey('chkobba-felt')));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#954 : le tapis ne bouge pas quand le tour passe à l\'adversaire',
      (tester) async {
    final quandJoueur = await _feltRect(tester, Player.player);
    final quandAdversaire = await _feltRect(tester, Player.opponent);
    expect(quandAdversaire.top, quandJoueur.top);
    expect(quandAdversaire.height, quandJoueur.height);
    expect(quandAdversaire.bottom, quandJoueur.bottom);
  });
}
