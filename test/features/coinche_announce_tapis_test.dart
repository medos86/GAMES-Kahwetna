// Belote : pseudo du joueur, détail de l'annonce et main dans le tapis (issues #838, #839).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_contract_label.dart';
import 'package:kahwetne/features/coinche/coinche_opponent_names.dart';
import 'package:kahwetne/game/coinche.dart';

void main() {
  const names = {Seat.north: 'Nour', Seat.west: 'Hedi', Seat.east: 'Ines'};

  test('le sud prend le pseudo du joueur, « Toi » par défaut', () {
    expect(coincheSeatName(names, Seat.south, 'Amine'), 'Amine');
    expect(coincheSeatName(names, Seat.south), 'Toi');
  });

  test('détail de l\'annonce : atout, contre et annonceur', () {
    const contract = Contract(
      seat: Seat.north,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 2,
    );
    final detail = coincheAnnounceDetail(contract, names, 'Amine');
    expect(detail, startsWith('Atout '));
    expect(detail, contains('contré'));
    expect(detail, isNot(contains('surcontré')));
    expect(detail, endsWith('annoncé par Nour'));
  });

  test('détail de l\'annonce : surcontré, annonceur joueur', () {
    const contract = Contract(
      seat: Seat.south,
      value: 100,
      mode: CoincheSuit.epees,
      multiplier: 4,
    );
    final detail = coincheAnnounceDetail(contract, names, 'Amine');
    expect(detail, contains('surcontré'));
    expect(detail, endsWith('annoncé par Amine'));
  });

  test('détail de l\'annonce : annonce simple sans contre', () {
    const contract = Contract(
      seat: Seat.east,
      value: 90,
      mode: CoincheSuit.batons,
      multiplier: 1,
    );
    final detail = coincheAnnounceDetail(contract, names, 'Amine');
    expect(detail, isNot(contains('contré')));
    expect(detail, endsWith('annoncé par Ines'));
  });
}
