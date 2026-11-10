// Portage de src/app/game/coinche.ts (guide §5.3).
// Dart pur : aucun import Flutter dans lib/game/.
// Mêmes fonctions, même ordre des opérations, mêmes valeurs de retour.
// Une action refusée renvoie l'instance reçue (identical), comme le source.
// Les tris passent par sortedStable : List.sort de Dart n'est pas stable, Array.sort de JS l'est.

import 'dart:math' as math;

import '../core/utils/js_compat.dart';
import 'common.dart';

enum Seat { south, west, north, east }

enum Team { ns, ew }

enum CoincheSuit { deniers, coupes, epees, batons }

enum CoinchePhase { bidding, playing, done, redeal }

enum CoincheRank {
  seven('7'),
  eight('8'),
  nine('9'),
  ten('10'),
  valet('V'),
  dame('D'),
  roi('R'),
  ace('A');

  const CoincheRank(this.label);

  /// Libellé du source TS : affichage, id de carte (« deniers-V ») et JSON.
  final String label;
}

CoincheRank rankFromLabel(String label) => CoincheRank.values.firstWhere((r) => r.label == label);

const Object _unset = Object();

const firstDealer = Seat.east;
const minBid = 80;
const maxBid = 160;
const handSize = 8;
const totalCardPoints = 162;
const capotPoints = 250;
const belotePoints = 20;
const dixDeDerPoints = 10;
const bidThreshold = 36;

const trumpOrder = [
  CoincheRank.seven,
  CoincheRank.eight,
  CoincheRank.dame,
  CoincheRank.roi,
  CoincheRank.ten,
  CoincheRank.ace,
  CoincheRank.nine,
  CoincheRank.valet,
];

const plainOrder = [
  CoincheRank.seven,
  CoincheRank.eight,
  CoincheRank.nine,
  CoincheRank.valet,
  CoincheRank.dame,
  CoincheRank.roi,
  CoincheRank.ten,
  CoincheRank.ace,
];

int _trumpValue(CoincheRank rank) => switch (rank) {
      CoincheRank.seven => 0,
      CoincheRank.eight => 0,
      CoincheRank.nine => 14,
      CoincheRank.ten => 10,
      CoincheRank.valet => 20,
      CoincheRank.dame => 3,
      CoincheRank.roi => 4,
      CoincheRank.ace => 11,
    };

int _plainValue(CoincheRank rank) => switch (rank) {
      CoincheRank.seven => 0,
      CoincheRank.eight => 0,
      CoincheRank.nine => 0,
      CoincheRank.ten => 10,
      CoincheRank.valet => 2,
      CoincheRank.dame => 3,
      CoincheRank.roi => 4,
      CoincheRank.ace => 11,
    };

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

class CoincheCard {
  const CoincheCard({required this.suit, required this.rank, required this.id});

  factory CoincheCard.fromJson(Map<String, dynamic> json) => CoincheCard(
        suit: CoincheSuit.values.byName(json['suit'] as String),
        rank: rankFromLabel(json['rank'] as String),
        id: json['id'] as String,
      );

  final CoincheSuit suit;
  final CoincheRank rank;
  final String id;

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank.label, 'id': id};

  @override
  bool operator ==(Object other) => other is CoincheCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Play {
  const Play({required this.seat, required this.card});

  factory Play.fromJson(Map<String, dynamic> json) => Play(
        seat: Seat.values.byName(json['seat'] as String),
        card: CoincheCard.fromJson(json['card'] as Map<String, dynamic>),
      );

  final Seat seat;
  final CoincheCard card;

  Map<String, dynamic> toJson() => {'seat': seat.name, 'card': card.toJson()};
}

class Contract {
  const Contract({
    required this.seat,
    required this.value,
    required this.mode,
    required this.multiplier,
  });

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        seat: Seat.values.byName(json['seat'] as String),
        value: json['value'] as int,
        mode: CoincheSuit.values.byName(json['mode'] as String),
        multiplier: json['multiplier'] as int,
      );

  final Seat seat;
  final int value;
  final CoincheSuit mode;

  /// 1 = normal, 2 = contré, 4 = surcoinché.
  final int multiplier;

  Contract withMultiplier(int multiplier) =>
      Contract(seat: seat, value: value, mode: mode, multiplier: multiplier);

  Map<String, dynamic> toJson() => {
        'seat': seat.name,
        'value': value,
        'mode': mode.name,
        'multiplier': multiplier,
      };
}

