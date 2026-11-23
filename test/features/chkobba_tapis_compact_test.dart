// Tapis Chkobba épuré : pas de libellé « PIOCHE », score sous l'avatar comme à la Belote,
// dos de carte zoomé (pas écrasé), tapis sans cadre intérieur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
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
      won: {Player.player: const [], Player.opponent: const []},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 4, Player.opponent: 7},
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
    cardAnimations.value = false;
  });

  testWidgets('pas de libellé PIOCHE sous la pioche', (tester) async {
    await _pump(tester);
    expect(find.text('PIOCHE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adversaire : score sous son avatar, comme à la Belote', (
    tester,
  ) async {
    await _pump(tester);
    final opponentScore = tester.getCenter(find.text('7'));
    final opponentAvatar = tester.getCenter(find.byType(TurnAvatar).at(0));
    expect(opponentScore.dy, greaterThan(opponentAvatar.dy));
    expect(opponentScore.dx, closeTo(opponentAvatar.dx, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('joueur : score sous son avatar, comme à la Belote', (
    tester,
  ) async {
    await _pump(tester);
    final playerScore = tester.getCenter(find.text('4'));
    final playerAvatar = tester.getCenter(find.byType(TurnAvatar).at(1));
    expect(playerScore.dy, greaterThan(playerAvatar.dy));
    expect(playerScore.dx, closeTo(playerAvatar.dx, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dos de carte zoomé, sans étirement du motif', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ChkobbaCardBack())),
      ),
    );
    final zoom = tester.widget<Transform>(
      find.descendant(
        of: find.byType(ChkobbaCardBack),
        matching: find.byType(Transform),
      ),
    );
    // Échelle 2 : seule la partie centrale du dos est visible.
    expect(zoom.transform.storage[0], 2);
    expect(tester.takeException(), isNull);
  });
}
