import 'package:flutter/material.dart';

import '../../core/theme/comic_palette.dart';
import 'comic_panel.dart';

/// Bouton BD compact (libellé en Bangers, icône optionnelle) pour les en-têtes (issue #97).
class ComicPill extends StatelessWidget {
  const ComicPill({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.fill = ComicPalette.paper,
    this.foreground = ComicPalette.ink,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color fill;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: ComicPanel(
          color: fill,
          outlineColor: ComicPalette.ink,
          radius: 12,
          shadowOffset: const Offset(3, 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(fontFamily: 'Bangers', fontSize: 18, letterSpacing: 1, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
