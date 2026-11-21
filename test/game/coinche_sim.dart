// Simulation de parties Coinche pour mesurer les niveaux IA (issue #720).
// Partagé par le garde-fou rapide (test/game/coinche_levels_smoke_test.dart, en CI)
// et la calibration nocturne (calibration/coinche_win_rate_test.dart).
// Aucune règle n'est dupliquée : enchères, cartes et score passent par placeBid,
// playCard, collectTrick, scoreRound et applyRound de lib/game/coinche.dart.
import 'package:kahwetne/game/coinche.dart';
import 'package:kahwetne/game/common.dart';

const int coincheSimTargetScore = 1000;

/// Générateur pseudo-aléatoire à graine fixe (congruentiel linéaire).
RandomDouble _seeded(int seed) {
  var s = seed;
  return () {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    return s / 0x80000000;
  };
}

/// Niveau joué par [seat] : celui testé pour l'équipe [levelTeam], moyen pour l'autre.
CoincheAiLevel _levelOf(Seat seat, Team levelTeam, CoincheAiLevel level) =>
    teamOf(seat) == levelTeam ? level : CoincheAiLevel.moyen;

/// Enchères jusqu'au contrat, ou jusqu'au redeal si personne n'annonce.
RoundState _bid(RoundState round, Team levelTeam, CoincheAiLevel level) {
  var current = round;
  var steps = 0;
  while (current.phase == CoinchePhase.bidding) {
    if (++steps > 200) throw StateError('enchères sans fin');
    final seat = current.turn!;
    final action = chooseBid(current, seat, _levelOf(seat, levelTeam, level));
    var next = placeBid(current, seat, action);
    // Enchère refusée par les règles (surenchère trop basse) : on passe.
    if (identical(next, current)) {
      next = placeBid(current, seat, const PassBid());
    }
    current = next;
  }
  return current;
}

/// Plis jusqu'à la fin de la donne (phase done).
RoundState _play(
  RoundState round,
  Team levelTeam,
  CoincheAiLevel level,
  RandomDouble rnd,
) {
  var current = round;
  var steps = 0;
  while (current.phase == CoinchePhase.playing) {
    if (++steps > 1000) throw StateError('plis sans fin');
    if (current.trick.length == 4) {
      current = collectTrick(current);
      continue;
    }
    final seat = current.turn!;
    final seatLevel = _levelOf(seat, levelTeam, level);
    final id = chooseCard(
      current,
      seat,
      seatLevel == CoincheAiLevel.facile,
      rnd,
      seatLevel,
    );
    final next = playCard(current, seat, id);
    if (identical(next, current)) throw StateError('carte refusée : $id');
    current = next;
  }
  return current;
}

/// Joue une donne à partir de [dealt] : enchères puis plis.
/// Retourne la donne terminée (phase done), ou la donne en redeal.
RoundState simPlayRound(
  RoundState dealt,
  Team levelTeam,
  CoincheAiLevel level,
  RandomDouble rnd,
) {
  final bid = _bid(dealt, levelTeam, level);
  if (bid.phase != CoinchePhase.playing) return bid;
  return _play(bid, levelTeam, level, rnd);
}

/// Joue une partie complète jusqu'à [target]. L'équipe [levelTeam] joue au niveau [level],
/// l'autre équipe au niveau moyen. Retourne l'équipe gagnante.
Team playCoincheMatch(
  CoincheAiLevel level,
  Team levelTeam,
  int seed, {
  int target = coincheSimTargetScore,
}) {
  final rnd = _seeded(seed);
  var match = newMatch(target);
  var dealer = Seat.south;
  var donnes = 0;
  while (match.winner == null) {
    if (++donnes > 10000) {
      throw StateError('partie non terminée (graine $seed)');
    }
    final dealt = dealRound(dealer, rnd);
    final round = simPlayRound(dealt, levelTeam, level, rnd);
    dealer = nextSeat(dealer);
    if (round.phase == CoinchePhase.redeal) continue;
    match = applyRound(match, scoreRound(round)!);
  }
  return match.winner!;
}

/// Taux de victoire de [level] contre le niveau moyen, équipes alternées une partie sur deux.
double coincheWinRate(CoincheAiLevel level, {required int games}) {
  var wins = 0;
  for (var i = 0; i < games; i++) {
    final levelTeam = i.isEven ? Team.ns : Team.ew;
    if (playCoincheMatch(level, levelTeam, i + 1) == levelTeam) wins++;
  }
  return wins / games;
}
