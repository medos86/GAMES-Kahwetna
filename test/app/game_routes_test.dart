// Routage des jeux : chemins connus, repli des paramètres, routes inconnues.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/app/game_routes.dart';
import 'package:kahwetne/features/menu/menu_models.dart';

void main() {
  test('un chemin connu renvoie son jeu, un inconnu renvoie null', () {
    expect(gameForRoute('/rami')?.name, 'Rami');
    expect(gameForRoute('/game')?.name, 'Chkobba');
    expect(gameForRoute('/nope'), isNull);
  });

  test('difficulté : valeur connue, sinon facile', () {
    expect(parseDifficulty('moyen'), Difficulty.moyen);
    expect(parseDifficulty('difficile'), Difficulty.difficile);
    expect(parseDifficulty('n_importe_quoi'), Difficulty.facile);
    expect(parseDifficulty(null), Difficulty.facile);
  });

  test('objectif : doit appartenir aux valeurs du jeu, sinon la première', () {
    expect(parseTarget('21', [11, 21]), 21);
    expect(parseTarget('5', [11, 21]), 11);
    expect(parseTarget(null, [50, 100, 200]), 50);
    expect(parseTarget('200', []), 0);
  });

  test('joueurs : ramenés entre 1 et 4, un joueur par défaut', () {
    expect(parsePlayers('3'), 3);
    expect(parsePlayers('9'), 4);
    expect(parsePlayers('0'), 1);
    expect(parsePlayers('abc'), 1);
    expect(parsePlayers(null), 1);
  });

  test('buildGameRoute garde le nom de la route et ignore les chemins inconnus', () {
    final route = buildGameRoute('/game?difficulty=moyen&target=21');
    expect(route, isNotNull);
    expect(route!.settings.name, '/game?difficulty=moyen&target=21');
    expect(buildGameRoute('/inconnu?difficulty=facile'), isNull);
    expect(buildGameRoute(null), isNull);
  });
}
