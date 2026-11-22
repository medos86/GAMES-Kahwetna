// Prénoms des adversaires de la Belote (issue #770) : tirage aléatoire et sièges latéraux verticaux.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_opponent_names.dart';
import 'package:kahwetne/game/coinche.dart';

void main() {
  test('chaque adversaire reçoit un prénom distinct de la liste', () {
    final names = pickCoincheOpponentNames(math.Random(3));
    expect(names.keys, unorderedEquals([Seat.north, Seat.west, Seat.east]));
    expect(names.values.toSet(), hasLength(3));
    for (final name in names.values) {
      expect(coincheOpponentNames, contains(name));
    }
  });

  test('les tirages ne donnent pas toujours le même partenaire', () {
    final random = math.Random(42);
    final seen = <String>{};
    for (var i = 0; i < 30; i++) {
      seen.add(pickCoincheOpponentNames(random)[Seat.north]!);
    }
    expect(seen.length, greaterThan(3));
  });

  test('la liste n\'a ni doublon ni nom vide ni « Toi »', () {
    final unique = coincheOpponentNames.toSet();
    expect(unique, hasLength(coincheOpponentNames.length));
    expect(coincheOpponentNames.every((n) => n.trim().isNotEmpty), isTrue);
    expect(coincheOpponentNames, isNot(contains('Toi')));
  });

  test('le joueur s\'affiche toujours « Toi »', () {
    expect(coincheSeatName(const {}, Seat.south), 'Toi');
  });

  test('un adversaire s\'affiche avec le prénom tiré pour son siège', () {
    final names = {Seat.north: 'Nour', Seat.west: 'Hedi', Seat.east: 'Ines'};
    expect(coincheSeatName(names, Seat.west), 'Hedi');
    expect(coincheSeatName(names, Seat.north), 'Nour');
  });

  test('sièges latéraux écrits verticalement, haut horizontal', () {
    expect(coincheSeatQuarterTurns(Seat.west), 3);
    expect(coincheSeatQuarterTurns(Seat.east), 1);
    expect(coincheSeatQuarterTurns(Seat.north), 0);
    expect(coincheSeatQuarterTurns(Seat.south), 0);
  });
}
