// Calibration des niveaux IA Rami (issue #305) : 2 000 matchs par niveau, en mesure seule.
// Lancé chaque nuit par le workflow « Calibration IA Rami », pas à chaque push.
// Lancement manuel : flutter test calibration/rami_win_rate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/game/rami.dart';

import '../test/game/rami_sim.dart';

const _games = 2000;

void main() {
  group('Rami : taux de victoire des niveaux IA (issue #305)', () {
    final targets = {
      RamiAiLevel.facile: 0.30,
      RamiAiLevel.moyen: 0.50,
      RamiAiLevel.difficile: 0.90,
    };

    for (final entry in targets.entries) {
      final level = entry.key;
      final pct = (entry.value * 100).round();
      test('niveau ${level.name} : matchs contre trois moyens', () {
        final rate = ramiWinRate(level, games: _games);
        final measured = (rate * 100).toStringAsFixed(1);
        // ignore: avoid_print
        print(
          'Rami ${level.name} : $measured % sur $_games matchs (cible $pct %)',
        );
      });
    }
  });
}
