// Calibration des niveaux IA Ludo (issue #305) : 2 000 parties par niveau, en mesure seule.
// Lancé chaque nuit par le workflow « Calibration IA Ludo », pas à chaque push.
// Lancement manuel : flutter test calibration/ludo_win_rate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/ludo.dart';

import '../test/game/ludo_sim.dart';

const _games = 2000;

void main() {
  group('Ludo : taux de victoire des niveaux IA (issue #305)', () {
    final targets = {
      LudoAiLevel.facile: 0.30,
      LudoAiLevel.moyen: 0.50,
      LudoAiLevel.difficile: 0.80,
    };

    for (final entry in targets.entries) {
      final level = entry.key;
      final pct = (entry.value * 100).round();
      test('niveau ${level.name} : première place contre trois moyens', () {
        final rate = ludoWinRate(level, games: _games);
        final measured = (rate * 100).toStringAsFixed(1);
        // ignore: avoid_print
        print(
          'Ludo ${level.name} : $measured % sur $_games parties (cible $pct %)',
        );
      });
    }
  });
}
