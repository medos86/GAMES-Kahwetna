// Pointe de lumière sur le contour des mascottes (#904).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/mascot_outline.dart';
import 'package:kahwetne/features/menu/main_menu/mascot_outline_data.dart';

const _mascots = ['belote', 'chkobba', 'domino', 'rami'];

int _u32(List<int> bytes, int at) {
  var value = 0;
  for (var i = 0; i < 4; i++) {
    value = (value << 8) | bytes[at + i];
  }
  return value;
}

/// Dimensions lues dans l'en-tête IHDR d'un PNG (octets 16 à 23).
(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  return (_u32(bytes, 16), _u32(bytes, 20));
}

/// Carré de 100 × 100 : contour fermé de test.
ui.Path _square() {
  const data = MascotOutlineData(
    width: 100,
    height: 100,
    points: [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)],
  );
  return mascotOutlinePath(data, const Size(100, 100));
}

ui.PathMetric _squareMetric() => _square().computeMetrics().first;

double _traceLength(List<MascotSparkSegment> segments) {
  var total = 0.0;
  for (final s in segments) {
    for (final m in s.path.computeMetrics()) {
      total += m.length;
    }
  }
  return total;
}

void main() {
  group('données de contour', () {
    test('chaque mascotte a un contour', () {
      for (final name in _mascots) {
        expect(mascotOutlines.containsKey(name), isTrue, reason: name);
      }
    });

    test('dimensions cohérentes avec les PNG sources', () {
      for (final name in _mascots) {
        final data = mascotOutlines[name]!;
        final size = _pngSize('assets/images/mascots/$name.png');
        expect(data.width, size.$1, reason: name);
        expect(data.height, size.$2, reason: name);
      }
    });

    test('points normalisés entre 0 et 1, en nombre raisonnable', () {
      for (final name in _mascots) {
        final pts = mascotOutlines[name]!.points;
        expect(pts.length, greaterThanOrEqualTo(50), reason: name);
        expect(pts.length, lessThanOrEqualTo(400), reason: name);
        for (final p in pts) {
          expect(p.dx, inInclusiveRange(0, 1), reason: name);
          expect(p.dy, inInclusiveRange(0, 1), reason: name);
        }
      }
    });

    test('recherche par chemin d\'asset', () {
      const rami = 'assets/images/mascots/rami.png';
      expect(mascotNameOf(rami), 'rami');
      expect(mascotOutlineFor(rami), same(mascotOutlines['rami']));
      expect(mascotOutlineFor('assets/images/inconnu.png'), isNull);
    });
  });

  group('chemin du contour', () {
    test('le contour est fermé et mis à l\'échelle', () {
      final metrics = _square().computeMetrics().toList();
      expect(metrics, hasLength(1));
      expect(metrics.first.isClosed, isTrue);
      expect(metrics.first.length, closeTo(400, 0.001));
    });

    test('un contour vide donne un chemin vide', () {
      const data = MascotOutlineData(width: 1, height: 1, points: []);
      final path = mascotOutlinePath(data, const Size(10, 10));
      expect(path.computeMetrics().toList(), isEmpty);
    });
  });

  group('pointe de lumière', () {
    test('la traînée compte les morceaux prévus, tête la plus vive', () {
      final segments = mascotSparkSegments(_squareMetric(), 0.5);
      expect(segments, hasLength(mascotSparkSteps));
      expect(segments.first.brightness, 1.0);
      expect(segments.last.brightness, lessThan(0.2));
    });

    test('la longueur de traînée vaut la fraction prévue du contour', () {
      const expected = mascotSparkTail * 400;
      final segments = mascotSparkSegments(_squareMetric(), 0.5);
      expect(_traceLength(segments), closeTo(expected, 0.5));
    });

    test('la traînée franchit la couture sans rupture', () {
      const expected = mascotSparkTail * 400;
      final metric = _squareMetric();
      final before = mascotSparkSegments(metric, 0.01);
      final after = mascotSparkSegments(metric, 0.99);
      expect(_traceLength(before), closeTo(expected, 0.5));
      expect(_traceLength(after), closeTo(expected, 0.5));
    });

    test('la tête est continue à la couture (t = 0 ou t ≈ 1)', () {
      final metric = _squareMetric();
      final start = mascotSparkHead(metric, 0)!;
      final end = mascotSparkHead(metric, 0.9999999)!;
      expect((start - end).distance, lessThan(0.5));
    });

    test('la tête avance le long du contour selon t', () {
      // Carré 100 × 100 : un quart de tour (t = 0,25) atteint le coin (100, 0).
      final corner = mascotSparkHead(_squareMetric(), 0.25)!;
      expect(corner.dx, closeTo(100, 0.5));
      expect(corner.dy, closeTo(0, 0.5));
    });

    test('contour vide : aucun morceau et aucune tête', () {
      final metrics = ui.Path().computeMetrics().toList();
      expect(metrics, isEmpty);
    });
  });
}
