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

// La carte jouée capturée ne s'arrête pas au centre : elle va au tas (#362).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('la carte jouée capturée n\'est jamais posée au centre', (
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
    await tester.pump(const Duration(seconds: 8));

    final play = tester.widget<ChkobbaCardFace>(
      find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == 'batons-5',
      ),
    );
    play.onTap!();

    // Une seule étape : la carte jouée ne fait pas de pause au centre.
    // On relève sa position chaque image : elle descend sans s'arrêter.
    final tops = <double>[];
    for (var t = 0; t < 600; t += 20) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      final f = find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == 'batons-5',
      );
      if (f.evaluate().isNotEmpty) {
        tops.add(tester.getTopLeft(f.first).dy);
      }
    }
    // Pas de palier : chaque image la position avance (ou reste à l'arrivée).
    var pauses = 0;
    for (var i = 2; i < tops.length; i++) {
      if (tops[i] == tops[i - 1] && tops[i - 1] == tops[i - 2]) pauses++;
    }
    expect(pauses, lessThanOrEqualTo(2), reason: 'positions : $tops');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
