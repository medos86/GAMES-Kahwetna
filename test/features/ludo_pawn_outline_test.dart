import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

void main() {
  test('pion jouable : liseré or, jamais blanc pur', () {
    final c = ludoPawnOutlineColor(clickable: true);
    expect(c, ludoPawnRim);
    expect(c, isNot(const Color(0xFFFFFFFF)));
  });

  test('pion non jouable : contour brun inchangé', () {
    expect(ludoPawnOutlineColor(clickable: false), const Color(0xFF4A2A10));
  });
}
