// Règles de la Chkobba, reprises de src/app/game/chkobba.ts.
// Dart pur : aucun import Flutter dans lib/game/.

import 'dart:math' as math;

import 'common.dart';

enum ChkobbaSuit { deniers, coupes, epees, batons }

/// Niveau de l'IA (même valeurs que Difficulty côté interface).
enum ChkobbaAiLevel { facile, moyen, difficile }

class ChkobbaCard {
  const ChkobbaCard({required this.suit, required this.rank, required this.id});

  final ChkobbaSuit suit;
  final int rank;
  final String id;

  factory ChkobbaCard.fromJson(Map<String, dynamic> json) => ChkobbaCard(
        suit: ChkobbaSuit.values.byName(json['suit'] as String),
        rank: intFromJson(json['rank']),
        id: json['id'] as String,
      );

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank, 'id': id};

  bool get isHaya => suit == ChkobbaSuit.deniers && rank == 7;

  @override
  bool operator ==(Object other) => other is ChkobbaCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$rank ${suit.name}';
}

class ChkobbaState {
  const ChkobbaState({
    required this.targetScore,
    required this.deck,
    required this.hands,
    required this.table,
    required this.won,
    required this.chkobbas,
    required this.scores,
    required this.lastCapturer,
    required this.turn,
    required this.starter,
    required this.round,
    required this.winner,
  });

  final int targetScore;
  final List<ChkobbaCard> deck;
  final Map<Player, List<ChkobbaCard>> hands;
  final List<ChkobbaCard> table;
  final Map<Player, List<ChkobbaCard>> won;
  final Map<Player, int> chkobbas;
  final Map<Player, int> scores;
  final Player? lastCapturer;
  final Player turn;
  final Player starter;
  final int round;
  final Player? winner;

  /// Relit un état produit par [toJson] (mêmes clés que les champs du source TypeScript).
  factory ChkobbaState.fromJson(Map<String, dynamic> json) {
    List<ChkobbaCard> cards(Object? raw) =>
        [for (final c in raw as List<dynamic>) ChkobbaCard.fromJson(c as Map<String, dynamic>)];
    final hands = json['hands'] as Map<String, dynamic>;
    final won = json['won'] as Map<String, dynamic>;
    final chkobbas = json['chkobbas'] as Map<String, dynamic>;
    final scores = json['scores'] as Map<String, dynamic>;
    return ChkobbaState(
      targetScore: intFromJson(json['targetScore']),
      deck: cards(json['deck']),
      hands: {for (final p in Player.values) p: cards(hands[p.name])},
      table: cards(json['table']),
      won: {for (final p in Player.values) p: cards(won[p.name])},
      chkobbas: {for (final p in Player.values) p: intFromJson(chkobbas[p.name])},
      scores: {for (final p in Player.values) p: intFromJson(scores[p.name])},
      lastCapturer: playerFromJson(json['lastCapturer']),
      turn: Player.values.byName(json['turn'] as String),
      starter: Player.values.byName(json['starter'] as String),
      round: intFromJson(json['round']),
      winner: playerFromJson(json['winner']),
    );
  }

  Map<String, dynamic> toJson() => {
        'targetScore': targetScore,
        'deck': [for (final c in deck) c.toJson()],
        'hands': {for (final p in Player.values) p.name: [for (final c in hands[p]!) c.toJson()]},
        'table': [for (final c in table) c.toJson()],
        'won': {for (final p in Player.values) p.name: [for (final c in won[p]!) c.toJson()]},
        'chkobbas': {for (final p in Player.values) p.name: chkobbas[p]},
        'scores': {for (final p in Player.values) p.name: scores[p]},
        'lastCapturer': lastCapturer?.name,
        'turn': turn.name,
        'starter': starter.name,
        'round': round,
        'winner': winner?.name,
      };

