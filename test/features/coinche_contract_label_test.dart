import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_contract_label.dart';
import 'package:kahwetne/game/coinche.dart';

/// Issue #780 : l'annonce affiche le joueur qui l'a faite.
void main() {
  const names = {
    Seat.north: 'Karim',
    Seat.west: 'Sami',
    Seat.east: 'Leila',
  };

  test('aucune annonce : libellé neutre', () {
    expect(coincheContractLabel(null, names), 'Aucune annonce');
  });

  test('annonce d\'un adversaire : son prénom est affiché', () {
    const contract = Contract(
      seat: Seat.west,
      value: 90,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );
    final label = coincheContractLabel(contract, names);
    expect(label, contains('90'));
    expect(label, endsWith('· Sami'));
  });

  test('annonce du joueur : affiche « Toi »', () {
    const contract = Contract(
      seat: Seat.south,
      value: 80,
      mode: CoincheSuit.epees,
      multiplier: 1,
    );
    expect(coincheContractLabel(contract, names), endsWith('· Toi'));
  });
}
