// Tapis de combat Chkobba (#766) : coins latéraux (avatar, score, pile),
// pioche opposée, contour marron BD autour du tapis vert, pseudo du joueur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/chkobba/chkobba_opponent_name.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

ChkobbaState _state({
  Player starter = Player.player,
  List<ChkobbaCard> playerWon = const [],
  List<ChkobbaCard> opponentWon = const [],
}) =>
    ChkobbaState(
      targetScore: 11,
      deck: const [],
      hands: {
        Player.player: [_card(ChkobbaSuit.batons, 5)],
        Player.opponent: [_card(ChkobbaSuit.deniers, 2)],
      },
      table: [_card(ChkobbaSuit.coupes, 5)],
      won: {Player.player: playerWon, Player.opponent: opponentWon},
      chkobbas: {Player.player: 0, Player.opponent: 0},
      scores: {Player.player: 0, Player.opponent: 0},
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
  // Le profil est lu de façon asynchrone : on laisse passer la lecture.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('joueur bas-gauche, adversaire haut-droite', (tester) async {
    await _pump(tester, _state());
    final table = tester.getRect(find.byType(ChkobbaTable));
    final avatars = find.byType(TurnAvatar);
    final opp = tester.getCenter(avatars.at(0));
    final me = tester.getCenter(avatars.at(1));
    expect(me.dx, lessThan(table.left));
    expect(me.dy, greaterThan(table.center.dy));
    expect(opp.dx, greaterThan(table.right));
    expect(opp.dy, lessThan(table.center.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pile du joueur hors du contour, au-dessus de son avatar', (
    tester,
  ) async {
    final won = [
      _card(ChkobbaSuit.coupes, 1),
      _card(ChkobbaSuit.coupes, 2),
      _card(ChkobbaSuit.coupes, 3),
    ];
    await _pump(tester, _state(playerWon: won));
    final table = tester.getRect(find.byType(ChkobbaTable));
    final pile = _piles(tester)[1];
    expect(tester.getRect(pile).overlaps(table), isFalse);
    final me = tester.getCenter(find.byType(TurnAvatar).at(1));
    expect(tester.getCenter(pile).dy, lessThan(me.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pile adverse hors du contour, sous son avatar', (tester) async {
    final won = [
      _card(ChkobbaSuit.deniers, 1),
      _card(ChkobbaSuit.deniers, 4),
      _card(ChkobbaSuit.deniers, 6),
      _card(ChkobbaSuit.deniers, 7),
    ];
    await _pump(tester, _state(opponentWon: won));
    final table = tester.getRect(find.byType(ChkobbaTable));
    final pile = _piles(tester)[0];
    expect(tester.getRect(pile).overlaps(table), isFalse);
    final opp = tester.getCenter(find.byType(TurnAvatar).at(0));
    expect(tester.getCenter(pile).dy, greaterThan(opp.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pioche à droite quand le joueur commence', (tester) async {
    await _pump(tester, _state(starter: Player.player));
    final deck = tester.getCenter(find.byType(ChkobbaDeckPile));
    final table = tester.getRect(find.byType(ChkobbaTable));
    expect(deck.dx, greaterThan(table.center.dx));
    expect(deck.dy, greaterThan(table.center.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pioche à gauche quand l\'adversaire commence', (tester) async {
    await _pump(tester, _state(starter: Player.opponent));
    final deck = tester.getCenter(find.byType(ChkobbaDeckPile));
    final table = tester.getRect(find.byType(ChkobbaTable));
    expect(deck.dx, lessThan(table.center.dx));
    expect(deck.dy, lessThan(table.center.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contour marron BD, seul le tapis est vert', (tester) async {
    await _pump(tester, _state());
    final felt = tester.widget<Container>(
      find.byKey(const ValueKey('chkobba-felt')),
    );
    final decoration = felt.decoration! as BoxDecoration;
    expect(decoration.color, ComicPalette.tableWood);
    expect(decoration.color, isNot(ScobaPalette.tapisVert));
    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == ScobaPalette.tapisVert,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pseudo du joueur, pas « vous »', (tester) async {
    SharedPreferences.setMockInitialValues({
      profileNamePrefsKey: 'Karima',
      profileAvatarPrefsKey: 'cat',
    });
    await _pump(tester, _state());
    expect(find.text('KARIMA'), findsOneWidget);
    expect(find.text('VOUS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adversaire avec un prénom tiré au hasard', (tester) async {
    await _pump(tester, _state());
    final names = chkobbaOpponentNames.map((n) => n.toUpperCase()).toList();
    expect(
      find.byWidgetPredicate((w) => w is Text && names.contains(w.data)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
