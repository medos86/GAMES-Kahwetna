// Routage centralisé des écrans de jeu (guide §1.3 et §9.1).
//
// Décision : on garde le Navigator de Flutter au lieu de go_router. L'application
// n'a que cinq écrans de jeu, un seul niveau de navigation, et aucun lien profond
// à gérer pour l'instant. Les chemins et paramètres reprennent le format de React
// Router (/game?difficulty=facile&target=11), donc un passage à go_router reste
// possible sans changer les écrans.

import 'package:flutter/material.dart';

import '../features/chkobba/chkobba_screen.dart';
import '../features/coinche/coinche_screen.dart';
import '../features/domino/domino_screen.dart';
import '../features/ludo/ludo_screen.dart';
import '../features/menu/menu_models.dart';
import '../features/rami/rami_screen.dart';

/// Nombre de joueurs humains au Ludo (1 à 4).
const ludoMinPlayers = 1;
const ludoMaxPlayers = 4;

/// Le jeu du menu dont le chemin est [path] (/game, /domino, /coinche, /ludo, /rami).
GameEntry? gameForRoute(String path) {
  for (final entry in gameEntries) {
    if (entry.route == path) return entry;
  }
  return null;
}

/// Niveau de l'IA ; valeur inconnue ou absente : facile.
Difficulty parseDifficulty(String? raw) =>
    Difficulty.values.asNameMap()[raw] ?? Difficulty.facile;

/// Objectif de partie ; doit faire partie des valeurs du jeu, sinon la première.
int parseTarget(String? raw, List<int> allowed) {
  if (allowed.isEmpty) return 0;
  final value = int.tryParse(raw ?? '');
  return value != null && allowed.contains(value) ? value : allowed.first;
}

/// Nombre de joueurs au Ludo ; hors bornes ou absent : ramené dans 1..4, un joueur par défaut.
int parsePlayers(String? raw) {
  final value = int.tryParse(raw ?? '');
  if (value == null) return ludoMinPlayers;
  return value.clamp(ludoMinPlayers, ludoMaxPlayers);
}

/// Route d'un écran de jeu à partir de son nom (« /domino?difficulty=moyen&target=100 »).
/// Renvoie null si le chemin n'est pas un jeu connu.
Route<void>? buildGameRoute(String? name) {
  final uri = Uri.parse(name ?? '/');
  final entry = gameForRoute(uri.path);
  if (entry == null) return null;

  final query = uri.queryParameters;
  final difficulty = parseDifficulty(query['difficulty']);
  final target = parseTarget(query['target'], entry.targets);

  final Widget? screen = switch (entry.name) {
    'Chkobba' => ChkobbaScreen(
      difficulty: difficulty,
      targetScore: target,
      demoChoice: query['demo'] == 'choice',
    ),
    'Domino' => DominoScreen(difficulty: difficulty, targetScore: target),
    'Belote' => CoincheScreen(difficulty: difficulty, targetScore: target),
    'Ludo' => LudoScreen(
      difficulty: difficulty,
      players: parsePlayers(query['players']),
    ),
    'Rami' => RamiScreen(difficulty: difficulty, targetScore: target),
    _ => null,
  };
  if (screen == null) return null;
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => screen,
  );
}
