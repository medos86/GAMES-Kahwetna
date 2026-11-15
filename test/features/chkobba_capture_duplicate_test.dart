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

// Pendant une capture, une même carte ne doit jamais apparaître deux fois
// (#350 : carte dupliquée pendant le vol).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('une carte capturée n\'est jamais affichée en double', (
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
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(seconds: 3));

    int copies(String id) => find
        .byWidgetPredicate((w) => w is ChkobbaCardFace && w.card.id == id)
        .evaluate()
        .length;

    final play = tester.widget<ChkobbaCardFace>(
      find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == 'batons-5',
      ),
    );
    play.onTap!();

    // Échantillonne chaque image pendant toute la capture.
    var worst = {'batons-5': 0, 'coupes-5': 0};
    for (var t = 0; t < 1500; t += 25) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(tester.takeException(), isNull);
      for (final id in worst.keys) {
        final n = copies(id);
        if (n > worst[id]!) worst[id] = n;
      }
    }
    expect(worst['batons-5'], lessThanOrEqualTo(1), reason: 'batons-5 doublon');
    expect(worst['coupes-5'], lessThanOrEqualTo(1), reason: 'coupes-5 doublon');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
