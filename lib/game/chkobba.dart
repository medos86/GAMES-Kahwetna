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
ChkobbaMoveResult playCard(ChkobbaState state, Player who, String cardId, {List<String>? chosenIds}) {
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
  final captured = chosen ?? _bestCapture(state.table, card.rank);

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

int _evaluateMove(ChkobbaState state, ChkobbaCard card, ChkobbaAiLevel level) {
  final captured = _bestCapture(state.table, card.rank);
  int tableSum(List<ChkobbaCard> cards) => cards.fold(0, (sum, c) => sum + c.rank);

  if (captured.isNotEmpty) {
    final remaining = state.table.where((c) => !captured.contains(c)).toList();
    var score = 100 + _cardsValue([...captured, card]) + (remaining.isEmpty ? 50 : 0);
    // Laisser une table valant 10 ou moins permet à l'adversaire de la ramasser d'un coup.
    if (level == ChkobbaAiLevel.difficile && remaining.isNotEmpty && tableSum(remaining) <= 10) {
      score -= 4;
    }
    return score;
  }

  var score = -_cardsValue([card]);
  if (level == ChkobbaAiLevel.difficile && tableSum([...state.table, card]) <= 10) score -= 4;
  return score;
}

/// Carte jouée par l'adversaire : au hasard en facile, sinon la mieux évaluée.
String chooseOpponentCard(
  ChkobbaState state,
  ChkobbaAiLevel level, {
  RandomDouble? random,
}) {
  final hand = state.hands[Player.opponent]!;
  if (level == ChkobbaAiLevel.facile) {
    final r = random ?? _defaultRandom.nextDouble;
    return hand[(r() * hand.length).floor()].id;
  }

  var best = hand.first;
  for (final card in hand.skip(1)) {
    if (_evaluateMove(state, card, level) > _evaluateMove(state, best, level)) best = card;
  }
  return best.id;
}
