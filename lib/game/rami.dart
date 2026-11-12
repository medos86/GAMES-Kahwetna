// Portage de src/app/game/rami.ts (guide §5.5).
// Dart pur : aucun import Flutter dans lib/game/.
// Mêmes fonctions, même ordre des opérations, mêmes valeurs de retour.
// Une action refusée renvoie l'instance reçue (identical) : le contrôleur s'en sert pour le toast d'erreur.
// Les tris passent par sortedStable : List.sort de Dart n'est pas stable, Array.sort de JS l'est.

import 'dart:math' as math;

import '../core/utils/js_compat.dart';
import 'common.dart';

/// Couleurs ; un joker a suit == null.
enum RamiSuit { deniers, coupes, epees, batons }

enum RamiPhase { draw, play, end }

/// Niveau de l'IA (mêmes valeurs que Difficulty côté interface).
enum RamiAiLevel { facile, moyen, difficile }

const ramiSeats = [0, 1, 2, 3];
const ramiOpenMin = 51;
const _handSize = 13;
const _aceHigh = 14;

/// rank : 1 = As, 11 = Valet, 12 = Dame, 13 = Roi. Le joker a rank 0.
class RamiCard {
  const RamiCard({required this.id, required this.suit, required this.rank});

  factory RamiCard.fromJson(Map<String, dynamic> json) => RamiCard(
        id: json['id'] as String,
        suit: json['suit'] == null
            ? null
            : RamiSuit.values.byName(json['suit'] as String),
        rank: json['rank'] as int,
      );

  final String id;
  final RamiSuit? suit;
  final int rank;

  bool get isJoker => suit == null;

  Map<String, dynamic> toJson() => {'id': id, 'suit': suit?.name, 'rank': rank};

  @override
  bool operator ==(Object other) => other is RamiCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Combinaison posée sur la table ; id = id de sa première carte.
class Meld {
  const Meld({required this.id, required this.cards});

  factory Meld.fromJson(Map<String, dynamic> json) =>
      Meld(id: json['id'] as String, cards: _cardsFromJson(json['cards']));

  final String id;
  final List<RamiCard> cards;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cards': [for (final c in cards) c.toJson()],
      };
}

class RamiRoundResult {
  const RamiRoundResult({required this.winner, required this.penalties});

  factory RamiRoundResult.fromJson(Map<String, dynamic> json) =>
      RamiRoundResult(
        winner: json['winner'] as int?,
        penalties: [for (final p in json['penalties'] as List) p as int],
      );

  /// null = manche sans gagnant (pioche et défausse épuisées).
  final int? winner;
  final List<int> penalties;

  Map<String, dynamic> toJson() => {'winner': winner, 'penalties': penalties};
}

const Object _unset = Object();

class RamiState {
  const RamiState({
    required this.targetScore,
    required this.round,
    required this.dealer,
    required this.turn,
    required this.phase,
    required this.stock,
    required this.discard,
    required this.hands,
    required this.table,
    required this.opened,
    required this.staged,
    required this.takenId,
    required this.scores,
    required this.roundResult,
    required this.matchWinner,
  });

  factory RamiState.fromJson(Map<String, dynamic> json) => RamiState(
        targetScore: json['targetScore'] as int,
        round: json['round'] as int,
        dealer: json['dealer'] as int,
        turn: json['turn'] as int,
        phase: RamiPhase.values.byName(json['phase'] as String),
        stock: _cardsFromJson(json['stock']),
        discard: _cardsFromJson(json['discard']),
        hands: [for (final h in json['hands'] as List) _cardsFromJson(h)],
        table: [
          for (final m in json['table'] as List)
            Meld.fromJson(m as Map<String, dynamic>),
        ],
        opened: [for (final o in json['opened'] as List) o as bool],
        staged: [for (final s in json['staged'] as List) _cardsFromJson(s)],
        takenId: json['takenId'] as String?,
        scores: [for (final s in json['scores'] as List) s as int],
        roundResult: json['roundResult'] == null
            ? null
            : RamiRoundResult.fromJson(
                json['roundResult'] as Map<String, dynamic>),
        matchWinner: json['matchWinner'] as int?,
      );

