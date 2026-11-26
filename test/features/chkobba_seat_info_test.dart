import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChkobbaCard _card(ChkobbaSuit suit, int rank) =>
    ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank');

/// Texte affiché par le widget identifié par [key] dans la popup.
String? _value(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data;

// Issue #984 : toucher l'avatar d'un joueur ouvre une popup avec ses cartes gagnées
// et ses Chkobbas (valeurs de l'état de jeu), fermée par le bouton ou un tap extérieur.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('popup joueur : ouverture, valeurs exactes et fermeture', (
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
              Player.player: [
                _card(ChkobbaSuit.coupes, 1),
                _card(ChkobbaSuit.coupes, 2),
              ],
              Player.opponent: [_card(ChkobbaSuit.deniers, 3)],
            },
            chkobbas: {Player.player: 1, Player.opponent: 0},
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

    // Ouverture : appui sur l'avatar du joueur. Pas de pumpAndSettle : l'avatar actif
    // tourne en boucle (tour du joueur), la frame ne s'arrête jamais.
    expect(find.text(Strings.seatWonCards), findsNothing);
    await tester.tap(find.byKey(const ValueKey('seat-avatar:player')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(Strings.seatWonCards), findsOneWidget);
    expect(find.text(Strings.seatChkobbas), findsOneWidget);
    expect(_value(tester, 'seat-info:won'), '2');
    expect(_value(tester, 'seat-info:chkobbas'), '1');

    // Fermeture par le bouton.
    await tester.tap(find.text(Strings.close));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Strings.seatWonCards), findsNothing);

    // Réouverture puis fermeture par un tap en dehors de la boîte.
    await tester.tap(find.byKey(const ValueKey('seat-avatar:opponent')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_value(tester, 'seat-info:won'), '1');
    expect(_value(tester, 'seat-info:chkobbas'), '0');
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Strings.seatWonCards), findsNothing);

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
