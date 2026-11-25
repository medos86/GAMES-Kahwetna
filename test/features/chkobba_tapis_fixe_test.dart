import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state(Player turn) {
  return ChkobbaState(
    targetScore: 11,
    deck: const [],
    hands: {
      Player.player: [_card(ChkobbaSuit.batons, 5)],
      Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
    },
    table: [_card(ChkobbaSuit.coupes, 9)],
    won: {Player.player: [], Player.opponent: []},
    chkobbas: {Player.player: 0, Player.opponent: 0},
    scores: {Player.player: 0, Player.opponent: 0},
    lastCapturer: null,
    turn: turn,
    starter: turn,
    round: 1,
    winner: null,
  );
}

Future<Rect> _tableRect(WidgetTester tester, Player turn) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
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
  final rect = tester.getRect(find.byType(ChkobbaTable));
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  return rect;
}

// Tapis fixe (#909) : sa position ne change pas selon le tour en cours.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets("le tapis garde la même position quand l'adversaire joue", (
    tester,
  ) async {
    final mine = await _tableRect(tester, Player.player);
    final theirs = await _tableRect(tester, Player.opponent);

    expect(theirs.top, closeTo(mine.top, 0.5));
    expect(theirs.height, closeTo(mine.height, 0.5));
  });
}
