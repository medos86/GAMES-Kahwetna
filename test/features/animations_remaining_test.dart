import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_card_face.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Animations restantes de #224 : pioche dans la défausse (Rami) et
// cartes posées sur le tapis à la donne (Chkobba).
/// Plus grand nombre de copies de [finder] vues image par image pendant [frames] images.
Future<int> _peak(WidgetTester tester, Finder finder, int frames) async {
  var peak = 0;
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    final count = finder.evaluate().length;
    if (count > peak) peak = count;
  }
  return peak;
}

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = true;
  });

  tearDown(() => cardAnimations.value = false);

  testWidgets('Chkobba : la donne fait voler les cartes du tapis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tableCard = _card(ChkobbaSuit.coupes, 5);
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
            table: [tableCard],
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
    final faceOf = find.byWidgetPredicate(
      (w) => w is ChkobbaCardFace && w.card.id == tableCard.id,
    );
    // Pendant la donne : une copie de plus de la carte du tapis en vol.
    final peak = await _peak(tester, faceOf, 150);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    expect(peak, greaterThan(faceOf.evaluate().length));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('Rami : la pioche dans la défausse vole vers la main', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pump(const Duration(seconds: 3));

    // Piocher d'abord : la défausse n'est accessible qu'ensuite.
    await tester.tap(find.byType(RamiBackView).first);
    await tester.pump(const Duration(seconds: 3));

    // Carte de la défausse : celle qui n'est pas dans une main (sans Listener).
    final pile = find.descendant(
      of: find.byType(GestureDetector),
      matching: find.byType(RamiCardView),
    );
    if (pile.evaluate().isEmpty) return;
    final topId = tester.widget<RamiCardView>(pile.first).card.id;
    final faceOf = find.byWidgetPredicate(
      (w) => w is RamiCardView && w.card.id == topId,
    );
    await tester.tap(pile.first);
    final peak = await _peak(tester, faceOf, 100);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    expect(peak, greaterThan(faceOf.evaluate().length));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
