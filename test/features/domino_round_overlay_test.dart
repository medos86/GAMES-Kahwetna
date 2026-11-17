import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/game/common.dart';
import 'package:kahwetne/game/domino.dart';

/// Issue #295 : le récapitulatif Domino affiche le score et appelle la bonne action.
DominoState _roundEnded({required Player winner, Player? matchWinner}) {
  final base = newDominoRound(
    targetScore: 50,
    scores: {Player.player: 12, Player.opponent: 8},
    round: 2,
    random: () => 0.5,
  );
  return base.copyWith(
    roundWinner: winner,
    matchWinner: matchWinner,
    pointsAwarded: 12,
  );
}

void main() {
  testWidgets('manche terminée : score, points et Manche suivante', (
    tester,
  ) async {
    var next = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DominoRoundOverlay(
            game: _roundEnded(winner: Player.player),
            onNext: () => next++,
            onRestart: () {},
            onMenu: () {},
          ),
        ),
      ),
    );
    expect(find.text('MANCHE 2 TERMINÉE'), findsOneWidget);
    expect(find.text('Score 12 – 8 · +12 points'), findsOneWidget);
    await tester.tap(find.text('Manche suivante'));
    expect(next, 1);
  });

  testWidgets('partie terminée : Rejouer et Retour au menu', (tester) async {
    var restart = 0;
    var menu = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DominoRoundOverlay(
            game: _roundEnded(
              winner: Player.opponent,
              matchWinner: Player.opponent,
            ),
            onNext: () {},
            onRestart: () => restart++,
            onMenu: () => menu++,
          ),
        ),
      ),
    );
    expect(find.text(Strings.dominoMatchOver.toUpperCase()), findsOneWidget);
    expect(find.text('Le voisin gagne'), findsOneWidget);
    await tester.tap(find.text('Rejouer'));
    expect(restart, 1);
    await tester.tap(find.text('Retour au menu'));
    expect(menu, 1);
  });
}
