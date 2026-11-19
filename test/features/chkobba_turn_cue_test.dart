import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/pulse_glow.dart';
import 'package:material_ui/material_ui.dart';
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

Future<void> _pumpScreen(WidgetTester tester, Player turn) async {
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
}

// Indicateur de tour (#535) : la bannière n'apparaît que pour l'adversaire,
// et le halo doré de ma main ne pulse que quand c'est à moi de jouer.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('à moi de jouer : pas de bannière, pas de halo jaune', (
    tester,
  ) async {
    await _pumpScreen(tester, Player.player);

    expect(find.textContaining("Tour de l'adversaire"), findsNothing);
    // Pas de halo jaune pour signaler le tour (#588).
    expect(find.byType(PulseGlow), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets("tour de l'adversaire : bannière affichée, pas de halo", (
    tester,
  ) async {
    await _pumpScreen(tester, Player.opponent);

    expect(find.textContaining("Tour de l'adversaire"), findsOneWidget);
    expect(find.byType(PulseGlow), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
