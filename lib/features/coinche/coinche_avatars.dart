import '../../game/coinche.dart';

/// Sièges de l'équipe gagnante de la manche (issue #554). Vide tant que la
/// manche n'est pas finie ou si personne n'a enchéri.
List<int> coincheWinnerSeats(RoundState round) {
  if (round.phase != CoinchePhase.done) return const [];
  final result = scoreRound(round);
  if (result == null) return const [];
  final attack = teamOf(result.contract.seat);
  final winner = result.made ? attack : (attack == Team.ns ? Team.ew : Team.ns);
  final winners = <int>[];
  for (final seat in Seat.values) {
    if (teamOf(seat) == winner) winners.add(seat.index);
  }
  return winners;
}
