import 'package:flutter/material.dart';
import '../../core/strings.dart';

/// Données du menu, reprises de src/app/components/MainMenu.tsx.

enum Difficulty { facile, moyen, difficile }

class DifficultyOption {
  const DifficultyOption({
    required this.difficulty,
    required this.label,
    required this.detail,
    required this.icon,
    required this.activeBackground,
    required this.activeForeground,
    required this.activeShadow,
  });

  final Difficulty difficulty;
  final String label;
  final String detail;
  final IconData icon;
  final Color activeBackground;
  final Color activeForeground;
  final Color activeShadow;
}

const difficultyOptions = <DifficultyOption>[
  DifficultyOption(
    difficulty: Difficulty.facile,
    label: Strings.levelEasy,
    detail: Strings.levelEasyDetail,
    icon: Icons.wb_cloudy,
    activeBackground: Color(0xFFFFE16B),
    activeForeground: Color(0xFF513B00),
    activeShadow: Color(0xFFD99921),
  ),
  DifficultyOption(
    difficulty: Difficulty.moyen,
    label: Strings.levelMedium,
    detail: Strings.levelMediumDetail,
    icon: Icons.local_fire_department,
    activeBackground: Color(0xFFFF8A4C),
    activeForeground: Color(0xFF4D1C0A),
    activeShadow: Color(0xFFB84327),
  ),
  DifficultyOption(
    difficulty: Difficulty.difficile,
    label: Strings.levelHard,
    detail: Strings.levelHardDetail,
    icon: Icons.nightlight_round,
    activeBackground: Color(0xFF9B8CFF),
    activeForeground: Color(0xFF21195C),
    activeShadow: Color(0xFF5B43B8),
  ),
];

class GameEntry {
  const GameEntry({
    required this.name,
    required this.tunisian,
    required this.gradientFrom,
    required this.gradientTo,
    required this.edgeColor,
    required this.iconAsset,
    required this.route,
    required this.targets,
    required this.defaultTarget,
  });

  final String name;
  final String tunisian;
  final Color gradientFrom;
  final Color gradientTo;
  final Color edgeColor;
  final String iconAsset;

  /// Chemin de la partie (même contrat que le web, cf. guide §1.3).
  final String route;

  /// Scores proposés ; vide pour le Ludo (pas de score cible).
  final List<int> targets;
  final int defaultTarget;

  bool get isLudo => name == 'Ludo';
}

const gameEntries = <GameEntry>[
  GameEntry(
    name: 'Chkobba',
    tunisian: 'شكبة',
    gradientFrom: Color(0xFFFFCF48),
    gradientTo: Color(0xFFF49A28),
    edgeColor: Color(0xFFA64A1D),
    iconAsset: 'assets/icons/game_chkobba.svg',
    route: '/game',
    targets: [11, 21],
    defaultTarget: 11,
  ),
  GameEntry(
    name: 'Domino',
    tunisian: 'دومينو',
    gradientFrom: Color(0xFF56D5C8),
    gradientTo: Color(0xFF149E9F),
    edgeColor: Color(0xFF08706F),
    iconAsset: 'assets/icons/game_domino.svg',
    route: '/domino',
    targets: [50, 100, 200],
    defaultTarget: 50,
  ),
  GameEntry(
    name: 'Belote',
    tunisian: 'بلوت',
    gradientFrom: Color(0xFFFF7395),
    gradientTo: Color(0xFFD83968),
    edgeColor: Color(0xFF92264C),
    iconAsset: 'assets/icons/game_belote.svg',
    route: '/coinche',
    targets: [500, 1000],
    defaultTarget: 1000,
  ),
  GameEntry(
    name: 'Ludo',
    tunisian: 'لودو',
    gradientFrom: Color(0xFF8B86FF),
    gradientTo: Color(0xFF5A4ED0),
    edgeColor: Color(0xFF3D3292),
    iconAsset: 'assets/icons/game_ludo.svg',
    route: '/ludo',
    targets: [],
    defaultTarget: 11,
  ),
  GameEntry(
    name: 'Rami',
    tunisian: 'رامي',
    gradientFrom: Color(0xFF4BA9FF),
    gradientTo: Color(0xFF3266D5),
    edgeColor: Color(0xFF214597),
    iconAsset: 'assets/icons/game_rami.svg',
    route: '/rami',
    targets: [100, 200],
    defaultTarget: 100,
  ),
];

/// Paramètres transmis à l'écran de jeu. `location` reprend le format du web.
class LaunchRequest {
  const LaunchRequest({
    required this.game,
    required this.difficulty,
    required this.target,
    required this.players,
  });

  final GameEntry game;
  final Difficulty difficulty;
  final int target;
  final int players;

  String get location => game.isLudo
      ? '${game.route}?difficulty=${difficulty.name}&players=$players'
      : '${game.route}?difficulty=${difficulty.name}&target=$target';
}
