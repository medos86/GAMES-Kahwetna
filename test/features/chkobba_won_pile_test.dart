import 'package:flutter/widgets.dart' show Container;
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

// Tas de cartes gagnées (#534, #727) : sans compteur affiché (retiré), l'adversaire
// a son tas au-dessus du tapis et le joueur en dessous.

/// Tas de cartes gagnées (Container 56 x 44), dans l'ordre de l'arbre : adversaire, puis joueur.
List<Finder> _piles(WidgetTester tester) => [
      for (final c in tester.widgetList<Container>(find.byType(Container)))
        if (tester.getSize(find.byWidget(c)) == const Size(56, 44))
          find.byWidget(c),
    ];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('tas adversaire à gauche, tas joueur à droite', (tester) async {
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
              Player.player: [_card(ChkobbaSuit.batons, 5)],
              Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
            },
            table: const [],
            won: {
              Player.player: [_card(ChkobbaSuit.coupes, 1)],
              Player.opponent: [
                _card(ChkobbaSuit.deniers, 3),
                _card(ChkobbaSuit.deniers, 4),
                _card(ChkobbaSuit.deniers, 5),
              ],
            },
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

    final piles = _piles(tester);
    expect(piles, hasLength(2));
    // Adversaire en haut, joueur en bas (#752).
    expect(
      tester.getCenter(piles[0]).dy,
      lessThan(tester.getCenter(piles[1]).dy),
    );
    expect(find.text('3'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
