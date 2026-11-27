import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

// Issue #1016 : les cartes de la main se chevauchent en éventail.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('main du joueur : cartes qui se chevauchent', (tester) async {
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
              Player.player: [
                _card(ChkobbaSuit.batons, 5),
                _card(ChkobbaSuit.coupes, 3),
                _card(ChkobbaSuit.epees, 9),
              ],
              Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
            },
            table: const [],
            won: {Player.player: const [], Player.opponent: const []},
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

    final centers = <Offset>[];
    final widths = <double>[];
    for (final id in ['batons-5', 'coupes-3', 'epees-9']) {
      final card = find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == id,
      );
      expect(card, findsOneWidget);
      centers.add(tester.getCenter(card));
      widths.add(tester.getSize(card).width);
    }
    // Centres espacés d'un pas inférieur à la largeur d'une carte : recouvrement.
    final order = [0, 1, 2]..sort((a, b) => centers[a].dx.compareTo(centers[b].dx));
    final cardWidth = widths[order[1]];
    for (var i = 1; i < order.length; i++) {
      final shift = centers[order[i]].dx - centers[order[i - 1]].dx;
      expect(shift, greaterThan(0));
      expect(shift, lessThan(cardWidth));
    }
  });
}
