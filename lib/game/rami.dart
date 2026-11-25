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

/// Seuil de la prochaine ouverture : 51 pour la première, puis strictement plus que la précédente.
int minOpening(RamiState state) =>
    state.lastOpening == 0 ? ramiOpenMin : state.lastOpening + 1;
const _handSize = 14;
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
  const Meld({required this.id, required this.cards, this.owner = -1});

  factory Meld.fromJson(Map<String, dynamic> json) => Meld(
        id: json['id'] as String,
        cards: _cardsFromJson(json['cards']),
        owner: (json['owner'] as int?) ?? -1,
      );

  final String id;
  final List<RamiCard> cards;

  /// Siège du joueur qui a posé le paquet (0 = moi). -1 : inconnu (sauvegardes anciennes).
  final int owner;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cards': [for (final c in cards) c.toJson()],
        'owner': owner,
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
    required this.lastOpening,
    this.firstTour = false,
    this.openings = const [0, 0, 0, 0],
    this.recycles = 0,
    this.turnMeldIds = const [],
    this.turnOpenMin = 0,
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
        lastOpening: (json['lastOpening'] as int?) ?? 0,
        firstTour: (json['firstTour'] as bool?) ?? false,
        openings: json['openings'] == null
            ? const [0, 0, 0, 0]
            : [for (final o in json['openings'] as List) o as int],
        recycles: (json['recycles'] as int?) ?? 0,
        turnMeldIds: json['turnMeldIds'] == null
            ? const []
            : [for (final id in json['turnMeldIds'] as List) id as String],
        turnOpenMin: (json['turnOpenMin'] as int?) ?? 0,
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

  /// Points de la dernière ouverture de la manche (0 : personne n'a ouvert).
  final int lastOpening;

  /// Première tournée : jusqu'au passage du donneur. Pas de pose, pas de prise de la défausse.
  final bool firstTour;

  /// Points de la première ouverture de chaque joueur cette manche (0 : pas ouvert).
  final List<int> openings;

  /// Nombre de fois où la défausse a été recyclée en pioche cette manche.
  final int recycles;

  /// Paquets posés pendant le tour courant, avant ou après ouverture (#661).
  /// Seuls ceux-là peuvent être repris ; ils sont vidés à la défausse.
  final List<String> turnMeldIds;

  /// Seuil d'ouverture franchi pendant le tour courant (0 : pas ouvert pendant ce tour).
  /// Une reprise ne doit pas faire retomber le total sous ce seuil (#661).
  final int turnOpenMin;

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
    int? lastOpening,
    bool? firstTour,
    List<int>? openings,
    int? recycles,
    List<String>? turnMeldIds,
    int? turnOpenMin,
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
      lastOpening: lastOpening ?? this.lastOpening,
      firstTour: firstTour ?? this.firstTour,
      openings: openings ?? this.openings,
      recycles: recycles ?? this.recycles,
      turnMeldIds: turnMeldIds ?? this.turnMeldIds,
      turnOpenMin: turnOpenMin ?? this.turnOpenMin,
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
        'lastOpening': lastOpening,
        'firstTour': firstTour,
        'openings': openings,
        'recycles': recycles,
        'turnMeldIds': turnMeldIds,
        'turnOpenMin': turnOpenMin,
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

/// Valeur d'une carte en main (fin de manche, #416) : joker 20, as 1, 2 à 9 leur chiffre, figures 10.
int cardValue(RamiCard card) => card.isJoker ? 20 : math.min(card.rank, 10);

/// Points des cartes restées en main (fin de manche).
int handPointsOf(List<RamiCard> cards) =>
    cards.fold<int>(0, (sum, card) => sum + cardValue(card));

/// Valeur d'une position de suite : as haut (14) = 10, as bas (1) = 1, figures 10.
int _valueAtPosition(int pos) => pos == _aceHigh ? 10 : math.min(pos, 10);

/// Points d'un paquet posé sur la table (#422) : selon sa position,
/// l'as vaut 10 côté roi ou dans un brelan d'as, 1 côté 2 ; le joker vaut la carte qu'il remplace.
/// Un ensemble invalide compte ses cartes en main.
int pointsOf(List<RamiCard> cards) {
  if (!isValidMeld(cards)) return handPointsOf(cards);
  if (_isSet(cards)) {
    final rank = _naturalsOf(cards).first.rank;
    final value = rank == 1 ? 10 : math.min(rank, 10);
    return cards.length * value;
  }
  final span = _runSpan(cards)!;
  var sum = 0;
  for (var i = 0; i < span.order.length; i++) {
    sum += _valueAtPosition(span.low + i);
  }
  return sum;
}

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
  cards.add(const RamiCard(id: 'joker-2', suit: null, rank: 0));
  cards.add(const RamiCard(id: 'joker-3', suit: null, rank: 0));
  return shuffled(cards, random);
}

