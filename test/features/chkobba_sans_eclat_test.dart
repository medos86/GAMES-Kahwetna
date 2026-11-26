import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/comic/action_burst.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

/// Issue #964 : plus d'éclat « Chkobba ! » ni « 7AYA ! » sur le tapis.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('une Chkobba n\'affiche aucun éclat sur le tapis (#964)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ChkobbaScreen(
          difficulty: Difficulty.facile,
          targetScore: 11,
          initialState: ChkobbaState(
            targetScore: 11,
            deck: const [],
            hands: {
              Player.player: [_card(ChkobbaSuit.batons, 9)],
              Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
            },
            table: [_card(ChkobbaSuit.coupes, 9)],
            won: {Player.player: [], Player.opponent: []},
            chkobbas: {Player.player: 0, Player.opponent: 0},
            scores: {Player.player: 0, Player.opponent: 0},
            lastCapturer: null,
            turn: Player.player,
            starter: Player.player,
            round: 1,
            winner: null,
          ),
        ),
      ),
    );
    await tester.pump();

    final play = tester.widget<ChkobbaCardFace>(
      find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == 'batons-9',
      ),
    );
    play.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ActionBurst), findsNothing);
    expect(find.text('Chkobba !'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
