import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

// Options de difficulté, clés de sauvegarde et adresse de lancement (#167).
void main() {
  test('trois niveaux dans l\'ordre facile, moyen, difficile', () {
    expect(
      difficultyOptions.map((o) => o.difficulty),
      Difficulty.values,
    );
  });

  test('chaque clé de sauvegarde correspond à un jeu du menu', () {
    for (final route in savedGameKeys.keys) {
      expect(gameEntries.any((g) => g.route == route), isTrue);
    }
  });

  test('Ludo reçoit les joueurs, les autres la manche', () {
    final ludo = gameEntries.firstWhere((g) => g.isLudo);
    final other = gameEntries.firstWhere((g) => !g.isLudo);

    final ludoRequest = LaunchRequest(
      game: ludo,
      difficulty: Difficulty.moyen,
      target: 11,
      players: 3,
    );
    expect(
      ludoRequest.location,
      '${ludo.route}?difficulty=moyen&players=3',
    );

    final otherRequest = LaunchRequest(
      game: other,
      difficulty: Difficulty.difficile,
      target: 21,
      players: 2,
    );
    expect(
      otherRequest.location,
      '${other.route}?difficulty=difficile&target=21',
    );
  });
}
