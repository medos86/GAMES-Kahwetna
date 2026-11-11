import 'package:flutter/material.dart';

import '../../core/theme/comic_palette.dart';
import 'ink_outline.dart';

/// Case de BD (issue #94) : fond papier, contour d'encre et ombre décalée sans flou.
class ComicPanel extends StatelessWidget {
  const ComicPanel({
    super.key,
    required this.child,
    this.color = ComicPalette.paper,
    this.shadowOffset = const Offset(4, 4),
    this.radius = 12,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color color;

  /// Décalage de l'ombre dure (aucun flou).
  final Offset shadowOffset;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding,
      child: child,
    );
    // La place de l'ombre est réservée à droite et en bas.
    return Padding(
      padding: EdgeInsets.only(right: shadowOffset.dx, bottom: shadowOffset.dy),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ombre dure : même forme que la case, décalée, sans flou.
          Positioned(
            left: shadowOffset.dx,
            top: shadowOffset.dy,
            right: -shadowOffset.dx,
            bottom: -shadowOffset.dy,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ComicPalette.ink,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: InkOutline(radius: radius, child: body),
          ),
        ],
      ),
    );
  }
}