  final int targetScore;
  final int round;
  final int dealer;
  final int turn;
  final RamiPhase phase;
  final List<RamiCard> stock;
  final List<RamiCard> discard;
  final List<List<RamiCard>> hands;
  final List<Meld> table;
  final List<bool> opened;
  final List<List<RamiCard>> staged;
  final String? takenId;
  final List<int> scores;
  final RamiRoundResult? roundResult;
  final int? matchWinner;

  /// Les champs nullables (takenId, roundResult, matchWinner) se remettent à null avec une valeur explicite.
  RamiState copyWith({
    RamiPhase? phase,
    List<RamiCard>? stock,
    List<RamiCard>? discard,
    List<List<RamiCard>>? hands,
    List<Meld>? table,
    List<bool>? opened,
    List<List<RamiCard>>? staged,
    Object? takenId = _unset,
    int? turn,
    List<int>? scores,
    Object? roundResult = _unset,
    Object? matchWinner = _unset,
  }) {
    return RamiState(
      targetScore: targetScore,
      round: round,
      dealer: dealer,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      stock: stock ?? this.stock,
      discard: discard ?? this.discard,
      hands: hands ?? this.hands,
      table: table ?? this.table,
      opened: opened ?? this.opened,
      staged: staged ?? this.staged,
      takenId: identical(takenId, _unset) ? this.takenId : takenId as String?,
      scores: scores ?? this.scores,
      roundResult: identical(roundResult, _unset)
          ? this.roundResult
          : roundResult as RamiRoundResult?,
      matchWinner: identical(matchWinner, _unset)
          ? this.matchWinner
          : matchWinner as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetScore': targetScore,
        'round': round,
        'dealer': dealer,
        'turn': turn,
        'phase': phase.name,
        'stock': [for (final c in stock) c.toJson()],
        'discard': [for (final c in discard) c.toJson()],
        'hands': [
          for (final h in hands) [for (final c in h) c.toJson()],
        ],
        'table': [for (final m in table) m.toJson()],
        'opened': opened,
        'staged': [
          for (final s in staged) [for (final c in s) c.toJson()],
        ],
        'takenId': takenId,
        'scores': scores,
        'roundResult': roundResult?.toJson(),
        'matchWinner': matchWinner,
      };
}

List<RamiCard> _cardsFromJson(Object? raw) => [
      for (final c in raw as List) RamiCard.fromJson(c as Map<String, dynamic>),
    ];

final _defaultRandom = math.Random();

// ---------------------------------------------------------------------------
// Utilitaires
// ---------------------------------------------------------------------------

bool isJoker(RamiCard card) => card.isJoker;

int nextSeat(int seat) => (seat + 1) % 4;

List<RamiCard> _naturalsOf(List<RamiCard> cards) =>
    cards.where((c) => !c.isJoker).toList();

int cardValue(RamiCard card) => card.isJoker ? 20 : math.min(card.rank, 10);

int pointsOf(List<RamiCard> cards) =>
    cards.fold<int>(0, (sum, card) => sum + cardValue(card));

List<RamiCard> _createDeck(RandomDouble random) {
  final cards = <RamiCard>[];
  for (var copy = 0; copy < 2; copy++) {
    for (final suit in RamiSuit.values) {
      for (var rank = 1; rank <= 13; rank++) {
        cards.add(
          RamiCard(id: '${suit.name}-$rank-$copy', suit: suit, rank: rank),
        );
      }
    }
  }
  cards.add(const RamiCard(id: 'joker-0', suit: null, rank: 0));
  cards.add(const RamiCard(id: 'joker-1', suit: null, rank: 0));
  return shuffled(cards, random);
}

// ---------------------------------------------------------------------------
// Combinaisons
// ---------------------------------------------------------------------------

/// Suite : une seule couleur, rangs distincts qui se suivent (As bas ou haut, sans boucler).
/// Les jokers comblent les trous. Renvoie l'ordre des cartes, ou null.
List<RamiCard>? _runOrder(List<RamiCard> cards) {
  final naturals = _naturalsOf(cards);
  final jokers = cards.where((c) => c.isJoker).toList();
  if (naturals.length < 2 ||
      naturals.any((card) => card.suit != naturals.first.suit)) return null;

  for (final aceHigh in [false, true]) {
    final slots = sortedStable([
      for (final card in naturals)
        (card: card, pos: card.rank == 1 && aceHigh ? _aceHigh : card.rank),
    ], (a, b) => a.pos - b.pos);
    for (var i = 1; i < slots.length; i++) {
      if (slots[i].pos == slots[i - 1].pos) return null;
    }

    final len = cards.length;
    final low = math.max(1, slots.last.pos - len + 1);
    final high = math.min(slots.first.pos, _aceHigh + 1 - len);
    if (low > high) continue;

    final order = <RamiCard>[];
    var joker = 0;
    for (var pos = low; pos < low + len; pos++) {
      RamiCard? slotCard;
      for (final slot in slots) {
        if (slot.pos == pos) slotCard = slot.card;
      }
      order.add(slotCard ?? jokers[joker++]);
    }
    return order;
  }
  return null;
}

/// Brelan ou carré : même valeur, couleurs différentes.
bool _isSet(List<RamiCard> cards) {
  final naturals = _naturalsOf(cards);
  if (naturals.isEmpty) return true;
  return naturals.every((card) => card.rank == naturals.first.rank);
}

bool isValidMeld(List<RamiCard> cards) {
  final naturals = _naturalsOf(cards);
  if (cards.length < 3 || cards.length > 13 || naturals.length < 2)
    return false;
  if (_isSet(cards)) {
    return cards.length <= 4 &&
        naturals.map((c) => c.suit).toSet().length == naturals.length;
  }
  return _runOrder(cards) != null;
}

List<RamiCard> arrangeMeld(List<RamiCard> cards) =>
    _isSet(cards) ? cards : (_runOrder(cards) ?? cards);

/// Paquets valides formés par des cartes voisines dans l'ordre de la main.
List<List<RamiCard>> meldGroups(List<RamiCard> hand) {
  final groups = <List<RamiCard>>[];
  var start = 0;
  while (start < hand.length) {
    var end = math.min(hand.length, start + 13);
    while (end >= start + 3 && !isValidMeld(hand.sublist(start, end))) {
      end--;
    }
    if (end < start + 3) {
      start++;
      continue;
    }
    groups.add(hand.sublist(start, end));
    start = end;
  }
  return groups;
}

// ---------------------------------------------------------------------------
// Donne, fin de manche
// ---------------------------------------------------------------------------

RamiState _setHand(RamiState state, int seat, List<RamiCard> hand) =>
    state.copyWith(
      hands: [
        for (var i = 0; i < state.hands.length; i++)
          i == seat ? hand : state.hands[i],
      ],
    );

RamiState dealRound(
  List<int> scores,
  int dealer,
  int round,
  int targetScore, [
  RandomDouble? random,
]) {
  final deck = _createDeck(random ?? _defaultRandom.nextDouble);
  final stock = deck.sublist(ramiSeats.length * _handSize);
  final discardCard = stock.removeLast();
  return RamiState(
    targetScore: targetScore,
    round: round,
    dealer: dealer,
    turn: nextSeat(dealer),
    phase: RamiPhase.draw,
    stock: stock,
    discard: [discardCard],
    hands: [
      for (final seat in ramiSeats)
        deck.sublist(seat * _handSize, (seat + 1) * _handSize),
    ],
    table: const [],
    opened: [for (final _ in ramiSeats) false],
    staged: const [],
    takenId: null,
    scores: [...scores],
    roundResult: null,
    matchWinner: null,
  );
}

RamiState newMatch([int targetScore = 100, RandomDouble? random]) =>
    dealRound([0, 0, 0, 0], 3, 1, targetScore, random);

RamiState nextRound(RamiState state, [RandomDouble? random]) {
  if (state.phase != RamiPhase.end || state.matchWinner != null) return state;
  return dealRound(
    state.scores,
    nextSeat(state.dealer),
    state.round + 1,
    state.targetScore,
    random,
  );
}

RamiState _finish(RamiState state, int? winner) {
  final penalties = [
    for (final seat in ramiSeats)
      seat == winner ? 0 : pointsOf(state.hands[seat]),
  ];
  final scores = [
    for (final seat in ramiSeats) state.scores[seat] + penalties[seat],
  ];
  final lowest = scores.reduce(math.min);
  final leaders = [
    for (final seat in ramiSeats)
      if (scores[seat] == lowest) seat,
  ];
  final reached = scores.any((score) => score >= state.targetScore);
  return state.copyWith(
    phase: RamiPhase.end,
    scores: scores,
    roundResult: RamiRoundResult(winner: winner, penalties: penalties),
    matchWinner: reached && leaders.length == 1 ? leaders.first : null,
    staged: const [],
    takenId: null,
  );
}

// ---------------------------------------------------------------------------
// Coups du joueur
// ---------------------------------------------------------------------------

RamiState drawStock(RamiState state, [RandomDouble? random]) {
  if (state.phase != RamiPhase.draw) return state;
  var stock = state.stock;
  var discard = state.discard;
  if (stock.isEmpty) {
    if (discard.length < 2) return _finish(state, null);
    stock = shuffled(
      discard.sublist(0, discard.length - 1),
      random ?? _defaultRandom.nextDouble,
    );
    discard = discard.sublist(discard.length - 1);
  }
  final card = stock.last;
  return _setHand(
    state.copyWith(
      stock: stock.sublist(0, stock.length - 1),
      discard: discard,
      phase: RamiPhase.play,
      takenId: null,
    ),
    state.turn,
    [...state.hands[state.turn], card],
  );
}

RamiState drawDiscard(RamiState state) {
  if (state.phase != RamiPhase.draw || state.discard.isEmpty) return state;
  final card = state.discard.last;
  return _setHand(
    state.copyWith(
      discard: state.discard.sublist(0, state.discard.length - 1),
      phase: RamiPhase.play,
      takenId: card.id,
    ),
    state.turn,
    [...state.hands[state.turn], card],
  );
}

/// Hors ouverture, la combinaison part directement sur la table. Pendant l'ouverture, elle est mise de côté.
RamiState poseMeld(RamiState state, List<String> cardIds) {
  if (state.phase != RamiPhase.play || cardIds.toSet().length != cardIds.length)
    return state;
  final seat = state.turn;
  final hand = state.hands[seat];
  final picked = <RamiCard>[];
  for (final id in cardIds) {
    final index = hand.indexWhere((item) => item.id == id);
    if (index < 0) return state;
    picked.add(hand[index]);
  }
  if (!isValidMeld(picked)) return state;

  final cards = arrangeMeld(picked);
  final rest = hand.where((card) => !cardIds.contains(card.id)).toList();
  final next = _setHand(state, seat, rest);
  if (!state.opened[seat]) {
    return next.copyWith(staged: [...state.staged, cards]);
  }

  final updated = next.copyWith(
    table: [
      ...state.table,
      Meld(id: cards.first.id, cards: cards),
    ],
  );
  return rest.isEmpty ? _finish(updated, seat) : updated;
}

RamiState commitOpening(RamiState state) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      state.opened[seat] ||
      state.staged.isEmpty) return state;
  final staged = state.staged.fold<int>(
    0,
    (sum, cards) => sum + pointsOf(cards),
  );
  if (staged < ramiOpenMin) return state;

  final next = state.copyWith(
    table: [
      ...state.table,
      for (final cards in state.staged) Meld(id: cards.first.id, cards: cards),
    ],
    staged: const [],
    opened: [
      for (var i = 0; i < state.opened.length; i++)
        state.opened[i] || i == seat,
    ],
  );
  return next.hands[seat].isEmpty ? _finish(next, seat) : next;
}

