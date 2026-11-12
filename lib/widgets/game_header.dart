import 'package:flutter/material.dart';

import '../core/strings.dart';

/// En-tête commun des écrans de jeu (guide §8 : GameHeader).
/// Bouton Menu (texte masqué sous 390 px de large), titre « KAHWETNE · JEU »,
/// sous-titre (ex. « Manche 3 ») et emplacement à droite (trophée, règles…).
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.gameName,
    required this.onMenu,
    this.subtitle,
    this.trailing,
  });

  /// Nom du jeu en majuscules, ex. « CHKOBBA » → « KAHWETNE · CHKOBBA ».
  final String gameName;
  final VoidCallback onMenu;
  final String? subtitle;
  final Widget? trailing;

  static const double _labelBreakpoint = 390;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabel = MediaQuery.sizeOf(context).width >= _labelBreakpoint;
        return Row(
          children: [
            Semantics(
              button: true,
              label: Strings.menuLabel,
              child: TextButton.icon(
                onPressed: onMenu,
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xFFFFF1BD),
                ),
                label: showLabel
                    ? Text(
                        Strings.menuLabel,
                        style: TextStyle(
                          color: Color(0xFFFFF1BD),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : const SizedBox.shrink(),
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KAHWETNE · $gameName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFF1BD),
                      shadows: [
                        Shadow(offset: Offset(1, 2), color: Color(0xFF4A2A10)),
                      ],
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xCCFFF8E7),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        );
      },
    );
  }
}
