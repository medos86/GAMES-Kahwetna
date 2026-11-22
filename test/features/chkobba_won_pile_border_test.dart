import 'package:flutter/widgets.dart' show BoxDecoration, Container, SizedBox;
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

// Issue #648 : le tas de cartes gagnées n'est pas encadré par une bordure bleue.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('le tas de cartes gagnées n\'a pas de bordure colorée', (
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
            table: const [],
            won: {
              Player.player: [_card(ChkobbaSuit.coupes, 1)],
              Player.opponent: [_card(ChkobbaSuit.deniers, 3)],
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

    // Le tas est le Container de 56 x 44 (#766) qui porte le compteur de cartes.
    final piles = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => _isPile(tester, c))
        .toList();
    expect(piles, isNotEmpty);
    for (final pile in piles) {
      final decoration = pile.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

bool _isPile(WidgetTester tester, Container c) {
  final size = tester.getSize(find.byWidget(c));
  return size.width == 56 && size.height == 44;
}