RamiState cancelStaged(RamiState state) {
  if (state.phase != RamiPhase.play || state.staged.isEmpty) return state;
  final seat = state.turn;
  return _setHand(state.copyWith(staged: const []), seat, [
    ...state.hands[seat],
    ...state.staged.expand((cards) => cards),
  ]);
}

RamiState layOff(RamiState state, String cardId, String meldId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      !state.opened[seat] ||
      state.staged.isNotEmpty) return state;
  final hand = state.hands[seat];
  final cardIndex = hand.indexWhere((item) => item.id == cardId);
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (cardIndex < 0 || meldIndex < 0) return state;
  final card = hand[cardIndex];
  final meld = state.table[meldIndex];

  final cards = arrangeMeld([...meld.cards, card]);
  if (!isValidMeld(cards)) return state;

  final table = [
    for (final item in state.table)
      item.id == meldId ? Meld(id: item.id, cards: cards) : item,
  ];
  final next = _setHand(
    state.copyWith(table: table),
    seat,
    hand.where((item) => item.id != cardId).toList(),
  );
  return next.hands[seat].isEmpty ? _finish(next, seat) : next;
}

RamiState discardCard(RamiState state, String cardId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play || state.staged.isNotEmpty) return state;
  final hand = state.hands[seat];
  final index = hand.indexWhere((item) => item.id == cardId);
  if (index < 0) return state;
  final card = hand[index];
  // La carte prise à la défausse doit rester en main, sauf si c'est la dernière.
  if (card.id == state.takenId && hand.length > 1) return state;

  final next = _setHand(
    state.copyWith(discard: [...state.discard, card], takenId: null),
    seat,
    hand.where((item) => item.id != cardId).toList(),
  );
  if (next.hands[seat].isEmpty) return _finish(next, seat);
  return next.copyWith(turn: nextSeat(seat), phase: RamiPhase.draw);
}

