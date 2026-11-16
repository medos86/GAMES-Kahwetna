import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_round_summary.dart';

/// Issue #298 : fin de manche lisible — valeurs signées et motif par joueur.
void main() {
  test('gagnant : -10 affiché avec son signe', () {
    expect(ramiPenaltyText(-10), '-10');
  });

  test('perdant sans paquet : +100', () {
    expect(ramiPenaltyText(100), '+100');
  });

  test('zéro reste zéro', () {
    expect(ramiPenaltyText(0), '0');
  });

  test('motif : gagnant, pas ouvert, cartes en main', () {
    expect(ramiSeatReason(isWinner: true, opened: true), 'Gagnant');
    expect(ramiSeatReason(isWinner: false, opened: false), 'Pas ouvert');
    expect(ramiSeatReason(isWinner: false, opened: true), 'Cartes en main');
  });
}
