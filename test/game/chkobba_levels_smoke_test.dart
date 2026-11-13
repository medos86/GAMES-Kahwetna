// Garde-fou rapide en CI (issue #92) : 200 parties par niveau contre le niveau moyen.
// La marge d'erreur est d'environ ±7 points : ce test vérifie l'ordre des niveaux,
// pas leur calibration (voir calibration/chkobba_win_rate_test.dart pour ça).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';

import 'chkobba_sim.dart';

void main() {
  group('Chkobba : ordre des niveaux IA (garde-fou, issue #92)', () {
    test('facile reste nettement sous le moyen, difficile au-dessus', () {
      final facile = chkobbaWinRate(ChkobbaAiLevel.facile, games: 200);
      final difficile = chkobbaWinRate(ChkobbaAiLevel.difficile, games: 200);
      expect(facile, lessThan(0.25));
      expect(difficile, greaterThan(0.5));
    });
  });
}