// ---------------------------------------------------------------------------
// IA
// ---------------------------------------------------------------------------

RamiCard? _firstWhereOrNull(
  Iterable<RamiCard> cards,
  bool Function(RamiCard) test,
) {
  for (final card in cards) {
    if (test(card)) return card;
  }
  return null;
}

/// Recherche gloutonne de brelans et carrés.
List<List<RamiCard>> _setCandidates(List<RamiCard> hand) {
  final jokers = hand.where((c) => c.isJoker).toList();
  final candidates = <List<RamiCard>>[];
  for (var rank = 1; rank <= 13; rank++) {
    final ofRank = <RamiCard>[
      for (final suit in RamiSuit.values)
        if (_firstWhereOrNull(
          hand,
          (item) => item.suit == suit && item.rank == rank,
        )
            case final card?)
          card,
    ];
    if (ofRank.length >= 3) candidates.add(ofRank);
    if (ofRank.length >= 2 && ofRank.length < 4 && jokers.isNotEmpty) {
      candidates.add([...ofRank, jokers.first]);
    }
  }
  return candidates;
}

/// Recherche de suites dans chaque couleur, avec jokers pour les trous.
List<List<RamiCard>> _runCandidates(List<RamiCard> hand) {
  final jokers = hand.where((c) => c.isJoker).toList();
  final candidates = <List<RamiCard>>[];
  for (final suit in RamiSuit.values) {
    RamiCard? cardAt(int pos) => _firstWhereOrNull(
          hand,
          (card) =>
              card.suit == suit && card.rank == (pos == _aceHigh ? 1 : pos),
        );
    for (var low = 1; low <= _aceHigh; low++) {
      for (var len = 3; len <= 13 && low + len - 1 <= _aceHigh; len++) {
        final parts = <RamiCard>[];
        var missing = 0;
        for (var pos = low; pos < low + len; pos++) {
          final card = cardAt(pos);
          if (card != null) {
            parts.add(card);
          } else {
            missing++;
          }
        }
        if (parts.length < 2 || missing > jokers.length) continue;
        final candidate = [...parts, ...jokers.take(missing)];
        if (isValidMeld(candidate)) candidates.add(candidate);
      }
    }
  }
  return candidates;
}

