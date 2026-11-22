import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaState _state({required Player turn}) => ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: const [
          ChkobbaCard(suit: ChkobbaSuit.batons, rank: 5, id: 'b5'),
        ],
        Player.opponent: const [
          ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 2, id: 'd2'),
        ],
      },
      table: const [],
      won: {Player.player: const [], Player.opponent: const []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 4, Player.opponent: 7},
      lastCapturer: null,
      turn: turn,
      starter: Player.player,
      round: 1,
      winner: null,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Size logicalSize,
  required ChkobbaState state,
}) async {
  tester.view.physicalSize = logicalSize * 3;
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

/// Issues #726 (panneaux latéraux, plus de barre du haut), #727 (pile dans le panneau)
/// et #728 (avatar du joueur dont c'est le tour agrandi, médaillon partagé avec le Ludo).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('pas de débordement sur 360 px de large (#726)', (tester) async {
    await _pump(
      tester,
      logicalSize: const Size(360, 780),
      state: _state(turn: Player.player),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scores des panneaux latéraux (#726)', (tester) async {
    await _pump(
      tester,
      logicalSize: const Size(390, 844),
      state: _state(turn: Player.player),
    );
    final opponentScore = find.text('7');
    final playerScore = find.text('4');
    expect(opponentScore, findsOneWidget);
    expect(playerScore, findsOneWidget);
    // Adversaire à gauche, joueur à droite.
    expect(
      tester.getCenter(opponentScore).dx,
      lessThan(tester.getCenter(playerScore).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('seul le joueur actif est agrandi (#728)', (tester) async {
    await _pump(
      tester,
      logicalSize: const Size(390, 844),
      state: _state(turn: Player.player),
    );
    final avatars = tester.widgetList<TurnAvatar>(find.byType(TurnAvatar));
    expect(avatars, hasLength(2));
    final active = avatars.where((a) => a.active).toList();
    expect(active, hasLength(1));
    expect(active.single.activeSize, greaterThan(active.single.baseSize));
    expect(active.single.semanticLabel, isNotEmpty);
  });

  testWidgets('le tour adverse rend son avatar actif (#728)', (tester) async {
    await _pump(
      tester,
      logicalSize: const Size(390, 844),
      state: _state(turn: Player.opponent),
    );
    final avatars = tester.widgetList<TurnAvatar>(find.byType(TurnAvatar));
    expect(avatars.where((a) => a.active), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
