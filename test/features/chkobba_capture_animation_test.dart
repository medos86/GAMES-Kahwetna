import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

// Capture Chkobba : la carte prise du tapis vole vers le tas (#238).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('une carte prise du tapis vole vers le tas', (tester) async {
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
              Player.player: [card(ChkobbaSuit.batons, 5)],
              Player.opponent: [card(ChkobbaSuit.deniers, 2)],
            },
            table: [card(ChkobbaSuit.coupes, 5)],
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
    await tester.pump(const Duration(seconds: 1));

    Finder faceOf(String id) => find.byWidgetPredicate(
          (w) => w is ChkobbaCardFace && w.card.id == id,
        );

    // Le 5 du tapis est visible avant la capture.
    expect(faceOf('coupes-5'), findsOneWidget);

    final play = tester.widget<ChkobbaCardFace>(faceOf('batons-5'));
    expect(play.onTap, isNotNull);
    play.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    // Pendant le vol : une seule copie du 5 de coupes, celle qui vole.
    expect(faceOf('coupes-5'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(faceOf('coupes-5'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