List<List<RamiCard>> _planMelds(List<RamiCard> hand) {
  final candidates = sortedStable(
    [..._setCandidates(hand), ..._runCandidates(hand)],
    (a, b) => pointsOf(b) - pointsOf(a) != 0
        ? pointsOf(b) - pointsOf(a)
        : b.length - a.length,
  );
  final used = <String>{};
  final plan = <List<RamiCard>>[];
  for (final cards in candidates) {
    if (cards.any((card) => used.contains(card.id))) continue;
    for (final card in cards) {
      used.add(card.id);
    }
    plan.add(cards);
  }
  return plan;
}

int _planValue(List<RamiCard> cards) =>
    _planMelds(cards).fold<int>(0, (sum, meld) => sum + pointsOf(meld));

({String cardId, String meldId})? _findLayOff(RamiState state, int seat) {
  for (final card in state.hands[seat]) {
    for (final meld in state.table) {
      if (isValidMeld([...meld.cards, card]))
        return (cardId: card.id, meldId: meld.id);
    }
  }
  return null;
}

int _keepValue(RamiCard card, List<RamiCard> hand) {
  if (card.isJoker) return 100;
  var total = 0;
  for (final other in hand) {
    if (other.id == card.id || other.isJoker) continue;
    if (other.rank == card.rank) {
      total += 3;
    } else if (other.suit == card.suit) {
      final gap = (other.rank - card.rank).abs();
      if (gap == 1) total += 2;
      if (gap == 2) total += 1;
    }
  }
  return total;
}

