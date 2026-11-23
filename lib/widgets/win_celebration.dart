import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';

/// Effet de fin de partie façon boîte de nuit (issue #814).
///
/// Victoire : papiers/confettis qui tombent, boule à facettes en haut et
/// faisceaux de lumière qui balayent l'écran.
/// Défaite : voile gris discret et léger tremblement, sans confettis.
///
/// L'animation dure [duration] puis s'arrête (pas de boucle infinie).
/// Avec « réduire les animations » activé, rien n'est dessiné.
/// Le widget ne capte pas les touches : les boutons restent utilisables.
class WinCelebration extends StatefulWidget {
  const WinCelebration({
    super.key,
    required this.won,
    this.duration = const Duration(milliseconds: 2600),
  });

  final bool won;
  final Duration duration;

  @override
  State<WinCelebration> createState() => _WinCelebrationState();
}

class _WinCelebrationState extends State<WinCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_reduceMotion) {
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
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Animation terminée ou réduction demandée : plus rien à dessiner.
            if (_reduceMotion || _controller.isCompleted) {
              return const SizedBox.shrink();
            }
            final t = _controller.value;
            final painter = CustomPaint(
              key: widget.won
                  ? const Key('win-celebration-confetti')
                  : const Key('win-celebration-defeat'),
              painter: WinCelebrationPainter(progress: t, won: widget.won),
              child: const SizedBox.expand(),
            );
            if (widget.won) return painter;
            // Défaite : léger tremblement qui s'éteint.
            final shake = math.sin(t * 2 * math.pi * 6) * 4 * (1 - t);
            return Transform.translate(
              offset: Offset(shake, 0),
              child: painter,
            );
          },
        ),
      ),
    );
  }
}

/// Peinture de l'effet [WinCelebration]. [progress] va de 0 à 1.
class WinCelebrationPainter extends CustomPainter {
  WinCelebrationPainter({required this.progress, required this.won});

  final double progress;
  final bool won;

  /// Couleurs des faisceaux de la boule à facettes.
  static const List<Color> beamColors = [
    Color(0xFF9EE7FF),
    Color(0xFFFF8FD8),
    Color(0xFFFFF59D),
    Color(0xFFB9FBC0),
  ];

  static const Color _silver = Color(0xFFDDE3EA);
  static const Color _mirror = Color(0xFFFFFFFF);

  static const List<Color> _confettiColors = [
    ComicPalette.red,
    ComicPalette.yellow,
    ComicPalette.tunisBlue,
    ComicPalette.seatGreen,
    ComicPalette.white,
    ComicPalette.gold,
  ];

  /// Nombre de confettis (issue #814 : entre 60 et 120).
  static const int confettiCount = 90;

  /// Particules fixes, générées avec une graine : rendu identique à chaque build.
  static final List<_Particle> _particles = _buildParticles(math.Random(814));

  static List<_Particle> _buildParticles(math.Random random) {
    return List<_Particle>.generate(confettiCount, (i) {
      return _Particle(
        x: random.nextDouble(),
        fall: 0.8 + random.nextDouble() * 0.45,
        sway: 0.02 + random.nextDouble() * 0.05,
        swayFreq: 1 + random.nextDouble() * 2,
        phase: random.nextDouble() * 2 * math.pi,
        spin: (random.nextDouble() * 2 - 1) * 3,
        flip: 2 + random.nextDouble() * 3,
        size: 6 + random.nextDouble() * 5,
        color: _confettiColors[i % _confettiColors.length],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (won) {
      _paintBeams(canvas, size);
      _paintDiscoBall(canvas, size);
      _paintConfetti(canvas, size);
    } else {
      _paintVeil(canvas, size);
    }
  }

  /// Ramène [v] dans [0, 1] en gardant le type `double`.
  static double _unit(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  Offset _ballCenter(Size size) => Offset(size.width / 2, size.height * 0.14);

  void _paintConfetti(Canvas canvas, Size size) {
    // Les confettis s'estompent sur le dernier quart de l'animation.
    final fade = progress < 0.75 ? 1.0 : _unit((1 - progress) / 0.25);
    final paint = Paint();
    for (final p in _particles) {
      final y = size.height * (-0.08 + p.fall * progress * 1.15);
      if (y > size.height + 20) continue;
      final sway = math.sin(progress * p.swayFreq * 2 * math.pi + p.phase);
      final x = size.width * (p.x + sway * p.sway);
      // Rotation 3D simulée : la hauteur du papier varie comme un cosinus.
      final flip = math.cos(progress * p.flip * 2 * math.pi + p.phase).abs();
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin * 2 * math.pi + p.phase);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * (0.3 + 0.7 * flip),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintDiscoBall(Canvas canvas, Size size) {
    final center = _ballCenter(size);
    final radius = math.min(size.width, size.height) * 0.07;
    final appear = _unit(progress / 0.15);
    final fade = progress > 0.85 ? _unit((1 - progress) / 0.15) : 1.0;
    final alpha = appear * fade;
    if (alpha <= 0) return;

    // Fil de suspension.
    canvas.drawLine(
      Offset(center.dx, 0),
      center - Offset(0, radius),
      Paint()
        ..color = ComicPalette.ink.withValues(alpha: alpha)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _silver.withValues(alpha: alpha),
    );

    // Miroirs : petits carrés répartis sur trois rangées, qui tournent.
    final spin = progress * 2 * math.pi * 2;
    for (var i = 0; i < 9; i++) {
      final a = spin + i * 2 * math.pi / 9;
      // Profondeur : 0 au bord du globe, 1 face à l'écran.
      final depth = (math.cos(a) + 1) / 2;
      final row = (i % 3) - 1;
      final mirror = Offset(
        center.dx + math.sin(a) * radius * 0.7,
        center.dy + row * radius * 0.45,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: mirror,
          width: radius * 0.4,
          height: radius * 0.4,
        ),
        Paint()
          ..color = _mirror.withValues(alpha: alpha * (0.3 + 0.7 * depth)),
      );
    }
  }

  void _paintBeams(Canvas canvas, Size size) {
    final envelope = math.sin(math.pi * progress);
    if (envelope <= 0) return;
    final origin = _ballCenter(size);
    final length = size.height * 1.2;
    const spread = 0.14;
    for (var i = 0; i < beamColors.length; i++) {
      // Chaque faisceau balaie l'écran avec sa propre phase.
      final sweep = math.sin(progress * 2 * math.pi * 1.5 + i * 1.3) * 0.6;
      final angle =
          math.pi / 2 + sweep + (i - (beamColors.length - 1) / 2) * 0.35;
      final left = origin +
          Offset(math.cos(angle - spread), math.sin(angle - spread)) * length;
      final right = origin +
          Offset(math.cos(angle + spread), math.sin(angle + spread)) * length;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = beamColors[i].withValues(alpha: 0.28 * envelope)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _paintVeil(Canvas canvas, Size size) {
    final alpha = math.sin(math.pi * progress) * 0.4;
    if (alpha <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF555555).withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(WinCelebrationPainter old) =>
      old.progress != progress || old.won != won;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.fall,
    required this.sway,
    required this.swayFreq,
    required this.phase,
    required this.spin,
    required this.flip,
    required this.size,
    required this.color,
  });

  /// Position horizontale de départ, en fraction de la largeur.
  final double x;

  /// Vitesse de chute relative.
  final double fall;

  /// Amplitude du balancement, en fraction de la largeur.
  final double sway;
  final double swayFreq;
  final double phase;

  /// Vitesse de rotation (tours par animation).
  final double spin;

  /// Vitesse du retournement du papier.
  final double flip;
  final double size;
  final Color color;
}