// ---------------------------------------------------------------------------
// Combinaisons
// ---------------------------------------------------------------------------

/// Suite : une seule couleur, rangs distincts qui se suivent (As bas ou haut, sans boucler).
/// Les jokers comblent les trous. Renvoie l'ordre des cartes, ou null.
List<RamiCard>? _runOrder(List<RamiCard> cards) => _runSpan(cards)?.order;

/// Ordre d'une suite et position (1 à 14) de sa première carte.
({List<RamiCard> order, int low})? _runSpan(List<RamiCard> cards) {
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
    final lowest = math.max(1, slots.last.pos - len + 1);
    final highest = math.min(slots.first.pos, _aceHigh + 1 - len);
    if (lowest > highest) continue;
    // Joker posé à droite de la suite (dernier de la liste) : il prend la place la plus haute (#838).
    final low = cards.last.isJoker ? highest : lowest;

    final order = <RamiCard>[];
    var joker = 0;
    for (var pos = low; pos < low + len; pos++) {
      RamiCard? slotCard;
      for (final slot in slots) {
        if (slot.pos == pos) slotCard = slot.card;
      }
      order.add(slotCard ?? jokers[joker++]);
    }
    return (order: order, low: low);
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

/// Liste à passer à [arrangeMeld] quand on ajoute [card] à [cards] : un joker resté à droite
/// garde sa place la plus haute, la nouvelle carte se glisse avant lui (#838).
List<RamiCard> extendMeld(List<RamiCard> cards, RamiCard card) =>
    cards.isNotEmpty && cards.last.isJoker
        ? [...cards.sublist(0, cards.length - 1), card, cards.last]
        : [...cards, card];

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
    lastOpening: 0,
    firstTour: true,
    openings: [for (final _ in ramiSeats) 0],
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
  // Gagnant : -10. Perdant sans paquet posé : +100. Perdant ayant posé : points des cartes en main (#416).
  final penalties = [
    for (final seat in ramiSeats)
      if (seat == winner)
        -10
      else if (!state.opened[seat])
        100
      else
        handPointsOf(state.hands[seat]),
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

/// Nombre maximal de recyclages de la défausse par manche : garde-fou contre une partie
/// qui tournerait indéfiniment (#458, #305).
const int ramiMaxRecycles = 2;

RamiState drawStock(RamiState state, [RandomDouble? random]) {
  if (state.phase != RamiPhase.draw) return state;
  var current = state;
  if (current.stock.isEmpty) {
    // Pioche vide : la défausse (sauf sa carte du dessus) est mélangée et redevient pioche.
    // Fin sans gagnant seulement si rien n'est recyclable ou si le garde-fou est atteint (#458).
    if (current.discard.length < 2 || current.recycles >= ramiMaxRecycles) {
      return _finish(state, null);
    }
    current = _recycleDiscard(current, random ?? _defaultRandom.nextDouble);
  }
  final stock = current.stock;
  final card = stock.last;
  return _setHand(
    current.copyWith(
      stock: stock.sublist(0, stock.length - 1),
      phase: RamiPhase.play,
      takenId: null,
    ),
    state.turn,
    [...current.hands[state.turn], card],
  );
}

/// Défausse → pioche : tout sauf la carte du dessus, mélangé.
RamiState _recycleDiscard(RamiState state, RandomDouble random) {
  final top = state.discard.last;
  final pile = shuffled(
    state.discard.sublist(0, state.discard.length - 1),
    random,
  );
  return state.copyWith(
    stock: pile,
    discard: [top],
    recycles: state.recycles + 1,
  );
}

/// Vrai si la carte du dessus peut être posée dès ce tour : sinon on ne peut pas la prendre.
bool canUseDiscardTop(RamiState state) {
  if (state.firstTour || state.discard.isEmpty) return false;
  final seat = state.turn;
  final top = state.discard.last;
  final hand = [...state.hands[seat], top];
  final plan = _usablePlan(hand, top.id);
  final carries = plan.isNotEmpty && plan.first.any((c) => c.id == top.id);
  if (state.opened[seat]) {
    return carries ||
        state.table.any((meld) => isValidMeld([...meld.cards, top]));
  }
  final total = plan.fold<int>(0, (sum, cards) => sum + pointsOf(cards));
  return carries && total >= minOpening(state);
}

/// Le joueur peut toujours prendre la carte du dessus (#315) : il doit ensuite la poser
/// (avant ouverture) ou la remettre, sinon il ne peut rien défausser d'autre.
/// L'IA ne prend que les cartes utiles (voir [canUseDiscardTop] et [_aiDraw]).
RamiState drawDiscard(RamiState state) {
  if (state.phase != RamiPhase.draw ||
      state.firstTour ||
      state.discard.isEmpty) {
    return state;
  }
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

/// Remet sur la défausse la carte prise, tant qu'aucune pose n'a été faite ce tour.
RamiState returnTaken(RamiState state) {
  final id = state.takenId;
  if (state.phase != RamiPhase.play || id == null || state.staged.isNotEmpty) {
    return state;
  }
  final seat = state.turn;
  final hand = state.hands[seat];
  final index = hand.indexWhere((item) => item.id == id);
  if (index < 0) return state;
  return _setHand(
    state.copyWith(
      discard: [...state.discard, hand[index]],
      phase: RamiPhase.draw,
      takenId: null,
    ),
    seat,
    hand.where((item) => item.id != id).toList(),
  );
}

/// Pose une combinaison directement sur la table (#496). Avant ouverture, les points posés
/// pendant le tour s'additionnent : dès que le seuil est atteint, le joueur est ouvert.
/// Une pose ne peut jamais vider la main : il faut toujours défausser sa dernière carte.
RamiState poseMeld(RamiState state, List<String> cardIds) {
  if (state.phase != RamiPhase.play ||
      state.firstTour ||
      cardIds.toSet().length != cardIds.length) {
    return state;
  }
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
  if (rest.isEmpty) return state;
  final meldId = _newMeldId(state.table, cards);
  final placed = _setHand(state, seat, rest).copyWith(
    table: [
      ...state.table,
      Meld(id: meldId, cards: cards, owner: seat),
    ],
    turnMeldIds: [...state.turnMeldIds, meldId],
  );
  if (state.opened[seat]) return placed;

  final turnCards = [...state.staged, cards];
  final total = turnCards.fold<int>(0, (sum, item) => sum + pointsOf(item));
  if (total < minOpening(state)) return placed.copyWith(staged: turnCards);
  return _open(placed, seat, total);
}

/// Rami directe (#867) : toute la main est posée d'un coup, sans seuil d'ouverture, et la
/// manche est gagnée. Si la main ne peut pas être entièrement posée, l'état est renvoyé
/// tel quel (identical) : la tentative est annulée et rien ne change.
RamiState ramiDirect(RamiState state) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play || state.firstTour || state.opened[seat]) {
    return state;
  }
  final cover = _exactCover(state.hands[seat]);
  if (cover == null) return state;
  var table = state.table;
  final turnIds = [...state.turnMeldIds];
  for (final group in cover) {
    final cards = arrangeMeld(group);
    final meldId = _newMeldId(table, cards);
    table = [...table, Meld(id: meldId, cards: cards, owner: seat)];
    turnIds.add(meldId);
  }
  final placed = _setHand(
    state.copyWith(table: table, turnMeldIds: turnIds),
    seat,
    const [],
  );
  return _finish(placed, seat);
}

/// Recouvrement exact de [hand] par des combinaisons valides, ou null s'il n'existe pas.
/// Retour arrière sur la première carte non couverte ; garde-fou sur le nombre d'essais.
List<List<RamiCard>>? _exactCover(List<RamiCard> hand) {
  if (hand.isEmpty) return null;
  final candidates = _allMeldCandidates(hand);
  final used = <String>{};
  var budget = 200000;

  List<List<RamiCard>>? solve() {
    final free = [
      for (final card in hand)
        if (!used.contains(card.id)) card
    ];
    if (free.isEmpty) return [];
    final target = free.first;
    for (final candidate in candidates) {
      if (--budget < 0) return null;
      if (!candidate.any((card) => card.id == target.id)) continue;
      if (candidate.any((card) => used.contains(card.id))) continue;
      used.addAll(candidate.map((card) => card.id));
      final rest = solve();
      if (rest != null) return [candidate, ...rest];
      used.removeAll(candidate.map((card) => card.id));
    }
    return null;
  }

  return solve();
}

/// Toutes les combinaisons valides de la main : brelans et carrés (jokers compris) et suites
/// de tous les intervalles. Contrairement à [_setCandidates] et [_runCandidates], aucune
/// combinaison n'est écartée : le recouvrement exact doit pouvoir tout trouver.
List<List<RamiCard>> _allMeldCandidates(List<RamiCard> hand) {
  final naturals = hand.where((c) => !c.isJoker).toList();
  final jokers = hand.where((c) => c.isJoker).toList();
  final out = <List<RamiCard>>[];

  // Brelans et carrés : un sous-ensemble de cartes de même rang, complété par des jokers.
  for (var rank = 1; rank <= 13; rank++) {
    final ofRank = [
      for (final c in naturals)
        if (c.rank == rank) c
    ];
    for (var mask = 1; mask < (1 << ofRank.length); mask++) {
      final chosen = [
        for (var i = 0; i < ofRank.length; i++)
          if ((mask & (1 << i)) != 0) ofRank[i],
      ];
      for (var m = 0; m <= jokers.length && chosen.length + m <= 4; m++) {
        final cand = [...chosen, ...jokers.take(m)];
        if (cand.length >= 3 && isValidMeld(cand)) out.add(cand);
      }
    }
  }

  // Suites : pour chaque couleur et intervalle, un choix de carte par position (ou joker).
  for (final suit in RamiSuit.values) {
    for (var low = 1; low <= _aceHigh; low++) {
      for (var len = 3; len <= 13 && low + len - 1 <= _aceHigh; len++) {
        final slots = <List<RamiCard?>>[];
        for (var pos = low; pos < low + len; pos++) {
          final rank = pos == _aceHigh ? 1 : pos;
          final options = <RamiCard?>[];
          for (final c in naturals) {
            if (c.suit == suit && c.rank == rank) options.add(c);
          }
          options.add(null);
          slots.add(options);
        }
        _runProduct(slots, 0, <RamiCard>[], 0, jokers.length, (cards) {
          if (isValidMeld(cards)) out.add(cards);
        });
      }
    }
  }
  return out;
}

/// Produit cartésien des positions d'une suite ; [null] = joker, au plus [maxJokers].
void _runProduct(
  List<List<RamiCard?>> slots,
  int index,
  List<RamiCard> acc,
  int jokersUsed,
  int maxJokers,
  void Function(List<RamiCard>) emit,
) {
  if (index == slots.length) {
    emit([...acc]);
    return;
  }
  for (final choice in slots[index]) {
    if (choice == null) {
      if (jokersUsed >= maxJokers) continue;
      _runProduct(slots, index + 1, acc, jokersUsed + 1, maxJokers, emit);
    } else {
      acc.add(choice);
      _runProduct(slots, index + 1, acc, jokersUsed, maxJokers, emit);
      acc.removeLast();
    }
  }
}

/// Ouvre le joueur : ses points d'ouverture sont enregistrés et le compte du tour est remis à zéro.
RamiState _open(RamiState state, int seat, int points) => state.copyWith(
      staged: const [],
      turnOpenMin: minOpening(state),
      lastOpening: points,
      openings: [
        for (var i = 0; i < state.openings.length; i++)
          i == seat ? points : state.openings[i],
      ],
      opened: [
        for (var i = 0; i < state.opened.length; i++)
          state.opened[i] || i == seat,
      ],
    );

/// Annule les poses du tour en cours, avant ouverture (#496) : les combinaisons repartent
/// de la table et les cartes reviennent en main. Après ouverture, rien n'est annulé.
RamiState cancelStaged(RamiState state) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      state.staged.isEmpty ||
      state.opened[seat]) return state;
  final posed = {
    for (final group in state.staged)
      for (final card in group) card.id,
  };
  final table = [
    for (final meld in state.table)
      if (!meld.cards.every((card) => posed.contains(card.id))) meld,
  ];
  final returned = [for (final group in state.staged) ...group];
  return _setHand(
    state.copyWith(
      table: table,
      staged: const [],
      turnMeldIds: [
        for (final id in state.turnMeldIds)
          if (table.any((meld) => meld.id == id)) id,
      ],
    ),
    seat,
    [...state.hands[seat], ...returned],
  );
}