String _chooseDiscard(
  RamiState state,
  int seat,
  RamiAiLevel level,
  RandomDouble random,
) {
  final hand = state.hands[seat];
  final pool = hand.where((card) => card.id != state.takenId).toList();
  final options = pool.isNotEmpty ? pool : hand;
  if (level == RamiAiLevel.facile) {
    return options[(random() * options.length).floor()].id;
  }

  double score(RamiCard card) {
    // Difficile : évite de jeter une carte que les autres peuvent poser sur la table.
    final useful = level == RamiAiLevel.difficile &&
        state.table.any((meld) => isValidMeld([...meld.cards, card]));
    // Difficile : une carte qui se combine avec la défausse (que le joueur a pu laisser passer) est gardée.
    final pile =
        level == RamiAiLevel.difficile ? _keepValue(card, state.discard) : 0;
    return _keepValue(card, hand) * 2 +
        pile -
        cardValue(card) * 0.5 +
        (useful ? 4 : 0);
  }

  var best = options.first;
  for (final card in options.skip(1)) {
    if (score(card) < score(best)) best = card;
  }
  return best.id;
}

RamiState _aiDraw(RamiState state, RamiAiLevel level, RandomDouble random) {
  final seat = state.turn;
  if (state.discard.isEmpty) return drawStock(state, random);
  final top = state.discard.last;
  final hand = state.hands[seat];
  final improves = _planValue([...hand, top]) > _planValue(hand);
  final layable = state.opened[seat] &&
      state.table.any((meld) => isValidMeld([...meld.cards, top]));
  final take = level == RamiAiLevel.facile
      ? random() < 0.5
      : isJoker(top) || improves || layable;
  return take ? drawDiscard(state) : drawStock(state, random);
}

RamiState _poseAll(RamiState state, List<List<RamiCard>> plan) => plan.fold(
      state,
      (current, cards) =>
          poseMeld(current, [for (final card in cards) card.id]),
    );

/// Une action atomique de l'IA (pioche, pose, ajout, défausse). Le contrôleur la rappelle tant que ce n'est pas son tour.
RamiState aiStep(RamiState state, RamiAiLevel level, [RandomDouble? random]) {
  final draw = random ?? _defaultRandom.nextDouble;
  if (state.phase == RamiPhase.draw) return _aiDraw(state, level, draw);
  if (state.phase != RamiPhase.play) return state;
  if (state.staged.isNotEmpty) return cancelStaged(state);

  final seat = state.turn;
  final plan = _planMelds(state.hands[seat]);
  final planTotal = plan.fold<int>(0, (sum, cards) => sum + pointsOf(cards));
  // Facile : ouvre plus tard que la règle (seuil relevé).
  final openMin = level == RamiAiLevel.facile ? ramiOpenMin + 15 : ramiOpenMin;
  if (state.opened[seat] && plan.isNotEmpty) return _poseAll(state, plan);
  if (!state.opened[seat] && planTotal >= openMin) {
    return commitOpening(_poseAll(state, plan));
  }

  if (state.opened[seat]) {
    final lay = _findLayOff(state, seat);
    // Facile : oublie de poser sur la table une fois sur deux.
    final forgets = level == RamiAiLevel.facile && draw() < 0.5;
    if (lay != null && !forgets) return layOff(state, lay.cardId, lay.meldId);
  }
  return discardCard(state, _chooseDiscard(state, seat, level, draw));
}
