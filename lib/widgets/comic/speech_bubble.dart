import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';

/// Bulle de dialogue BD avec queue (issue #94).
/// La queue pointe vers le bas, à gauche ou à droite.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    this.tailOnLeft = true,
    this.fill = ComicPalette.paper,
    this.tailHeight = 14,
    this.tailWidth = 22,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
  });

  final Widget child;
  final bool tailOnLeft;
  final Color fill;
  final double tailHeight;
  final double tailWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: tailHeight),
      child: CustomPaint(
        painter: _BubblePainter(
          fill: fill,
          tailOnLeft: tailOnLeft,
          tailHeight: tailHeight,
          tailWidth: tailWidth,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.fill,
    required this.tailOnLeft,
    required this.tailHeight,
    required this.tailWidth,
  });

  final Color fill;
  final bool tailOnLeft;
  final double tailHeight;
  final double tailWidth;

  static const double _inset = 24;
  static const double _radius = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyBottom = size.height - tailHeight;
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, 0, size.width, bodyBottom),
          const Radius.circular(_radius),
        ),
      );

    final baseLeft = tailOnLeft ? _inset : size.width - _inset - tailWidth;
    final tailPath = Path()
      ..moveTo(baseLeft, bodyBottom - 2)
      ..lineTo(baseLeft + tailWidth, bodyBottom - 2)
      ..lineTo(tailOnLeft ? baseLeft : baseLeft + tailWidth, size.height)
      ..close();

    final shape = Path.combine(PathOperation.union, body, tailPath);

    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = ComicPalette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fill != fill ||
      old.tailOnLeft != tailOnLeft ||
      old.tailHeight != tailHeight ||
      old.tailWidth != tailWidth;
}
