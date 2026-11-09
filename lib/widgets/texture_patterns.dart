import 'package:flutter/material.dart';

/// Trame de points, équivalent de `radial-gradient(circle, color rayon, transparent rayon)`
/// répété tous les `spacing` px. La couleur porte l'opacité du CSS source.
/// Utiliser dans un `Positioned.fill` (il n'a pas de taille propre).
class DotPattern extends StatelessWidget {
  const DotPattern({super.key, required this.spacing, required this.radius, required this.color});

  final double spacing;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPainter(spacing, radius, color));
  }
}

/// Rayures répétées, équivalent de `repeating-linear-gradient` :
/// une bande de `width` px en fin de chaque période de `period` px.
/// `vertical` : rayures verticales (gradient à 90deg), sinon horizontales (0deg).
class StripePattern extends StatelessWidget {
  const StripePattern({
    super.key,
    required this.period,
    required this.width,
    required this.color,
    this.vertical = false,
  });

  final double period;
  final double width;
  final Color color;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StripePainter(period, width, color, vertical));
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter(this.spacing, this.radius, this.color);

  final double spacing;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var y = spacing / 2; y < size.height + spacing; y += spacing) {
      for (var x = spacing / 2; x < size.width + spacing; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) =>
      old.spacing != spacing || old.radius != radius || old.color != color;
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.period, this.width, this.color, this.vertical);

  final double period;
  final double width;
  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final length = vertical ? size.width : size.height;
    final thickness = vertical ? size.height : size.width;
    for (var start = 0.0; start < length; start += period) {
      final from = start + period - width;
      if (from >= length) break;
      final stripe = vertical
          ? Rect.fromLTWH(from, 0, width, thickness)
          : Rect.fromLTWH(0, from, thickness, width);
      canvas.drawRect(stripe, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.period != period || old.width != width || old.color != color || old.vertical != vertical;
}
