// Garde-fou rapide en CI (issue #305) : 200 parties par niveau.
// Vérifie l'ordre des niveaux, pas leur calibration (voir calibration/ludo_win_rate_test.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';

import 'ludo_sim.dart';

void main() {
  group('Ludo : ordre des niveaux IA (garde-fou, issue #305)', () {
    test('difficile fait mieux que facile', () {
      final facile = ludoWinRate(LudoAiLevel.facile, games: 200);
      final difficile = ludoWinRate(LudoAiLevel.difficile, games: 200);
      expect(difficile, greaterThan(facile));
    });
  });
}
