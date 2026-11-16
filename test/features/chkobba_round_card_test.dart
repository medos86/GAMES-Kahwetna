import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/common.dart';

// Issue #295 : le récapitulatif de manche Chkobba est affiché via ResultDialog.
ChkobbaState _state({Player? winner}) {
  return ChkobbaState(
    targetScore: 11,
    deck: const [],
    hands: {Player.player: [], Player.opponent: []},
    table: const [],
    won: {Player.player: [], Player.opponent: []},
    chkobbas: {Player.player: 0, Player.opponent: 0},
    scores: {Player.player: 4, Player.opponent: 3},
    lastCapturer: null,
    turn: Player.player,
    starter: Player.player,
    round: 1,
    winner: winner,
  );
}

ChkobbaRoundScore _summary({Player? winner}) {
  return ChkobbaRoundScore(
    state: _state(winner: winner),
    points: {
      Player.player: [const RoundPoint('Cartes', 2)],
      Player.opponent: [const RoundPoint('Deniers', 1)],
    },
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('affiche totaux et objectif', (tester) async {
    await tester.pumpWidget(
      _host(ChkobbaRoundCard(summary: _summary(), onContinue: () {})),
    );

    expect(find.text('Manche 1'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Objectif : 11 points'), findsOneWidget);
  });

  testWidgets('Manche suivante déclenche onContinue', (tester) async {
    var continued = 0;
    await tester.pumpWidget(
      _host(
        ChkobbaRoundCard(summary: _summary(), onContinue: () => continued++),
      ),
    );

    await tester.tap(find.text('Manche suivante →'));
    expect(continued, 1);
  });

  testWidgets('partie finie : action vers le résultat', (tester) async {
    var continued = 0;
    await tester.pumpWidget(
      _host(
        ChkobbaRoundCard(
          summary: _summary(winner: Player.player),
          onContinue: () => continued++,
        ),
      ),
    );

    expect(find.text('Manche suivante →'), findsNothing);
    await tester.tap(find.text('Voir le résultat final'));
    expect(continued, 1);
  });
}
