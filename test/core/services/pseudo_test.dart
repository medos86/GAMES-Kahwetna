import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/pseudo.dart';

/// Issue #543 : génération et validation du pseudo.
void main() {
  test('1000 pseudos générés sont tous valides', () {
    final random = Random(42);
    for (var i = 0; i < 1000; i++) {
      final pseudo = generatePseudo(random);
      expect(validatePseudo(pseudo), isNull, reason: pseudo);
      expect(pseudo.length, lessThanOrEqualTo(pseudoMaxLength));
    }
  });

  test('un pseudo trop court est refusé', () {
    expect(validatePseudo('ab'), PseudoError.tooShort);
  });

  test('un pseudo trop long est refusé', () {
    expect(validatePseudo('a' * 15), PseudoError.tooLong);
  });

  test('un emoji ou un caractère spécial est refusé', () {
    expect(validatePseudo('Lion😀'), PseudoError.invalidCharacters);
    expect(validatePseudo('Lion!!'), PseudoError.invalidCharacters);
  });

  test('un mot interdit est refusé, même avec casse ou séparateurs', () {
    expect(validatePseudo('AdMin'), PseudoError.forbiddenWord);
    expect(validatePseudo('x_ro_ot'), PseudoError.forbiddenWord);
  });

  test('les espaces autour sont retirés avant la validation', () {
    expect(validatePseudo('  Sfaxi  '), isNull);
  });

  test('lettres arabes et accents acceptés', () {
    expect(validatePseudo('محمد'), isNull);
    expect(validatePseudo('Élodie'), isNull);
  });
}
