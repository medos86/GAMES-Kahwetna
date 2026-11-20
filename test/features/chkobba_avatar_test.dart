import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/avatars/avatar_catalog.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaState _state({Player? winner}) => ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: [
          const ChkobbaCard(suit: ChkobbaSuit.batons, rank: 5, id: 'b5'),
        ],
        Player.opponent: [
          const ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 2, id: 'd2'),
        ],
      },
      table: const [],
      won: {Player.player: const [], Player.opponent: const []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 11, Player.opponent: 4},
      lastCapturer: null,
      turn: Player.player,
      starter: Player.player,
      round: 1,
      winner: winner,
    );

Future<void> _pump(WidgetTester tester, ChkobbaState state) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: state,
      ),
    ),
  );
  await tester.pump();
}

/// Issue #551 : un avatar par joueur au tableau de bord, selon le résultat.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('deux avatars neutres pendant la partie', (tester) async {
    await _pump(tester, _state());
    expect(find.byType(AvatarView), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (w) => w is AvatarView && w.state != AvatarState.neutral,
      ),
      findsNothing,
    );
  });

  testWidgets('fin de partie : gagnant heureux, perdant fâché', (
    tester,
  ) async {
    await _pump(tester, _state(winner: Player.player));
    expect(
      find.byWidgetPredicate(
        (w) => w is AvatarView && w.state == AvatarState.happy,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is AvatarView && w.state == AvatarState.angry,
      ),
      findsOneWidget,
    );
  });
}
