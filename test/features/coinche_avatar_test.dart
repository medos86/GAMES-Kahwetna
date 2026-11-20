import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_avatars.dart';
import 'package:kahwetne/game/coinche.dart';

/// Issue #554 : gagnant de la manche, puis avatars selon le résultat.
RoundState _round({
  required CoinchePhase phase,
  required Seat contractSeat,
  required Map<Team, int> tricksWon,
}) {
  return RoundState(
    dealer: Seat.east,
    phase: phase,
    hands: {for (final s in Seat.values) s: <CoincheCard>[]},
    turn: Seat.south,
    calls: const {},
    contract: Contract(
      seat: contractSeat,
      value: 80,
      mode: CoincheSuit.deniers,
      multiplier: 1,
    ),
    passes: 0,
    trick: const [],
    tricksPlayed: handSize,
    tricksWon: tricksWon,
    pointsWon: {Team.ns: 0, Team.ew: 0},
    lastWinner: contractSeat,
    belote: null,
  );
}

void main() {
  test('manche en cours : aucun gagnant', () {
    final round = _round(
      phase: CoinchePhase.playing,
      contractSeat: Seat.south,
      tricksWon: {Team.ns: 0, Team.ew: 0},
    );
    expect(coincheWinnerSeats(round), isEmpty);
  });

  test('contrat réussi : les deux sièges de l\'attaque gagnent', () {
    final round = _round(
      phase: CoinchePhase.done,
      contractSeat: Seat.south,
      tricksWon: {Team.ns: handSize, Team.ew: 0},
    );
    expect(coincheWinnerSeats(round), [Seat.south.index, Seat.north.index]);
  });

  test('contrat chuté : la défense gagne', () {
    final round = _round(
      phase: CoinchePhase.done,
      contractSeat: Seat.south,
      tricksWon: {Team.ns: 0, Team.ew: handSize},
    );
    expect(coincheWinnerSeats(round), [Seat.west.index, Seat.east.index]);
  });
}
