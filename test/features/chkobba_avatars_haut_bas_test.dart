// Issue #752 : un avatar en haut, un en bas, tapis pleine largeur, fond bleu BD et feutre vert BD.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/tapis_background.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state() => ChkobbaState(
      targetScore: 11,
      deck: [_card(ChkobbaSuit.epees, 3)],
      hands: {
        Player.player: [_card(ChkobbaSuit.batons, 5)],
        Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
      },
      table: [_card(ChkobbaSuit.coupes, 5)],
      won: {Player.player: [], Player.opponent: []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
      lastCapturer: null,
      turn: Player.player,
      starter: Player.player,
      round: 1,
      winner: null,
    );

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: _state(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('#752 : un avatar en haut, un avatar en bas du tapis', (
    tester,
  ) async {
    await _pump(tester);
    final avatars = find.byType(TurnAvatar);
    expect(avatars, findsNWidgets(2));
    final table = tester.getCenter(find.byType(ChkobbaTable));
    final opp = tester.getCenter(avatars.at(0));
    final me = tester.getCenter(avatars.at(1));
    expect(opp.dy, lessThan(table.dy));
    expect(me.dy, greaterThan(table.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#766 : le tapis occupe la place centrale entre les coins', (
    tester,
  ) async {
    await _pump(tester);
    final felt = tester.getRect(find.byKey(const ValueKey('chkobba-felt')));
    final table = tester.getRect(find.byType(ChkobbaTable));
    expect(table.width, greaterThan(felt.width * 0.4));
    expect(table.width, lessThan(felt.width * 0.8));
    expect(tester.takeException(), isNull);
  });

  test('#752 : fond bleu BD et feutre vert BD', () {
    expect(ScobaPalette.tapisBleu.b, greaterThan(ScobaPalette.tapisBleu.r));
    expect(ScobaPalette.tapisVert.g, greaterThan(ScobaPalette.tapisVert.r));
    expect(ScobaPalette.tapisVert.g, greaterThan(ScobaPalette.tapisVert.b));
    const background = TapisBackground(color: ScobaPalette.tapisBleu);
    expect(background.color, ScobaPalette.tapisBleu);
  });
}
