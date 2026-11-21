// Garde-fou rapide en CI (issue #720) : 200 parties par niveau contre le niveau moyen.
// La marge d'erreur est d'environ ±7 points : ce test vérifie l'ordre des niveaux,
// pas leur calibration (voir calibration/coinche_win_rate_test.dart pour ça).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

import 'coinche_sim.dart';

void main() {
  group('Coinche : ordre des niveaux IA (garde-fou, issue #720)', () {
    test('facile reste nettement sous le moyen, difficile au-dessus', () {
      final facile = coincheWinRate(CoincheAiLevel.facile, games: 200);
      final difficile = coincheWinRate(CoincheAiLevel.difficile, games: 200);
      // Cible du facile : 30 %. Marge ±7 points à 200 parties : seuil 0,40.
      expect(facile, lessThan(0.40));
      expect(difficile, greaterThan(0.5));
      expect(facile, lessThan(difficile));
    });
  });
}