/// Indice du paquet posé pendant ce tour (avant ouverture) qui porte [meldId], ou -1.
int _stagedGroupIndex(RamiState state, String meldId) {
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (meldIndex < 0) return -1;
  final ids = {for (final card in state.table[meldIndex].cards) card.id};
  for (var i = 0; i < state.staged.length; i++) {
    final group = state.staged[i];
    if (group.length == ids.length &&
        group.every((card) => ids.contains(card.id))) {
      return i;
    }
  }
  return -1;
}

/// Vrai si [meldId] a été posé pendant le tour courant (#661).
bool isTurnMeld(RamiState state, String meldId) =>
    state.turnMeldIds.contains(meldId);

/// Vrai si [meldId] est un paquet posé pendant le tour courant, avant ouverture (#660).
bool isStagedMeld(RamiState state, String meldId) =>
    _stagedGroupIndex(state, meldId) >= 0;

RamiState layOff(RamiState state, String cardId, String meldId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play || state.firstTour) return state;
  // Un paquet posé pendant le tour reste modifiable, avant comme après ouverture (#660).
  final stagedIndex = _stagedGroupIndex(state, meldId);
  final refused =
      state.staged.isNotEmpty ? stagedIndex < 0 : !state.opened[seat];
  if (refused) return state;
  final hand = state.hands[seat];
  final cardIndex = hand.indexWhere((item) => item.id == cardId);
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (cardIndex < 0 || meldIndex < 0) return state;
  if (hand.length <= 1) return state; // jamais vider sa main en posant (#496)
  final card = hand[cardIndex];
  final meld = state.table[meldIndex];

  // D'abord reprendre un joker du paquet, s'il peut être remplacé (#390).
  final taken = takeJoker(state, cardId, meldId);
  if (!identical(taken, state)) return taken;

  final cards = arrangeMeld(extendMeld(meld.cards, card));
  if (!isValidMeld(cards)) return state;

  final table = [
    for (final item in state.table)
      item.id == meldId
          ? Meld(id: item.id, cards: cards, owner: item.owner)
          : item,
  ];
  final next = _setHand(
    state.copyWith(table: table),
    seat,
    hand.where((item) => item.id != cardId).toList(),
  );
  if (stagedIndex < 0) return next;

  // Avant ouverture : le paquet compte pour l'ouverture avec sa nouvelle carte.
  final turnCards = [
    for (var i = 0; i < state.staged.length; i++)
      i == stagedIndex ? cards : state.staged[i],
  ];
  final total = turnCards.fold<int>(0, (sum, item) => sum + pointsOf(item));
  if (total < minOpening(state)) return next.copyWith(staged: turnCards);
  return _open(next, seat, total);
}

