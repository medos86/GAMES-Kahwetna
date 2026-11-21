// Calibration des niveaux IA Coinche (issue #720) : 2 000 parties par niveau, en mesure seule.
// Lancé chaque nuit par le workflow « Calibration IA Coinche », pas à chaque push.
// Lancement manuel : flutter test calibration/coinche_win_rate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/coinche.dart';

import '../test/game/coinche_sim.dart';

const _games = 2000;

void main() {
  group('Coinche : taux de victoire des niveaux IA (issue #720)', () {
    final targets = {
      CoincheAiLevel.facile: 0.30,
      CoincheAiLevel.moyen: 0.50,
      CoincheAiLevel.difficile: 0.85,
    };

    for (final entry in targets.entries) {
      final level = entry.key;
      final pct = (entry.value * 100).round();
      test('niveau ${level.name} : mesure contre moyen', () {
        final rate = coincheWinRate(level, games: _games);
        final measured = (rate * 100).toStringAsFixed(1);
        print(
          'Coinche ${level.name} : $measured % sur $_games parties (cible $pct %)',
        );
      });
    }
  });
}
