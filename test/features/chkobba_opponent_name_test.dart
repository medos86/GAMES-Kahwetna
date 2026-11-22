// Prénoms de l'adversaire de la Chkobba (#766) : tirage dans la liste,
// sans doublon ni nom vide.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_opponent_name.dart';

void main() {
  test('le nom tiré appartient à la liste des prénoms', () {
    final random = math.Random(7);
    for (var i = 0; i < 50; i++) {
      expect(chkobbaOpponentNames, contains(pickOpponentName(random)));
    }
  });

  test('la liste n\'a ni doublon ni nom vide', () {
    final unique = chkobbaOpponentNames.toSet();
    expect(unique, hasLength(chkobbaOpponentNames.length));
    expect(chkobbaOpponentNames.every((n) => n.trim().isNotEmpty), isTrue);
  });

  test('les tirages ne donnent pas toujours le même prénom', () {
    final random = math.Random(42);
    final seen = {for (var i = 0; i < 50; i++) pickOpponentName(random)};
    expect(seen.length, greaterThan(3));
  });
}
