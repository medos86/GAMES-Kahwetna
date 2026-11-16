// Garde-fou rapide en CI (issue #305) : 200 matchs par niveau.
// Vérifie l'ordre des niveaux, pas leur calibration (voir calibration/rami_win_rate_test.dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

import 'rami_sim.dart';

void main() {
  group('Rami : ordre des niveaux IA (garde-fou, issue #305)', () {
    test('difficile fait mieux que facile', () {
      final facile = ramiWinRate(RamiAiLevel.facile, games: 200);
      final difficile = ramiWinRate(RamiAiLevel.difficile, games: 200);
      expect(difficile, greaterThan(facile));
    });
  });
}