/// Total des points des paquets posés pendant le tour (#661).
int _turnPoints(RamiState state) {
  var total = 0;
  for (final meld in state.table) {
    if (state.turnMeldIds.contains(meld.id)) total += pointsOf(meld.cards);
  }
  return total;
}

/// Reprend une carte d'un paquet posé pendant le tour, dans la main (#661).
/// Le paquet restant doit rester valide (3 cartes au moins). Un joker ne se reprend pas ici.
RamiState takeBackFromMeld(RamiState state, String cardId, String meldId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      state.firstTour ||
      !state.turnMeldIds.contains(meldId)) return state;
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (meldIndex < 0) return state;
  final meld = state.table[meldIndex];
  final cardIndex = meld.cards.indexWhere((item) => item.id == cardId);
  if (cardIndex < 0 || meld.cards[cardIndex].isJoker) return state;
  final card = meld.cards[cardIndex];
  final remaining = [
    for (final item in meld.cards)
      if (item.id != cardId) item,
  ];
  if (remaining.length < 3 || !isValidMeld(remaining)) return state;
  final cards = arrangeMeld(remaining);

  final stagedIndex = _stagedGroupIndex(state, meldId);
  if (!state.opened[seat] && stagedIndex < 0) return state;
  final table = [
    for (final item in state.table)
      item.id == meldId
          ? Meld(id: item.id, cards: cards, owner: item.owner)
          : item,
  ];
  final next = _setHand(
    state.copyWith(table: table),
    seat,
    [...state.hands[seat], card],
  );
  if (!state.opened[seat]) {
    // Avant ouverture : le paquet du tour est mis à jour (il compte pour l'ouverture).
    final staged = [
      for (var i = 0; i < state.staged.length; i++)
        i == stagedIndex ? cards : state.staged[i],
    ];
    return next.copyWith(staged: staged);
  }
  if (state.turnOpenMin > 0 && _turnPoints(next) < state.turnOpenMin) {
    return state; // l'ouverture du tour ne tiendrait plus
  }
  return next;
}

