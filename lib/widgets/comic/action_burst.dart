import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/comic_palette.dart';

/// Éclat d'impact BD avec une onomatopée (« PAFF ! », « POW ! », « BAM ! ») (issue #94).
///
/// Rebond à l'apparition : échelle 0,2 → 1 et rotation −8° → 0°.
/// Avec « réduire les animations » activé, l'éclat s'affiche d'emblée.
/// Pour rejouer l'animation, change la `key` du widget.
class ActionBurst extends StatefulWidget {
  const ActionBurst({
    super.key,
    required this.text,
    this.color = ComicPalette.yellow,
    this.size = 120,
  });

  final String text;
  final Color color;

  /// Côté du carré dans lequel l'éclat est dessiné.
  final double size;

  @override
  State<ActionBurst> createState() => _ActionBurstState();
}

class _ActionBurstState extends State<ActionBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final scale = 0.2 + 0.8 * Curves.elasticOut.transform(t);
            final angle = (-8 * math.pi / 180) * (1 - Curves.easeOut.transform(t));
            return Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _StarPainter(color: widget.color),
                    child: Center(
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: widget.size * 0.22,
                          letterSpacing: 1,
                          color: ComicPalette.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.color});

  final Color color;

  static const int _points = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 2;
    final inner = outer * 0.74;
    final path = Path();
    for (var i = 0; i < _points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / _points;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = ComicPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
