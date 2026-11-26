import 'dart:math' as math;

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

// Issue #986 : la main du joueur est disposée en arc, cartes agrandies sans
// sortir de l'écran (390 x 844 dp).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('main du joueur : trois cartes en arc, la centrale droite', (
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

    const ids = ['batons-5', 'coupes-3', 'epees-9'];
    final xs = <double>[];
    final angles = <double>[];
    for (final id in ids) {
      final card = find.byWidgetPredicate(
        (w) => w is ChkobbaCardFace && w.card.id == id,
      );
      expect(card, findsOneWidget);
      xs.add(tester.getCenter(card).dx);
      // La carte centrale n'a pas de rotation : son angle reste 0.
      var angle = 0.0;
      final ancestors = find.ancestor(
        of: card,
        matching: find.byType(Transform),
      );
      for (final t in tester.widgetList<Transform>(ancestors)) {
        final sine = -t.transform.entry(0, 1);
        if (sine.abs() > 1e-6) angle = math.asin(sine);
      }
      angles.add(angle);
      final rect = tester.getRect(card);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(390));
    }

    // Arc : la carte centrale reste droite, les deux voisines sont inclinées
    // symétriquement (sens d'inclinaison indifférent).
    final order = [0, 1, 2]..sort((a, b) => xs[a].compareTo(xs[b]));
    final left = angles[order[0]];
    final middle = angles[order[1]];
    final right = angles[order[2]];
    expect(middle.abs(), lessThan(1e-6));
    expect(left.abs(), greaterThan(0.01));
    expect(right + left, closeTo(0, 1e-6));
  });
}
