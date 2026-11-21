import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/ludo_backdrop_palette.dart';

/// Un dé du motif de fond : centre, côté, rotation et face affichée.
class LudoDicePlacement {
  const LudoDicePlacement({
    required this.centre,
    required this.side,
    required this.angle,
    required this.value,
  });

  final Offset centre;
  final double side;
  final double angle;
  final int value;
}

const _q = 0.25;

/// Points de chaque face (1 à 6), en fractions du côté du dé.
const _pipLayouts = <List<Offset>>[
  [Offset.zero],
  [Offset(-_q, -_q), Offset(_q, _q)],
  [Offset(-_q, -_q), Offset.zero, Offset(_q, _q)],
  [Offset(-_q, -_q), Offset(_q, -_q), Offset(-_q, _q), Offset(_q, _q)],
  [
    Offset(-_q, -_q),
    Offset(_q, -_q),
    Offset.zero,
    Offset(-_q, _q),
    Offset(_q, _q),
  ],
  [
    Offset(-_q, -_q),
    Offset(_q, -_q),
    Offset(-_q, 0),
    Offset(_q, 0),
    Offset(-_q, _q),
    Offset(_q, _q),
  ],
];

/// Positions des points d'une face de dé.
List<Offset> ludoPipOffsets(int value) => _pipLayouts[value - 1];

/// Disposition des dés sur le fond. Graine fixe : même motif à chaque affichage.
List<LudoDicePlacement> ludoDicePlacements(
  double width,
  double height, {
  int seed = 7,
}) {
  const spacing = 84.0;
  final random = math.Random(seed);
  final placements = <LudoDicePlacement>[];
  final cols = (width / spacing).ceil() + 1;
  final rows = (height / spacing).ceil() + 1;
  for (var row = 0; row < rows; row++) {
    for (var col = 0; col < cols; col++) {
      // Une case sur cinq reste vide : le motif paraît moins régulier.
      if (random.nextDouble() < 0.2) continue;
      placements.add(
        LudoDicePlacement(
          centre: Offset(
            col * spacing + (random.nextDouble() - 0.5) * 30,
            row * spacing + (random.nextDouble() - 0.5) * 30,
          ),
          side: 26 + random.nextDouble() * 12,
          angle: (random.nextDouble() - 0.5) * 0.7,
          value: 1 + random.nextInt(6),
        ),
      );
    }
  }
  return placements;
}

/// Dessine les dés en contour translucide, sans remplissage.
class LudoDicePainter extends CustomPainter {
  const LudoDicePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = LudoBackdropPalette.diceStroke;
    final pip = Paint()..color = LudoBackdropPalette.pip;
    for (final dice in ludoDicePlacements(size.width, size.height)) {
      canvas
        ..save()
        ..translate(dice.centre.dx, dice.centre.dy)
        ..rotate(dice.angle);
      final side = dice.side;
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        Radius.circular(side * 0.22),
      );
      canvas.drawRRect(body, outline);
      for (final point in ludoPipOffsets(dice.value)) {
        canvas.drawCircle(
          Offset(point.dx * side, point.dy * side),
          side * 0.07,
          pip,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(LudoDicePainter oldDelegate) => false;
}

/// Fond du Ludo : dégradé bleu et motif de dés discrets (#690).
class LudoBackdrop extends StatelessWidget {
  const LudoBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LudoBackdropPalette.top,
            LudoBackdropPalette.middle,
            LudoBackdropPalette.bottom,
          ],
        ),
      ),
      child: const CustomPaint(
        painter: LudoDicePainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}
