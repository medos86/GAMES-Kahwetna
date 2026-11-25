// Pointe de lumière qui parcourt le contour d'une mascotte, en boucle continue (#904).
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'mascot_outline_data.dart';

/// Durée d'un tour complet de la pointe.
const mascotSparkPeriod = Duration(milliseconds: 5000);

/// Longueur de la traînée, en fraction du contour.
const mascotSparkTail = 0.16;

/// Nombre de morceaux qui composent la traînée (estompage par paliers).
const mascotSparkSteps = 10;

/// Nom court d'une mascotte, d'après son chemin d'asset (rami.png -> rami).
String mascotNameOf(String assetPath) =>
    assetPath.split('/').last.split('.').first;

/// Contour de la mascotte désignée par [assetPath], ou null si inconnu.
MascotOutlineData? mascotOutlineFor(String assetPath) =>
    mascotOutlines[mascotNameOf(assetPath)];

/// Contour fermé de [data], mis à l'échelle de [size].
ui.Path mascotOutlinePath(MascotOutlineData data, Size size) {
  final path = ui.Path();
  final pts = data.points;
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
  for (final p in pts.skip(1)) {
    path.lineTo(p.dx * size.width, p.dy * size.height);
  }
  path.close();
  return path;
}

/// Un morceau de la pointe, avec sa luminosité (1 = tête, 0 = fin de traînée).
class MascotSparkSegment {
  const MascotSparkSegment(this.path, this.brightness);

  final ui.Path path;
  final double brightness;
}

/// Ramène [t] dans l'intervalle [0, 1).
double _wrapFraction(double t) => ((t % 1.0) + 1.0) % 1.0;

/// Ramène une distance dans l'intervalle [0, total).
double _wrapDistance(double d, double total) => ((d % total) + total) % total;

/// Position de la tête, à la fraction [t] du contour, ou null si le contour est vide.
ui.Offset? mascotSparkHead(ui.PathMetric metric, double t) {
  final total = metric.length;
  if (total <= 0) return null;
  return metric.getTangentForOffset(_wrapFraction(t) * total)?.position;
}

/// Morceaux de la pointe pour une tête à la fraction [t] du contour.
/// La traînée remonte le contour ; elle franchit la couture sans rupture.
List<MascotSparkSegment> mascotSparkSegments(ui.PathMetric metric, double t) {
  final total = metric.length;
  if (total <= 0) return const [];
  final head = _wrapFraction(t) * total;
  final tail = mascotSparkTail * total;
  final segments = <MascotSparkSegment>[];
  for (var i = 0; i < mascotSparkSteps; i++) {
    final from = head - tail * (i + 1) / mascotSparkSteps;
    final to = head - tail * i / mascotSparkSteps;
    segments.add(
      MascotSparkSegment(
        _extractWrapped(metric, from, to),
        1 - i / mascotSparkSteps,
      ),
    );
  }
  return segments;
}

/// Extrait le contour entre les distances [from] et [to] (to après from), en
/// enroulant autour de la boucle fermée.
ui.Path _extractWrapped(ui.PathMetric metric, double from, double to) {
  final total = metric.length;
  final a = _wrapDistance(from, total);
  final b = _wrapDistance(to, total);
  final out = ui.Path();
  if (b >= a) {
    out.addPath(metric.extractPath(a, b), Offset.zero);
  } else {
    out.addPath(metric.extractPath(a, total), Offset.zero);
    out.addPath(metric.extractPath(0, b), Offset.zero);
  }
  return out;
}

/// Dessine la pointe sur le contour de [outline], pilotée par [animation].
class MascotSparkPainter extends CustomPainter {
  MascotSparkPainter({required this.outline, required this.animation})
      : super(repaint: animation);

  final MascotOutlineData outline;
  final Animation<double> animation;

  static const _color = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final path = mascotOutlinePath(outline, size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final t = animation.value;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final s in mascotSparkSegments(metric, t)) {
      stroke.color = _color.withValues(alpha: 0.7 * s.brightness);
      canvas.drawPath(s.path, stroke);
    }

    final head = mascotSparkHead(metric, t);
    if (head != null) {
      final glow = Paint()
        ..color = _color.withValues(alpha: 0.9)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);
      canvas.drawCircle(head, 2.2, glow);
    }
  }

  @override
  bool shouldRepaint(covariant MascotSparkPainter oldDelegate) =>
      oldDelegate.outline != outline || oldDelegate.animation != animation;
}