/// Action d'enchère : union discriminée du source (type "pass" | "bid" | "contre" | "surcoinche").
sealed class BidAction {
  const BidAction();

  factory BidAction.fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'pass' => const PassBid(),
        'bid' => ValueBid(json['value'] as int, CoincheSuit.values.byName(json['mode'] as String)),
        'contre' => const ContreBid(),
        'surcoinche' => const SurcoincheBid(),
        _ => throw FormatException('Enchère inconnue : ${json['type']}'),
      };

  Map<String, dynamic> toJson();
}

final class PassBid extends BidAction {
  const PassBid();

  @override
  Map<String, dynamic> toJson() => {'type': 'pass'};
}

final class ValueBid extends BidAction {
  const ValueBid(this.value, this.mode);

  final int value;
  final CoincheSuit mode;

  @override
  Map<String, dynamic> toJson() => {'type': 'bid', 'value': value, 'mode': mode.name};
}

final class ContreBid extends BidAction {
  const ContreBid();

  @override
  Map<String, dynamic> toJson() => {'type': 'contre'};
}

final class SurcoincheBid extends BidAction {
  const SurcoincheBid();

  @override
  Map<String, dynamic> toJson() => {'type': 'surcoinche'};
}

class RoundState {
  const RoundState({
    required this.dealer,
    required this.phase,
    required this.hands,
    required this.turn,
    required this.calls,
    required this.contract,
    required this.passes,
    required this.trick,
    required this.tricksPlayed,
    required this.tricksWon,
    required this.pointsWon,
    required this.lastWinner,
    required this.belote,
  });

  factory RoundState.fromJson(Map<String, dynamic> json) => RoundState(
        dealer: Seat.values.byName(json['dealer'] as String),
        phase: CoinchePhase.values.byName(json['phase'] as String),
        hands: {
          for (final e in (json['hands'] as Map<String, dynamic>).entries)
            Seat.values.byName(e.key): _cardsFromJson(e.value),
        },
        turn: _seatOrNull(json['turn']),
        calls: {
          for (final e in (json['calls'] as Map<String, dynamic>).entries)
            Seat.values.byName(e.key): BidAction.fromJson(e.value as Map<String, dynamic>),
        },
        contract: json['contract'] == null
            ? null
            : Contract.fromJson(json['contract'] as Map<String, dynamic>),
        passes: json['passes'] as int,
        trick: [for (final p in json['trick'] as List) Play.fromJson(p as Map<String, dynamic>)],
        tricksPlayed: json['tricksPlayed'] as int,
        tricksWon: _teamCountsFromJson(json['tricksWon']),
        pointsWon: _teamCountsFromJson(json['pointsWon']),
        lastWinner: _seatOrNull(json['lastWinner']),
        belote: _teamOrNull(json['belote']),
      );

  final Seat dealer;
  final CoinchePhase phase;
  final Map<Seat, List<CoincheCard>> hands;
  final Seat? turn;
  final Map<Seat, BidAction> calls;
  final Contract? contract;
  final int passes;
  final List<Play> trick;
  final int tricksPlayed;
  final Map<Team, int> tricksWon;
  final Map<Team, int> pointsWon;
  final Seat? lastWinner;
  final Team? belote;

  /// Les champs nullables (turn, contract, lastWinner, belote) se remettent à null
  /// avec une valeur explicite ; omis, ils gardent leur valeur.
  RoundState copyWith({
    CoinchePhase? phase,
    Map<Seat, List<CoincheCard>>? hands,
    Object? turn = _unset,
    Map<Seat, BidAction>? calls,
    Object? contract = _unset,
    int? passes,
    List<Play>? trick,
    int? tricksPlayed,
    Map<Team, int>? tricksWon,
    Map<Team, int>? pointsWon,
    Object? lastWinner = _unset,
    Object? belote = _unset,
  }) {
    return RoundState(
      dealer: dealer,
      phase: phase ?? this.phase,
      hands: hands ?? this.hands,
      turn: identical(turn, _unset) ? this.turn : turn as Seat?,
      calls: calls ?? this.calls,
      contract: identical(contract, _unset) ? this.contract : contract as Contract?,
      passes: passes ?? this.passes,
      trick: trick ?? this.trick,
      tricksPlayed: tricksPlayed ?? this.tricksPlayed,
      tricksWon: tricksWon ?? this.tricksWon,
      pointsWon: pointsWon ?? this.pointsWon,
      lastWinner: identical(lastWinner, _unset) ? this.lastWinner : lastWinner as Seat?,
      belote: identical(belote, _unset) ? this.belote : belote as Team?,
    );
  }