/// Déplace une carte d'un paquet posé pendant le tour vers un autre paquet (#898).
/// Reprise puis pose : mêmes règles que [takeBackFromMeld] et [layOff]. Sans effet si refusé.
RamiState moveBetweenMelds(
  RamiState state,
  String cardId,
  String fromMeldId,
  String toMeldId,
) {
  if (fromMeldId == toMeldId) return state;
  final taken = takeBackFromMeld(state, cardId, fromMeldId);
  if (identical(taken, state)) return state;
  final placed = layOff(taken, cardId, toMeldId);
  return identical(placed, taken) ? state : placed;
}

/// Reprend un paquet entier posé pendant le tour, avec toutes ses cartes (#661).
RamiState takeBackMeld(RamiState state, String meldId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      state.firstTour ||
      !state.turnMeldIds.contains(meldId)) return state;
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (meldIndex < 0) return state;
  final meld = state.table[meldIndex];
  final table = [
    for (final item in state.table)
      if (item.id != meldId) item,
  ];
  var next = state.copyWith(
    table: table,
    turnMeldIds: [
      for (final id in state.turnMeldIds)
        if (id != meldId) id,
    ],
  );
  if (!state.opened[seat]) {
    final stagedIndex = _stagedGroupIndex(state, meldId);
    if (stagedIndex < 0) return state;
    final staged = [...state.staged]..removeAt(stagedIndex);
    next = next.copyWith(staged: staged);
  } else if (state.turnOpenMin > 0 && _turnPoints(next) < state.turnOpenMin) {
    return state; // l'ouverture du tour ne tiendrait plus
  }
  return _setHand(next, seat, [...state.hands[seat], ...meld.cards]);
}

