// Pions : plus de liseré or ; le pion jouable se signale par son rebond (#779).
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

void main() {
  test('contour de tous les pions : brun cartoon, sans liseré or', () {
    expect(ludoPawnOutline, const Color(0xFF4A2A10));
  });

  test('pion jouable : rebond qui part de sa place et y revient', () {
    expect(ludoBobAt(0), 0);
    expect(ludoBobAt(0.5), closeTo(-ludoBobHeight, 1e-9));
    expect(ludoBobAt(1), closeTo(0, 1e-9));
  });
}