  Map<String, dynamic> toJson() => {
        'dealer': dealer.name,
        'phase': phase.name,
        'hands': {for (final e in hands.entries) e.key.name: [for (final c in e.value) c.toJson()]},
        'turn': turn?.name,
        'calls': {for (final e in calls.entries) e.key.name: e.value.toJson()},
        'contract': contract?.toJson(),
        'passes': passes,
        'trick': [for (final p in trick) p.toJson()],
        'tricksPlayed': tricksPlayed,
        'tricksWon': _teamCountsToJson(tricksWon),
        'pointsWon': _teamCountsToJson(pointsWon),
        'lastWinner': lastWinner?.name,
        'belote': belote?.name,
      };
}

class CoincheRoundResult {
  const CoincheRoundResult({
    required this.contract,
    required this.made,
    required this.capot,
    required this.points,
    required this.awarded,
  });

  factory CoincheRoundResult.fromJson(Map<String, dynamic> json) => CoincheRoundResult(
        contract: Contract.fromJson(json['contract'] as Map<String, dynamic>),
        made: json['made'] as bool,
        capot: json['capot'] as bool,
        points: _teamCountsFromJson(json['points']),
        awarded: _teamCountsFromJson(json['awarded']),
      );

  final Contract contract;
  final bool made;
  final bool capot;
  final Map<Team, int> points;
  final Map<Team, int> awarded;

  Map<String, dynamic> toJson() => {
        'contract': contract.toJson(),
        'made': made,
        'capot': capot,
        'points': _teamCountsToJson(points),
        'awarded': _teamCountsToJson(awarded),
      };
}

class CoincheMatch {
  const CoincheMatch({
    required this.target,
    required this.scores,
    required this.round,
    required this.winner,
  });

  factory CoincheMatch.fromJson(Map<String, dynamic> json) => CoincheMatch(
        target: json['target'] as int,
        scores: _teamCountsFromJson(json['scores']),
        round: json['round'] as int,
        winner: _teamOrNull(json['winner']),
      );

  final int target;
  final Map<Team, int> scores;
  final int round;
  final Team? winner;

  Map<String, dynamic> toJson() => {
        'target': target,
        'scores': _teamCountsToJson(scores),
        'round': round,
        'winner': winner?.name,
      };
}

// ---------------------------------------------------------------------------
// Helpers JSON
// ---------------------------------------------------------------------------

List<CoincheCard> _cardsFromJson(Object? raw) => [
      for (final c in raw as List) CoincheCard.fromJson(c as Map<String, dynamic>),
    ];

Seat? _seatOrNull(Object? raw) => raw == null ? null : Seat.values.byName(raw as String);

Team? _teamOrNull(Object? raw) => raw == null ? null : Team.values.byName(raw as String);

Map<String, dynamic> _teamCountsToJson(Map<Team, int> counts) => {
      for (final t in Team.values) t.name: counts[t],
    };

Map<Team, int> _teamCountsFromJson(Object? raw) {
  final json = raw as Map<String, dynamic>;
  return {for (final t in Team.values) t: json[t.name] as int};
}

// ---------------------------------------------------------------------------
// Règles de base
// ---------------------------------------------------------------------------

final _suits = CoincheSuit.values;
final _ranks = CoincheRank.values;

Seat nextSeat(Seat seat) => Seat.values[(seat.index + 1) % Seat.values.length];

Team teamOf(Seat seat) => seat == Seat.south || seat == Seat.north ? Team.ns : Team.ew;

Team _otherTeam(Team team) => team == Team.ns ? Team.ew : Team.ns;

bool isTrump(CoincheCard card, CoincheSuit mode) => card.suit == mode;

