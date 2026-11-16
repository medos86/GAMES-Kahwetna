import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

// Difficulté et score cible mémorisés par jeu (#113).
void main() {
  test('difficulté : rien d enregistré donne Facile', () {
    expect(difficultyFromPrefs(null), Difficulty.facile);
  });

  test('difficulté : la valeur enregistrée est reprise', () {
    expect(difficultyFromPrefs('moyen'), Difficulty.moyen);
    expect(difficultyFromPrefs('difficile'), Difficulty.difficile);
  });

  test('difficulté : une valeur inconnue donne Facile', () {
    expect(difficultyFromPrefs('bidon'), Difficulty.facile);
  });

  test('score cible : un choix valide du jeu est repris', () {
    final game = gameEntries.firstWhere((g) => g.targets.length > 1);
    final other = game.targets.last;
    expect(targetFromPrefs(game, other), other);
  });

  test('score cible : rien d enregistré garde la valeur par défaut', () {
    final game = gameEntries.firstWhere((g) => g.targets.isNotEmpty);
    expect(targetFromPrefs(game, null), game.defaultTarget);
  });

  test('score cible : une valeur hors des choix du jeu est ignorée', () {
    final game = gameEntries.firstWhere((g) => g.targets.isNotEmpty);
    expect(targetFromPrefs(game, -1), game.defaultTarget);
  });
}
