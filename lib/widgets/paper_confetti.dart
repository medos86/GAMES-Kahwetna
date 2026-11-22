import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Un morceau de papier jeté : position de départ, délai, rotation et couleur.
@visibleForTesting
class PaperPiece {
  const PaperPiece({
    required this.x,
    required this.delay,
    required this.spin,
    required this.drift,
    required this.width,
    required this.height,
    required this.color,
  });

  /// Position horizontale de départ, de 0 à 1 (fraction de la largeur).
  final double x;

  /// Retard avant la chute, de 0 à 0.3 (fraction de la durée totale).
  final double delay;

  /// Nombre de tours complets pendant la chute.
  final double spin;

  /// Amplitude du balancement horizontal (fraction de la largeur).
  final double drift;

  final double width;
  final double height;
  final Color color;
}

/// Génère les papiers de façon déterministe à partir de [seed] (tests stables).
@visibleForTesting
List<PaperPiece> buildPaperPieces(int count, int seed) {
  const colors = [
    ComicPalette.yellow,
    ComicPalette.tunisBlue,
    ComicPalette.red,
    ComicPalette.seatGreen,
    ComicPalette.white,
  ];
  final rng = math.Random(seed);
  return List.generate(
    count,
    (_) => PaperPiece(
      x: rng.nextDouble(),
      delay: rng.nextDouble() * 0.3,
      spin: 1 + rng.nextDouble() * 3,
      drift: (rng.nextDouble() - 0.5) * 0.2,
      width: 6 + rng.nextDouble() * 6,
      height: 10 + rng.nextDouble() * 8,
      color: colors[rng.nextInt(colors.length)],
    ),
  );
}

/// Pluie de papiers colorés en style BD, jouée à la victoire (issue #773).
/// Purement décorative : ignore les touchers et s'arrête après [duration].
class PaperConfetti extends StatefulWidget {
  const PaperConfetti({
    super.key,
    this.pieceCount = 60,
    this.duration = const Duration(milliseconds: 2400),
    this.seed = 773,
  });

  final int pieceCount;
  final Duration duration;
  final int seed;

  @override
  State<PaperConfetti> createState() => _PaperConfettiState();
}

class _PaperConfettiState extends State<PaperConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<PaperPiece> _pieces;

  @override
  void initState() {
    super.initState();
    _pieces = buildPaperPieces(widget.pieceCount, widget.seed);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _PaperConfettiPainter(_pieces, _controller),
        ),
      ),
    );
  }
}

class _PaperConfettiPainter extends CustomPainter {
  _PaperConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<PaperPiece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = ComicPalette.ink;

    for (final piece in pieces) {
      final local = (t - piece.delay) / (1 - piece.delay);
      if (local <= 0 || local >= 1) continue;

      final fade = local > 0.85 ? (1 - local) / 0.15 : 1.0;
      final y = local * size.height * 1.1 - 20;
      final x =
          piece.x * size.width +
          math.sin(local * math.pi * 4) * piece.drift * size.width;
      final angle = local * piece.spin * 2 * math.pi;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        height: piece.height,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(
        rect,
        Paint()..color = piece.color.withValues(alpha: fade),
      );
      canvas.drawRect(
        rect,
        outline..color = ComicPalette.ink.withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PaperConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.animation != animation;
}
