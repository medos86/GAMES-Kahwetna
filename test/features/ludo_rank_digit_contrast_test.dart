import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';

/// Issue #295 : contraste >= 4,5 du chiffre de classement sur chaque pastille Ludo.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Couleurs de pastille des quatre joueurs (_toneOf dans ludo_screen.dart).
  const fills = <String, Color>{
    'Rouge': Color(0xFFE43F5F),
    'Vert': Color(0xFF49C9A7),
    'Jaune': Color(0xFFFFD653),
    'Bleu': Color(0xFF1676D2),
  };

  for (final entry in fills.entries) {
    test('chiffre de classement lisible sur ${entry.key} (>= 4,5)', () {
      final digit = ludoRankDigitColor(entry.value);
      expect(_contrast(digit, entry.value), greaterThanOrEqualTo(4.5));
    });
  }
}