  ChkobbaState copyWith({
    List<ChkobbaCard>? deck,
    Map<Player, List<ChkobbaCard>>? hands,
    List<ChkobbaCard>? table,
    Map<Player, List<ChkobbaCard>>? won,
    Map<Player, int>? chkobbas,
    Map<Player, int>? scores,
    Player? lastCapturer,
    Player? turn,
    Player? winner,
  }) {
    return ChkobbaState(
      targetScore: targetScore,
      deck: deck ?? this.deck,
      hands: hands ?? this.hands,
      table: table ?? this.table,
      won: won ?? this.won,
      chkobbas: chkobbas ?? this.chkobbas,
      scores: scores ?? this.scores,
      lastCapturer: lastCapturer ?? this.lastCapturer,
      turn: turn ?? this.turn,
      starter: starter,
      round: round,
      winner: winner ?? this.winner,
    );
  }
}

class ChkobbaMoveResult {
  const ChkobbaMoveResult({
    required this.state,
    required this.captured,
    required this.chkobba,
    required this.haya,
  });

  final ChkobbaState state;
  final List<ChkobbaCard> captured;
  final bool chkobba;
  final bool haya;
}

class RoundPoint {
  const RoundPoint(this.label, this.value);

  final String label;
  final int value;
}

class ChkobbaRoundScore {
  const ChkobbaRoundScore({required this.state, required this.points});

  final ChkobbaState state;
  final Map<Player, List<RoundPoint>> points;
}

const int chkobbaDefaultTarget = 11;

final _defaultRandom = math.Random();

List<ChkobbaCard> _createDeck(RandomDouble random) {
  final deck = <ChkobbaCard>[
    for (final suit in ChkobbaSuit.values)
      for (var rank = 1; rank <= 10; rank++)
        ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank'),
  ];
  for (var i = deck.length - 1; i > 0; i--) {
    final j = (random() * (i + 1)).floor();
    final tmp = deck[i];
    deck[i] = deck[j];
    deck[j] = tmp;
  }
  return deck;
}

ChkobbaState dealRound({
  required Map<Player, int> scores,
  required Player starter,
  required int round,
  int targetScore = chkobbaDefaultTarget,
  RandomDouble? random,
}) {
  final deck = _createDeck(random ?? _defaultRandom.nextDouble);
  return ChkobbaState(
    targetScore: targetScore,
    deck: deck.skip(10).toList(),
    hands: {
      Player.player: deck.take(3).toList(),
      Player.opponent: deck.skip(3).take(3).toList(),
    },
    table: deck.skip(6).take(4).toList(),
    won: {Player.player: [], Player.opponent: []},
    chkobbas: {Player.player: 0, Player.opponent: 0},
    scores: scores,
    lastCapturer: null,
    turn: starter,
    starter: starter,
    round: round,
    winner: null,
  );
}

ChkobbaState newMatch({int targetScore = chkobbaDefaultTarget, RandomDouble? random}) => dealRound(
      scores: {Player.player: 0, Player.opponent: 0},
      starter: Player.player,
      round: 1,
      targetScore: targetScore,
      random: random,
    );

