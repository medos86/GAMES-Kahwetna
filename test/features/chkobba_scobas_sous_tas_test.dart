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

// Issue #649 : une Scoba posée sous le tas est à moitié cachée par lui ; seule la moitié basse dépasse.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('scoba à moitié cachée sous le tas', (tester) async {
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
              Player.player: [_card(ChkobbaSuit.batons, 1)],
              Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
            },
            table: [_card(ChkobbaSuit.coupes, 1)],
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

    // Le 1 de la main ramasse le 1 du tapis : Chkobba, la carte est posée sous le tas du joueur.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == 'batons-1',
      ),
    );
    await tester.pump();

    final scoba = tester.getRect(find.byKey(const ValueKey('scoba:batons-1')));
    // Le tas du joueur est celui dont le haut est le plus proche de la scoba.
    final piles = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => tester.getRect(find.byWidget(c)))
        .where((r) => r.width == 56 && r.height == 44)
        .toList();
    expect(piles, isNotEmpty);
    final top = scoba.top;
    final pile = piles.reduce(
      (a, b) => (a.top - top).abs() < (b.top - top).abs() ? a : b,
    );

    // La partie haute de la scoba passe sous le tas, la partie basse dépasse.
    expect(scoba.top, lessThan(pile.bottom));
    expect(scoba.bottom, greaterThan(pile.bottom));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