/// Reprise d'un joker posé sur la table (#390) : la carte naturelle de la main
/// prend sa place dans le paquet, s'il reste valide ; le joker revient en main.
RamiState takeJoker(RamiState state, String cardId, String meldId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play ||
      state.firstTour ||
      !state.opened[seat] ||
      state.staged.isNotEmpty) return state;
  final hand = state.hands[seat];
  final cardIndex = hand.indexWhere((item) => item.id == cardId);
  final meldIndex = state.table.indexWhere((item) => item.id == meldId);
  if (cardIndex < 0 || meldIndex < 0) return state;
  final card = hand[cardIndex];
  if (card.isJoker) return state;
  final meld = state.table[meldIndex];
  final jokerIndex = meld.cards.indexWhere((item) => item.isJoker);
  if (jokerIndex < 0) return state;
  // Un brelan de 3 cartes (joker compris) garde son joker : on ne le reprend qu'à partir de 4 (#443).
  if (meld.cards.length < 4 && _isSet(meld.cards)) return state;
  final joker = meld.cards[jokerIndex];

  final replaced = [...meld.cards]..[jokerIndex] = card;
  final cards = arrangeMeld(replaced);
  if (!isValidMeld(cards)) return state;

  final table = [
    for (final item in state.table)
      item.id == meldId
          ? Meld(id: item.id, cards: cards, owner: item.owner)
          : item,
  ];
  final newHand = [
    for (final item in hand)
      if (item.id != cardId) item,
    joker,
  ];
  return _setHand(state.copyWith(table: table), seat, newHand);
}