/// Donne fixe pour vérifier le dialogue de choix de prise (issue #29, équivalent de `?demo=choice` du React).
/// Le joueur a 7 d'épées, 10 de bâtons et 9 de coupes ; le tapis est 3 d'épées, 4 de bâtons, 2 de coupes,
/// 5 de deniers, 1 d'épées et 6 de coupes. Les cartes de l'adversaire ne sont pas précisées par la source :
/// ici 1, 8 et 9 de deniers. Utilisé uniquement en mode debug.
ChkobbaState chkobbaDemoChoiceState({int targetScore = chkobbaDefaultTarget}) {
  const playerHand = [
    ChkobbaCard(suit: ChkobbaSuit.epees, rank: 7, id: 'epees-7'),
    ChkobbaCard(suit: ChkobbaSuit.batons, rank: 10, id: 'batons-10'),
    ChkobbaCard(suit: ChkobbaSuit.coupes, rank: 9, id: 'coupes-9'),
  ];
  const opponentHand = [
    ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 1, id: 'deniers-1'),
    ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 8, id: 'deniers-8'),
    ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 9, id: 'deniers-9'),
  ];
  const table = [
    ChkobbaCard(suit: ChkobbaSuit.epees, rank: 3, id: 'epees-3'),
    ChkobbaCard(suit: ChkobbaSuit.batons, rank: 4, id: 'batons-4'),
    ChkobbaCard(suit: ChkobbaSuit.coupes, rank: 2, id: 'coupes-2'),
    ChkobbaCard(suit: ChkobbaSuit.deniers, rank: 5, id: 'deniers-5'),
    ChkobbaCard(suit: ChkobbaSuit.epees, rank: 1, id: 'epees-1'),
    ChkobbaCard(suit: ChkobbaSuit.coupes, rank: 6, id: 'coupes-6'),
  ];
  final used = {...playerHand, ...opponentHand, ...table}.map((c) => c.id).toSet();
  final deck = [
    for (final suit in ChkobbaSuit.values)
      for (var rank = 1; rank <= 10; rank++)
        if (!used.contains('${suit.name}-$rank')) ChkobbaCard(suit: suit, rank: rank, id: '${suit.name}-$rank'),
  ];
  return ChkobbaState(
    targetScore: targetScore,
    deck: deck,
    hands: {Player.player: playerHand, Player.opponent: opponentHand},
    table: table,
    won: {Player.player: [], Player.opponent: []},
    chkobbas: {Player.player: 0, Player.opponent: 0},
    scores: {Player.player: 0, Player.opponent: 0},
    lastCapturer: null,
    turn: Player.player,
    starter: Player.player,
    round: 1,
    winner: null,
  );
}

/// Distribue les 6 cartes suivantes du paquet (si la distribution n'a pas tout donné).
ChkobbaState dealHands(ChkobbaState state) => state.copyWith(
      deck: state.deck.skip(6).toList(),
      hands: {
        Player.player: state.deck.take(3).toList(),
        Player.opponent: state.deck.skip(3).take(3).toList(),
      },
    );

// Une carte de même valeur sur la table se prend seule, avant toute combinaison de somme.
List<List<ChkobbaCard>> _captureOptions(List<ChkobbaCard> table, int rank) {
  final same = table.where((c) => c.rank == rank).toList();
  if (same.isNotEmpty) return [for (final c in same) [c]];

  final options = <List<ChkobbaCard>>[];
  void search(int index, int total, List<ChkobbaCard> current) {
    if (total == rank) {
      options.add(current);
      return;
    }
    if (total > rank || index >= table.length) return;
    search(index + 1, total + table[index].rank, [...current, table[index]]);
    search(index + 1, total, current);
  }

  search(0, 0, []);
  return options;
}

int _cardsValue(List<ChkobbaCard> cards) {
  var sum = 0;
  for (final c in cards) {
    sum += 1 +
        (c.suit == ChkobbaSuit.deniers ? 1 : 0) +
        (c.rank == 7 ? 2 : c.rank == 6 ? 1 : 0) +
        (c.isHaya ? 10 : 0);
  }
  return sum;
}

List<ChkobbaCard> _bestCapture(List<ChkobbaCard> table, int rank) {
  int score(List<ChkobbaCard> o) => _cardsValue(o) + (o.length == table.length ? 20 : 0);
  var best = <ChkobbaCard>[];
  for (final o in _captureOptions(table, rank)) {
    if (score(o) > score(best)) best = o;
  }
  return best;
}

ChkobbaCard? _findCard(List<ChkobbaCard> cards, String id) {
  for (final c in cards) {
    if (c.id == id) return c;
  }
  return null;
}

/// Toutes les prises possibles pour la carte donnée (vide si la carte n'est pas en main).
List<List<ChkobbaCard>> getCaptureOptions(ChkobbaState state, Player who, String cardId) {
  final card = _findCard(state.hands[who]!, cardId);
  return card == null ? [] : _captureOptions(state.table, card.rank);
}

