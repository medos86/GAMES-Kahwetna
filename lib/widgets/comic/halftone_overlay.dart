import 'package:flutter/material.dart';

import '../../core/theme/comic_palette.dart';

/// Trame de points façon impression BD (issue #94).
/// Dessinée par-dessus [child] sans bloquer les touches.
class HalftoneOverlay extends StatelessWidget {
  const HalftoneOverlay({
    super.key,
    required this.child,
    this.dotColor = ComicPalette.halftone,
    this.spacing = 8,
    this.radius = 1.5,
  });

  final Widget child;
  final Color dotColor;

  /// Distance entre deux points, en pixels logiques.
  final double spacing;

  /// Rayon de chaque point, en pixels logiques.
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _HalftonePainter(
                  color: dotColor,
                  spacing: spacing,
                  radius: radius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HalftonePainter extends CustomPainter {
  _HalftonePainter({
    required this.color,
    required this.spacing,
    required this.radius,
  });

  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Rangées décalées d'une demi-maille, comme une trame d'imprimerie.
    var row = 0;
    for (double y = spacing / 2; y < size.height; y += spacing, row++) {
      final offset = row.isOdd ? spacing / 2 : 0.0;
      for (double x = spacing / 2 + offset; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}
