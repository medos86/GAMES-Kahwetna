// Issue #800 : avatar et score sur une colonne, pile gagnée et pioche sur l'autre.
// Les coins restent sur leur rangée : le tapis garde toute la hauteur libre.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaState _state({required Player starter}) => ChkobbaState(
      targetScore: 11,
      deck: const [
        ChkobbaCard(suit: ChkobbaSuit.epees, rank: 3, id: 'e3'),
      ],
      hands: {
        Player.player: const [
          ChkobbaCard(suit: ChkobbaSuit.batons, rank: 5, id: 'b5'),
        ],
        Player.opponent: const [
          ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 2, id: 'd2'),
        ],
      },
      table: const [],
      won: {
        Player.player: const [],
        Player.opponent: const [],
      },
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 4, Player.opponent: 7},
      lastCapturer: null,
      turn: starter,
      starter: starter,
      round: 1,
      winner: null,
    );

Future<void> _pump(WidgetTester tester, ChkobbaState state) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ChkobbaScreen(
        difficulty: Difficulty.facile,
        targetScore: 11,
        initialState: state,
      ),
    ),
  );
  await tester.pump();
}

/// Tas de cartes gagnées (Container 56 x 44), dans l'ordre de l'arbre : adversaire, puis joueur.
List<Finder> _piles(WidgetTester tester) {
  final found = <Finder>[];
  for (final c in tester.widgetList<Container>(find.byType(Container))) {
    final finder = find.byWidget(c);
    if (tester.getSize(finder) == const Size(56, 44)) found.add(finder);
  }
  return found;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('#800 : pile adverse et avatar adverse sur sa rangée', (
    tester,
  ) async {
    await _pump(tester, _state(starter: Player.player));
    final table = tester.getRect(find.byType(ChkobbaTable));
    final oppAvatar = tester.getCenter(find.byType(TurnAvatar).at(0));
    final oppPile = tester.getCenter(_piles(tester)[0]);
    // Rangée du haut, au-dessus du tapis : pile à gauche, avatar à droite.
    expect(oppAvatar.dy, lessThan(table.top));
    expect(oppPile.dy, lessThan(table.top));
    expect(oppPile.dx, lessThan(oppAvatar.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#800 : avatar joueur à gauche, pile joueur à droite', (
    tester,
  ) async {
    await _pump(tester, _state(starter: Player.player));
    final table = tester.getRect(find.byType(ChkobbaTable));
    final playerAvatar = tester.getCenter(find.byType(TurnAvatar).at(1));
    final playerPile = tester.getCenter(_piles(tester)[1]);
    // Rangée du bas, sous le tapis.
    expect(playerAvatar.dy, greaterThan(table.bottom));
    expect(playerPile.dy, greaterThan(table.bottom));
    expect(playerPile.dx, greaterThan(playerAvatar.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('#800 : le tapis garde plus de 200 dp de haut', (tester) async {
    await _pump(tester, _state(starter: Player.player));
    final table = tester.getRect(find.byType(ChkobbaTable));
    expect(table.height, greaterThan(200));
    expect(tester.takeException(), isNull);
  });
}
