import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme/comic_palette.dart';
import '../features/menu/menu_models.dart';

/// Pastille BD discrète qui indique le niveau de la partie en cours (issue #220).
/// Couleurs et icône repris du menu (difficultyOptions), pour que le joueur reconnaisse le niveau choisi.
class DifficultyChip extends StatelessWidget {
  const DifficultyChip({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final option = difficultyOptions.firstWhere(
      (o) => o.difficulty == difficulty,
    );
    return Semantics(
      container: true,
      label: '${Strings.menuDifficultyTitle} : ${option.label}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: option.activeBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ComicPalette.ink, width: 2),
            boxShadow: const [
              BoxShadow(offset: Offset(2, 2), color: ComicPalette.ink),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 14, color: option.activeForeground),
              const SizedBox(width: 4),
              Text(
                option.label,
                style: TextStyle(
                  fontFamily: 'Bangers',
                  fontSize: 14,
                  letterSpacing: 1,
                  color: option.activeForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
