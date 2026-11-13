// Calibration des niveaux IA Chkobba (issue #92) : 2 000 parties par niveau, en mesure seule.
// Lancé chaque nuit par le workflow « Calibration IA Chkobba », pas à chaque push.
// Lancement manuel : flutter test calibration/chkobba_win_rate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/chkobba.dart';

import '../test/game/chkobba_sim.dart';

const _games = 2000;

void main() {
  group('Chkobba : taux de victoire des niveaux IA (issue #92)', () {
    final targets = {
      ChkobbaAiLevel.facile: 0.30,
      ChkobbaAiLevel.moyen: 0.50,
      ChkobbaAiLevel.difficile: 0.90,
    };

    for (final entry in targets.entries) {
      final level = entry.key;
      final pct = (entry.value * 100).round();
      test('niveau ${level.name} : mesure contre moyen', () {
        final rate = chkobbaWinRate(level, games: _games);
        final measured = (rate * 100).toStringAsFixed(1);
        print(
          'Chkobba ${level.name} : $measured % sur $_games parties (cible $pct %)',
        );
      });
    }
  });
}