RamiState discardCard(RamiState state, String cardId) {
  final seat = state.turn;
  if (state.phase != RamiPhase.play) return state;
  final hand = state.hands[seat];
  final index = hand.indexWhere((item) => item.id == cardId);
  if (index < 0) return state;
  final card = hand[index];
  // La carte prise à la défausse doit être posée ou remise : avant ouverture, on ne défausse
  // rien d'autre tant qu'elle est en main ; après ouverture, elle ne peut pas être défaussée
  // (sauf si c'est la dernière carte).
  final takenInHand =
      state.takenId != null && hand.any((item) => item.id == state.takenId);
  if (takenInHand &&
      hand.length > 1 &&
      (card.id == state.takenId || !state.opened[seat])) {
    return state;
  }

  final next = _setHand(
    state.copyWith(discard: [...state.discard, card], takenId: null),
    seat,
    hand.where((item) => item.id != cardId).toList(),
  );
  if (next.hands[seat].isEmpty) return _finish(next, seat);
  return next.copyWith(
    turn: nextSeat(seat),
    phase: RamiPhase.draw,
    firstTour: state.firstTour && seat != state.dealer,
    staged: const [],
    turnMeldIds: const [],
    turnOpenMin: 0,
  );
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

/// Plan jouable : une pose ne peut pas vider la main (#496). Si le plan couvre toute la main,
/// on retire sa dernière combinaison pour garder une carte à défausser.
List<List<RamiCard>> _usablePlan(List<RamiCard> hand, [String? firstId]) {
  final plan = _planMelds(hand, firstId);
  final covered = plan.fold<int>(0, (sum, cards) => sum + cards.length);
  if (plan.isEmpty || covered < hand.length) return plan;
  return plan.sublist(0, plan.length - 1);
}

List<List<RamiCard>> _planMelds(List<RamiCard> hand, [String? firstId]) {
  final sorted = sortedStable(
    [..._setCandidates(hand), ..._runCandidates(hand)],
    (a, b) => pointsOf(b) - pointsOf(a) != 0
        ? pointsOf(b) - pointsOf(a)
        : b.length - a.length,
  );
  // La carte prise à la défausse est placée en premier si elle doit être posée.
  bool carries(List<RamiCard> cards) =>
      firstId != null && cards.any((card) => card.id == firstId);
  final candidates = [
    ...sorted.where(carries),
    ...sorted.where((cards) => !carries(cards)),
  ];
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

/// Première combinaison de la table portant cet id (celle que layOff cible).
Meld? _firstWithId(List<Meld> table, String id) {
  for (final meld in table) {
    if (meld.id == id) return meld;
  }
  return null;
}

/// Id unique pour une nouvelle combinaison : première carte pas encore utilisée comme id (#450).
/// Un joker repris peut garder un id déjà utilisé sur la table : on ne le réutilise pas.
String _newMeldId(List<Meld> table, List<RamiCard> cards) {
  final used = {for (final meld in table) meld.id};
  for (final card in cards) {
    if (!used.contains(card.id)) return card.id;
  }
  var n = table.length;
  while (used.contains('meld-$n')) {
    n++;
  }
  return 'meld-$n';
}

({String cardId, String meldId})? _findLayOff(
  RamiState state,
  int seat,
  String? onlyCardId,
) {
  for (final card in state.hands[seat]) {
    if (onlyCardId != null && card.id != onlyCardId) continue;
    for (final meld in state.table) {
      // Même test que layOff (arrangeMeld), et seulement sur la combinaison que layOff retrouve par son id (#450).
      if (!identical(_firstWithId(state.table, meld.id), meld)) continue;
      if (isValidMeld(arrangeMeld(extendMeld(meld.cards, card))))
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

/// Défausses classées de la meilleure à la moins bonne (score croissant, ordre stable).
List<String> _rankDiscards(RamiState state, int seat, RamiAiLevel level) {
  final hand = state.hands[seat];
  final pool = hand.where((card) => card.id != state.takenId).toList();
  final options = pool.isNotEmpty ? pool : hand;

  double score(RamiCard card) {
    // Facile : évaluation simple, sans défausse ni notion de cartes utiles à la table (#281).
    if (level == RamiAiLevel.facile) return _keepValue(card, hand).toDouble();
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

  final scores = [for (final card in options) score(card)];
  // Tri stable : à score égal, l'ordre de la main est conservé.
  final order = List<int>.generate(options.length, (i) => i)
    ..sort((a, b) {
      final byScore = scores[a].compareTo(scores[b]);
      return byScore != 0 ? byScore : a.compareTo(b);
    });
  return [for (final i in order) options[i].id];
}

String _chooseDiscard(RamiState state, int seat, RamiAiLevel level) {
  return _rankDiscards(state, seat, level).first;
}

/// Seuil d'ouverture de l'IA : le facile ouvre plus tard que la règle (#281).
int _aiOpenMin(RamiState state, RamiAiLevel level) =>
    minOpening(state) + (level == RamiAiLevel.facile ? 15 : 0);

/// L'IA ne prend la carte de la défausse que si elle peut la poser ce tour, au seuil de son niveau.
/// Sinon elle resterait en main sans pouvoir être défaussée (blocage).
bool _aiCanUseTop(RamiState state, RamiCard top, RamiAiLevel level) {
  if (state.opened[state.turn]) return true;
  final hand = state.hands[state.turn];
  final plan = _usablePlan([...hand, top], top.id);
  final total = plan.fold<int>(0, (sum, cards) => sum + pointsOf(cards));
  return total >= _aiOpenMin(state, level);
}

/// Difficile (#304) : nombre de défausses candidates évaluées par simulation, et de parties simulées.
const int ramiMcCandidates = 3;
const int ramiMcRollouts = 4;
const int ramiMcHorizon = 60;

/// Simulation courte de la suite de la manche (coups moyens), puis valeur pour [seat] : plus bas = mieux.
double _rolloutValue(RamiState start, int seat, int seed) {
  var s = start;
  var x = seed;
  RandomDouble rnd = () {
    x = (x * 1103515245 + 12345) & 0x7fffffff;
    return x / 0x80000000;
  };
  for (var i = 0; i < ramiMcHorizon && s.phase != RamiPhase.end; i++) {
    final next = aiStep(s, RamiAiLevel.moyen, rnd);
    if (identical(next, s)) break;
    s = next;
  }
  final points = handPointsOf(s.hands[seat]).toDouble();
  if (s.phase == RamiPhase.end) {
    return s.roundResult?.winner == seat ? -50 : points;
  }
  return points + (s.opened[seat] ? 0 : 30);
}

/// Défausse du difficile : parmi les meilleures candidates, celle qui laisse la meilleure moyenne de simulations.
String _mcDiscard(RamiState state, int seat) {
  final ranked = _rankDiscards(state, seat, RamiAiLevel.difficile);
  final candidates = ranked.take(ramiMcCandidates);
  var best = candidates.first;
  var bestValue = double.infinity;
  var seedBase = state.round * 131 + seat * 17 + state.discard.length;
  for (final id in candidates) {
    final after = discardCard(state, id);
    if (identical(after, state)) continue;
    var total = 0.0;
    for (var k = 0; k < ramiMcRollouts; k++) {
      total += _rolloutValue(after, seat, seedBase + k * 7919 + 1);
    }
    if (total < bestValue) {
      bestValue = total;
      best = id;
    }
    seedBase += 1;
  }
  return best;
}

/// Défausse de l'IA. Ne doit jamais rester bloquée : si la carte choisie est refusée,
/// on remet d'abord la carte prise, puis on tente une autre carte légale.
RamiState _aiDiscard(RamiState state, int seat, RamiAiLevel level) {
  final pick = level == RamiAiLevel.difficile
      ? _mcDiscard(state, seat)
      : _chooseDiscard(state, seat, level);
  final chosen = discardCard(state, pick);
  if (!identical(chosen, state)) return chosen;
  if (state.takenId != null) {
    final returned = returnTaken(state);
    if (!identical(returned, state)) return returned;
  }
  for (final card in state.hands[seat]) {
    final other = discardCard(state, card.id);
    if (!identical(other, state)) return other;
  }
  return state;
}

/// Probabilité, pour le facile, de prendre la défausse quand elle est utile (#439).
const double ramiEasyDrawAccuracy = 0.8;

RamiState _aiDraw(RamiState state, RamiAiLevel level, RandomDouble random) {
  final seat = state.turn;
  if (state.discard.isEmpty) return drawStock(state, random);
  final top = state.discard.last;
  final hand = state.hands[seat];
  final improves = _planValue([...hand, top]) > _planValue(hand);
  final layable = state.opened[seat] &&
      state.table.any((meld) => isValidMeld([...meld.cards, top]));
  final useful = isJoker(top) || improves || layable;
  // Facile : prend une carte utile seulement dans la proportion ci-dessous, sans piocher au hasard (#439).
  final take = level == RamiAiLevel.facile
      ? useful && random() < ramiEasyDrawAccuracy
      : useful;
  if (take && canUseDiscardTop(state) && _aiCanUseTop(state, top, level)) {
    return drawDiscard(state);
  }
  return drawStock(state, random);
}

RamiState _poseAll(RamiState state, List<List<RamiCard>> plan) => plan.fold(
      state,
      (current, cards) =>
          poseMeld(current, [for (final card in cards) card.id]),
    );

/// Premier coup qui modifie l'état. Si aucun ne progresse, renvoie l'état tel quel.
RamiState _firstChange(RamiState state, List<RamiState Function()> moves) {
  for (final move in moves) {
    final next = move();
    if (!identical(next, state)) return next;
  }
  return state;
}

/// Une action atomique de l'IA (pioche, pose, ajout, défausse). Le contrôleur la rappelle tant que ce n'est pas son tour.
/// Ne se bloque jamais : si une action est refusée, l'IA tente la suivante, la défausse étant le dernier recours.
RamiState aiStep(RamiState state, RamiAiLevel level, [RandomDouble? random]) {
  final draw = random ?? _defaultRandom.nextDouble;
  if (state.phase == RamiPhase.draw) return _aiDraw(state, level, draw);
  if (state.phase != RamiPhase.play) return state;

  final seat = state.turn;
  if (state.firstTour) return _aiDiscard(state, seat, level);
  final plan = _usablePlan(state.hands[seat], state.takenId);
  final planTotal = plan.fold<int>(0, (sum, cards) => sum + pointsOf(cards));
  final openMin = _aiOpenMin(state, level);
  final taken = state.takenId;

  return _firstChange(state, [
    // Ouverture : pose tout le plan puis valide l'ouverture ; sinon on ne garde rien en attente.
    if (!state.opened[seat] && planTotal >= openMin)
      () {
        final posed = _poseAll(state, plan);
        return posed.opened[seat] ? posed : state;
      },
    if (state.opened[seat] && plan.isNotEmpty) () => _poseAll(state, plan),
    // La carte prise à la défausse doit être posée ce tour.
    if (state.opened[seat] && taken != null)
      () {
        final lay = _findLayOff(state, seat, taken);
        return lay == null ? state : layOff(state, lay.cardId, lay.meldId);
      },
    if (state.opened[seat])
      () {
        // Le facile pose toujours quand c'est légal : pas d'oubli volontaire (#281).
        final lay = _findLayOff(state, seat, null);
        return lay == null ? state : layOff(state, lay.cardId, lay.meldId);
      },
    () => _aiDiscard(state, seat, level),
  ]);
}
