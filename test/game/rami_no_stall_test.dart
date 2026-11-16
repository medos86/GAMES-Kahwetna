// Une partie de Rami ne doit jamais se bloquer, quel que soit le niveau IA (issue #305).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

import 'rami_sim.dart';

void main() {
  group('Rami : aucune partie IA bloquée', () {
    for (final level in RamiAiLevel.values) {
      test('niveau ${level.name} : 30 matchs complets sans blocage', () {
        for (var seed = 0; seed < 30; seed++) {
          playRamiMatch(level, seed % 4, seed + 1);
        }
      });
    }
  });
}