int _power(CoincheCard card, CoincheSuit mode) =>
    (isTrump(card, mode) ? trumpOrder : plainOrder).indexOf(card.rank);

int cardPoints(CoincheCard card, CoincheSuit mode) =>
    isTrump(card, mode) ? _trumpValue(card.rank) : _plainValue(card.rank);

List<CoincheCard> sortHand(List<CoincheCard> cards) => sortedStable(cards, (a, b) {
      final bySuit = a.suit.index - b.suit.index;
      return bySuit != 0 ? bySuit : plainOrder.indexOf(a.rank) - plainOrder.indexOf(b.rank);
    });

List<CoincheCard> _createDeck(RandomDouble random) {
  final deck = [
    for (final suit in _suits)
      for (final rank in _ranks) CoincheCard(suit: suit, rank: rank, id: '${suit.name}-${rank.label}'),
  ];
  for (var i = deck.length - 1; i > 0; i--) {
    final j = (random() * (i + 1)).floor();
    final tmp = deck[i];
    deck[i] = deck[j];
    deck[j] = tmp;
  }
  return deck;
}

final _defaultRandom = math.Random();

RoundState dealRound(Seat dealer, [RandomDouble? random]) {
  final deck = _createDeck(random ?? _defaultRandom.nextDouble);
  return RoundState(
    dealer: dealer,
    phase: CoinchePhase.bidding,
    hands: {
      Seat.south: deck.sublist(0, handSize),
      Seat.west: deck.sublist(handSize, handSize * 2),
      Seat.north: deck.sublist(handSize * 2, handSize * 3),
      Seat.east: deck.sublist(handSize * 3, handSize * 4),
    },
    turn: nextSeat(dealer),
    calls: {},
    contract: null,
    passes: 0,
    trick: const [],
    tricksPlayed: 0,
    tricksWon: {Team.ns: 0, Team.ew: 0},
    pointsWon: {Team.ns: 0, Team.ew: 0},
    lastWinner: null,
    belote: null,
  );
}

CoincheMatch newMatch([int target = 1000]) => CoincheMatch(
      target: target,
      scores: {Team.ns: 0, Team.ew: 0},
      round: 1,
      winner: null,
    );

int minBidValue(RoundState round) {
  final contract = round.contract;
  return contract == null ? minBid : contract.value + 10;
}

RoundState _startPlay(RoundState round) => round.copyWith(
      phase: CoinchePhase.playing,
      turn: nextSeat(round.dealer),
      passes: 0,
    );

RoundState placeBid(RoundState round, Seat seat, BidAction action) {
  if (round.phase != CoinchePhase.bidding || round.turn != seat) return round;
  final contract = round.contract;
  final calls = {...round.calls, seat: action};

  switch (action) {
    case PassBid():
      final passes = round.passes + 1;
      if (contract != null && passes >= 3) {
        return _startPlay(round.copyWith(calls: calls, passes: passes));
      }
      if (contract == null && passes >= 4) {
        return round.copyWith(calls: calls, phase: CoinchePhase.redeal, turn: null);
      }
      return round.copyWith(calls: calls, passes: passes, turn: nextSeat(seat));
    case ValueBid(:final value, :final mode):
      if (value < minBidValue(round) || value > maxBid || value % 10 != 0) return round;
      return round.copyWith(
        calls: calls,
        contract: Contract(seat: seat, value: value, mode: mode, multiplier: 1),
        passes: 0,
        turn: nextSeat(seat),
      );
    case ContreBid():
      if (contract == null || contract.multiplier != 1 || teamOf(contract.seat) == teamOf(seat)) {
        return round;
      }
      return round.copyWith(
        calls: calls,
        contract: contract.withMultiplier(2),
        passes: 0,
        turn: nextSeat(seat),
      );
    case SurcoincheBid():
      if (contract == null || contract.multiplier != 2 || teamOf(contract.seat) != teamOf(seat)) {
        return round;
      }
      return _startPlay(
        round.copyWith(calls: calls, contract: contract.withMultiplier(4), passes: 0),
      );
  }
}