/// Joue une carte. `chosenIds` choisit une des prises légales ; sinon la meilleure est prise.
ChkobbaMoveResult playCard(
  ChkobbaState state,
  Player who,
  String cardId, {
  List<String>? chosenIds,
  bool discardOnly = false,
}) {
  final card = _findCard(state.hands[who]!, cardId);
  if (card == null) {
    return ChkobbaMoveResult(state: state, captured: const [], chkobba: false, haya: false);
  }

  final hands = {
    ...state.hands,
    who: state.hands[who]!.where((c) => c.id != cardId).toList(),
  };

  List<ChkobbaCard>? chosen;
  if (chosenIds != null) {
    for (final o in _captureOptions(state.table, card.rank)) {
      if (o.length == chosenIds.length && o.every((c) => chosenIds.contains(c.id))) {
        chosen = o;
        break;
      }
    }
  }
  // discardOnly : l'adversaire facile pose sa carte sans prendre, même quand il le pourrait.
  final captured = discardOnly ? <ChkobbaCard>[] : (chosen ?? _bestCapture(state.table, card.rank));

  if (captured.isEmpty) {
    return ChkobbaMoveResult(
      state: state.copyWith(
        hands: hands,
        table: [...state.table, card],
        turn: other(who),
      ),
      captured: captured,
      chkobba: false,
      haya: false,
    );
  }

  final capturedIds = captured.map((c) => c.id).toSet();
  final table = state.table.where((c) => !capturedIds.contains(c.id)).toList();
  final isLastPlay = state.deck.isEmpty &&
      hands[Player.player]!.isEmpty &&
      hands[Player.opponent]!.isEmpty;
  // Un ramassage fait avec la toute dernière carte de la manche ne compte pas.
  final chkobba = table.isEmpty && !isLastPlay;

  return ChkobbaMoveResult(
    state: state.copyWith(
      hands: hands,
      table: table,
      won: {
        ...state.won,
        who: [...state.won[who]!, ...captured, card],
      },
      chkobbas: chkobba
          ? {...state.chkobbas, who: state.chkobbas[who]! + 1}
          : state.chkobbas,
      lastCapturer: who,
      turn: other(who),
    ),
    captured: captured,
    chkobba: chkobba,
    haya: card.isHaya || captured.any((c) => c.isHaya),
  );
}

/// Fin de manche : la table revient au dernier qui a ramassé, puis les points sont comptés.
ChkobbaRoundScore scoreRound(ChkobbaState state) {
  final won = {
    for (final p in Player.values) p: [...state.won[p]!],
  };
  if (state.lastCapturer != null && state.table.isNotEmpty) {
    final lc = state.lastCapturer!;
    won[lc] = [...won[lc]!, ...state.table];
  }

  final points = <Player, List<RoundPoint>>{
    Player.player: [],
    Player.opponent: [],
  };

  // Compare les deux joueurs ; le gagnant prend 1 point. Renvoie true si l'égalité est rompue.
  bool majority(String label, int Function(List<ChkobbaCard>) count) {
    final p = count(won[Player.player]!);
    final o = count(won[Player.opponent]!);
    if (p != o) {
      points[p > o ? Player.player : Player.opponent]!.add(RoundPoint(label, 1));
    }
    return p != o;
  }

  for (final p in [Player.player, Player.opponent]) {
    final n = state.chkobbas[p]!;
    if (n > 0) points[p]!.add(RoundPoint('Chkobba ×$n', n));
    if (won[p]!.any((c) => c.isHaya)) points[p]!.add(const RoundPoint('Haya (7♦)', 1));
  }
  majority('Cartes', (cards) => cards.length);
  majority('Deniers', (cards) => cards.where((c) => c.suit == ChkobbaSuit.deniers).length);
  if (!majority('Bermila', (cards) => cards.where((c) => c.rank == 7).length)) {
    majority('Bermila', (cards) => cards.where((c) => c.rank == 6).length);
  }

  int total(Player p) => points[p]!.fold(0, (sum, x) => sum + x.value);
  final scores = {
    Player.player: state.scores[Player.player]! + total(Player.player),
    Player.opponent: state.scores[Player.opponent]! + total(Player.opponent),
  };
  final sp = scores[Player.player]!;
  final so = scores[Player.opponent]!;
  final reached = sp >= state.targetScore || so >= state.targetScore;
  final Player? winner =
      reached && sp != so ? (sp > so ? Player.player : Player.opponent) : null;

  return ChkobbaRoundScore(
    state: state.copyWith(won: won, table: [], scores: scores, winner: winner),
    points: points,
  );
}

