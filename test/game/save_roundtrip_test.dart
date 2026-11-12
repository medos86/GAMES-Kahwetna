import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart' as chk;
import 'package:kahwetne/game/coinche.dart' as coinche;
import 'package:kahwetne/game/domino.dart' as domino;
import 'package:kahwetne/game/ludo.dart' as ludo;
import 'package:kahwetne/game/rami.dart' as rami;

/// Reprise d'une partie sauvegardée (#112) : toJson → chaîne JSON → fromJson doit redonner le même état.
Map<String, dynamic> _viaString(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  test('Chkobba : aller-retour sur une donne', () {
    final state = chk.newMatch(targetScore: 11);
    expect(
      chk.ChkobbaState.fromJson(_viaString(state.toJson())).toJson(),
      equals(state.toJson()),
    );
  });

  test('Domino : aller-retour sur une manche', () {
    final state = domino.newDominoRound(targetScore: 50);
    expect(
      domino.DominoState.fromJson(_viaString(state.toJson())).toJson(),
      equals(state.toJson()),
    );
  });

  test('Coinche : aller-retour sur un match et une donne', () {
    final match = coinche.newMatch(1000);
    final round = coinche.dealRound(coinche.Seat.east);
    final json = {'match': match.toJson(), 'round': round.toJson()};
    final restored = _viaString(json);
    expect(
      coinche.CoincheMatch.fromJson(restored['match'] as Map<String, dynamic>)
          .toJson(),
      equals(match.toJson()),
    );
    expect(
      coinche.RoundState.fromJson(restored['round'] as Map<String, dynamic>)
          .toJson(),
      equals(round.toJson()),
    );
  });

  test('Ludo : aller-retour sur une partie neuve', () {
    final state = ludo.newLudoGame();
    expect(
      ludo.LudoState.fromJson(_viaString(state.toJson())).toJson(),
      equals(state.toJson()),
    );
  });

  test('Rami : aller-retour sur une donne', () {
    final state = rami.newMatch(100, null);
    expect(
      rami.RamiState.fromJson(_viaString(state.toJson())).toJson(),
      equals(state.toJson()),
    );
  });
}