bool beats(CoincheCard card, CoincheCard current, CoincheSuit ledSuit, CoincheSuit mode) {
  final cardTrump = isTrump(card, mode);
  if (cardTrump != isTrump(current, mode)) return cardTrump;
  if (cardTrump) return _power(card, mode) > _power(current, mode);
  return card.suit == ledSuit && _power(card, mode) > _power(current, mode);
}

Play winningPlay(List<Play> trick, CoincheSuit mode) {
  final ledSuit = trick.first.card.suit;
  var best = trick.first;
  for (final play in trick.skip(1)) {
    if (beats(play.card, best.card, ledSuit, mode)) best = play;
  }
  return best;
}

List<CoincheCard> legalCards(RoundState round, Seat seat) {
  final hand = round.hands[seat]!;
  final contract = round.contract;
  if (contract == null || round.trick.isEmpty) return hand;

  final mode = contract.mode;
  final ledCard = round.trick.first.card;
  final winner = winningPlay(round.trick, mode);
  final best = winner.card;
  List<CoincheCard> overtrump(List<CoincheCard> cards) {
    if (!isTrump(best, mode)) return cards;
    final higher = cards
        .where((c) => isTrump(c, mode) && _power(c, mode) > _power(best, mode))
        .toList();
    return higher.isNotEmpty ? higher : cards;
  }

  final sameSuit = hand.where((c) => c.suit == ledCard.suit).toList();
  if (sameSuit.isNotEmpty) return isTrump(ledCard, mode) ? overtrump(sameSuit) : sameSuit;
  if (teamOf(winner.seat) == teamOf(seat)) return hand;

  final trumps = hand.where((c) => isTrump(c, mode)).toList();
  return trumps.isNotEmpty ? overtrump(trumps) : hand;
}

RoundState playCard(RoundState round, Seat seat, String cardId) {
  final contract = round.contract;
  if (round.phase != CoinchePhase.playing || round.turn != seat || contract == null) return round;

  final hand = round.hands[seat]!;
  final index = hand.indexWhere((c) => c.id == cardId);
  if (index < 0) return round;
  final card = hand[index];
  if (!legalCards(round, seat).any((c) => c.id == cardId)) return round;

  final mode = contract.mode;
  final remaining = hand.where((c) => c.id != cardId).toList();
  final beloteCard =
      card.suit == mode && (card.rank == CoincheRank.roi || card.rank == CoincheRank.dame);
  final partnerRank = card.rank == CoincheRank.roi ? CoincheRank.dame : CoincheRank.roi;
  final holdsPair =
      beloteCard && remaining.any((c) => c.suit == card.suit && c.rank == partnerRank);
  final trick = [...round.trick, Play(seat: seat, card: card)];

  return round.copyWith(
    hands: {...round.hands, seat: remaining},
    trick: trick,
    turn: trick.length == 4 ? null : nextSeat(seat),
    belote: holdsPair && round.belote == null ? teamOf(seat) : round.belote,
  );
}

RoundState collectTrick(RoundState round) {
  final contract = round.contract;
  if (round.phase != CoinchePhase.playing || round.trick.length != 4 || contract == null) {
    return round;
  }

  final mode = contract.mode;
  final winner = winningPlay(round.trick, mode);
  final team = teamOf(winner.seat);
  final points = round.trick.fold<int>(0, (sum, play) => sum + cardPoints(play.card, mode));
  final tricksPlayed = round.tricksPlayed + 1;
  final done = tricksPlayed == handSize;

  return round.copyWith(
    phase: done ? CoinchePhase.done : CoinchePhase.playing,
    trick: const <Play>[],
    tricksPlayed: tricksPlayed,
    turn: done ? null : winner.seat,
    tricksWon: {...round.tricksWon, team: round.tricksWon[team]! + 1},
    pointsWon: {...round.pointsWon, team: round.pointsWon[team]! + points},
    lastWinner: winner.seat,
  );
}