/// Gain d'un coup de `card` sur `table` (prise la meilleure, comme playCard), et table qui en résulte.
/// `priority` ajoute la priorité aux points de fin de manche (moyen et difficile).
({int score, List<ChkobbaCard> table}) _simulateMove(
  List<ChkobbaCard> table,
  ChkobbaCard card, {
  bool priority = false,
}) {
  final captured = _bestCapture(table, card.rank);
  if (captured.isEmpty) {
    return (score: -_cardsValue([card]), table: [...table, card]);
  }
  final remaining = table.where((c) => !captured.contains(c)).toList();
  var score = 100 + _cardsValue([...captured, card]) + (remaining.isEmpty ? 50 : 0);
  if (priority) score += _pointsPriority(captured);
  return (score: score, table: remaining);
}

/// Carreaux pris (points de fin de manche), et surtout le 7 de carreau (haya).
int _pointsPriority(List<ChkobbaCard> captured) {
  var bonus = 0;
  for (final c in captured) {
    if (c.suit == ChkobbaSuit.deniers) bonus += 3;
    if (c.suit == ChkobbaSuit.deniers && c.rank == 7) bonus += 8;
  }
  return bonus;
}

/// Décision de l'adversaire : la carte jouée, et s'il prend une prise quand il en a une.
typedef ChkobbaAiMove = ({String cardId, bool capture});

/// Coup de l'adversaire selon le niveau.
/// - Facile : carte au hasard ; quand une prise existe, il ne la prend qu'environ 60 % du temps.
/// - Moyen : évaluation gloutonne, avec priorité aux carreaux.
/// - Difficile : deux coups d'avance, en lisant la main du joueur (choix assumé).
ChkobbaAiMove chooseOpponentMove(
  ChkobbaState state,
  ChkobbaAiLevel level, {
  RandomDouble? random,
}) {
  final r = random ?? _defaultRandom.nextDouble;
  final hand = state.hands[Player.opponent]!;

  if (level == ChkobbaAiLevel.facile) {
    final card = hand[(r() * hand.length).floor()];
    final canCapture = _captureOptions(state.table, card.rank).isNotEmpty;
    final capture = !canCapture || r() >= 0.4;
    return (cardId: card.id, capture: capture);
  }

  if (level == ChkobbaAiLevel.moyen) {
    var best = hand.first;
    for (final card in hand.skip(1)) {
      if (_simulateMove(state.table, card, priority: true).score >
          _simulateMove(state.table, best, priority: true).score) {
        best = card;
      }
    }
    return (cardId: best.id, capture: true);
  }

  // Difficile : pour chaque carte, on retranche le meilleur coup que le joueur peut faire ensuite
  // sur la table qui en résulte. Une table que le joueur ramasse d'un coup coûte donc cher.
  final playerHand = state.hands[Player.player]!;
  var bestCard = hand.first;
  var bestTotal = 0;
  var first = true;
  for (final card in hand) {
    final mine = _simulateMove(state.table, card, priority: true);
    var reply = 0;
    if (playerHand.isNotEmpty) {
      reply = playerHand.map((c) => _simulateMove(mine.table, c).score).reduce((a, b) => a > b ? a : b);
    }
    final total = mine.score - reply;
    if (first || total > bestTotal) {
      bestCard = card;
      bestTotal = total;
      first = false;
    }
  }
  return (cardId: bestCard.id, capture: true);
}

/// Carte jouée par l'adversaire (voir chooseOpponentMove).
String chooseOpponentCard(
  ChkobbaState state,
  ChkobbaAiLevel level, {
  RandomDouble? random,
}) =>
    chooseOpponentMove(state, level, random: random).cardId;