CoincheRoundResult? scoreRound(RoundState round) {
  final contract = round.contract;
  if (round.phase != CoinchePhase.done || contract == null) return null;

  final attack = teamOf(contract.seat);
  final defense = _otherTeam(attack);
  int beloteOf(Team team) => round.belote == team ? belotePoints : 0;
  final capot = round.tricksWon[attack] == handSize;

  final points = <Team, int>{Team.ns: round.pointsWon[Team.ns]!, Team.ew: round.pointsWon[Team.ew]!};
  final last = round.lastWinner;
  if (last != null) {
    points[teamOf(last)] = points[teamOf(last)]! + dixDeDerPoints;
  }
  if (capot) {
    points[attack] = capotPoints;
    points[defense] = 0;
  }
  points[Team.ns] = points[Team.ns]! + beloteOf(Team.ns);
  points[Team.ew] = points[Team.ew]! + beloteOf(Team.ew);

  final bonus = contract.value * contract.multiplier;
  final made = points[attack]! >= contract.value;
  final awarded = <Team, int>{Team.ns: 0, Team.ew: 0};
  if (made) {
    awarded[attack] = points[attack]! + bonus;
    awarded[defense] = points[defense]!;
  } else {
    awarded[defense] = totalCardPoints + beloteOf(defense) + bonus;
  }

  return CoincheRoundResult(
    contract: contract,
    made: made,
    capot: capot,
    points: points,
    awarded: awarded,
  );
}

CoincheMatch applyRound(CoincheMatch match, CoincheRoundResult result) {
  final ns = match.scores[Team.ns]! + result.awarded[Team.ns]!;
  final ew = match.scores[Team.ew]! + result.awarded[Team.ew]!;
  final Team? leader = ns == ew ? null : (ns > ew ? Team.ns : Team.ew);
  final reached = math.max(ns, ew) >= match.target;
  return CoincheMatch(
    target: match.target,
    scores: {Team.ns: ns, Team.ew: ew},
    round: match.round + 1,
    winner: reached ? leader : null,
  );
}

// ---------------------------------------------------------------------------
// IA (même logique que le source ; seul le jeu de carte change avec la difficulté)
// ---------------------------------------------------------------------------

BidAction chooseBid(RoundState round, Seat seat) {
  final contract = round.contract;
  if (contract != null && teamOf(contract.seat) == teamOf(seat)) return const PassBid();

  final hand = round.hands[seat]!;
  CoincheSuit? bestSuit;
  var bestStrength = 0;
  for (final suit in _suits) {
    final strength = hand
        .where((c) => c.suit == suit)
        .fold<int>(0, (sum, c) => sum + _trumpValue(c.rank));
    if (strength > bestStrength) {
      bestStrength = strength;
      bestSuit = suit;
    }
  }
  if (bestSuit == null || bestStrength < bidThreshold) return const PassBid();

  final minValue = minBidValue(round);
  final value = math.min(
    maxBid,
    math.max(minValue, minBid + ((bestStrength - bidThreshold) / 8).floor() * 10),
  );
  if (value < minValue || value > maxBid) return const PassBid();
  return ValueBid(value, bestSuit);
}

/// Renvoie l'id de la carte choisie. `randomPlay` = jeu aléatoire (difficulté facile).
String chooseCard(RoundState round, Seat seat, [bool randomPlay = false, RandomDouble? random]) {
  final moves = legalCards(round, seat);
  final contract = round.contract;
  if (randomPlay || contract == null) {
    final draw = random ?? _defaultRandom.nextDouble;
    return moves[(draw() * moves.length).floor()].id;
  }

  final mode = contract.mode;
  int compare(CoincheCard a, CoincheCard b) {
    final byPoints = cardPoints(a, mode) - cardPoints(b, mode);
    return byPoints != 0 ? byPoints : _power(a, mode) - _power(b, mode);
  }

  CoincheCard cheapest(List<CoincheCard> cards) => sortedStable(cards, compare).first;
  CoincheCard priciest(List<CoincheCard> cards) => sortedStable(cards, compare).last;

  if (round.trick.isEmpty) {
    final plain = moves.where((c) => !isTrump(c, mode)).toList();
    if (plain.isNotEmpty) {
      final top = priciest(plain);
      if (cardPoints(top, mode) >= 10) return top.id;
    }
    return cheapest(moves).id;
  }

  final winner = winningPlay(round.trick, mode);
  if (teamOf(winner.seat) == teamOf(seat)) return cheapest(moves).id;

  final ledSuit = round.trick.first.card.suit;
  final winners = moves.where((c) => beats(c, winner.card, ledSuit, mode)).toList();
  return (winners.isNotEmpty ? cheapest(winners) : cheapest(moves)).id;
}
