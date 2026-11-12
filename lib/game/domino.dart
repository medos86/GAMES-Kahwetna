// Portage de src/app/game/domino.ts.
// Mêmes fonctions, même ordre des opérations, mêmes valeurs de retour.
// Une action refusée renvoie l'instance reçue (identical), comme le source.

import 'dart:math' as math;

import 'common.dart';

enum DominoSide { left, right }

class DominoTile {
  const DominoTile({required this.id, required this.a, required this.b});

  final String id;
  final int a;
  final int b;

  factory DominoTile.fromJson(Map<String, dynamic> json) => DominoTile(
        id: json['id'] as String,
        a: intFromJson(json['a']),
        b: intFromJson(json['b']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'a': a, 'b': b};

  @override
  bool operator ==(Object other) => other is DominoTile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Domino posé : orientation dans la chaîne.
class PlacedTile extends DominoTile {
  const PlacedTile({
    required super.id,
    required super.a,
    required super.b,
    required this.left,
    required this.right,
  });

  final int left;
  final int right;

  factory PlacedTile.fromJson(Map<String, dynamic> json) => PlacedTile(
        id: json['id'] as String,
        a: intFromJson(json['a']),
        b: intFromJson(json['b']),
        left: intFromJson(json['left']),
        right: intFromJson(json['right']),
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'left': left,
        'right': right,
      };
}

const Object _unset = Object();

class DominoState {
  const DominoState({
    required this.hands,
    required this.boneyard,
    required this.chain,
    required this.leftEnd,
    required this.rightEnd,
    required this.scores,
    required this.turn,
    required this.consecutivePasses,
    required this.roundWinner,
    required this.matchWinner,
    required this.pointsAwarded,
    required this.targetScore,
    required this.round,
  });

  final Map<Player, List<DominoTile>> hands;
  final List<DominoTile> boneyard;
  final List<PlacedTile> chain;
  final int? leftEnd;
  final int? rightEnd;
  final Map<Player, int> scores;
  final Player turn;
  final int consecutivePasses;
  final Player? roundWinner;
  final Player? matchWinner;
  final int pointsAwarded;
  final int targetScore;
  final int round;

  /// Relit un état produit par [toJson] (ou par `JSON.stringify(state)` côté TypeScript).
  factory DominoState.fromJson(Map<String, dynamic> json) {
    List<DominoTile> tiles(Object? raw) => [
          for (final t in raw as List<dynamic>)
            DominoTile.fromJson(t as Map<String, dynamic>),
        ];
    final hands = json['hands'] as Map<String, dynamic>;
    final scores = json['scores'] as Map<String, dynamic>;
    return DominoState(
      hands: {for (final p in Player.values) p: tiles(hands[p.name])},
      boneyard: tiles(json['boneyard']),
      chain: [
        for (final t in json['chain'] as List<dynamic>)
          PlacedTile.fromJson(t as Map<String, dynamic>),
      ],
      leftEnd: json['leftEnd'] == null ? null : intFromJson(json['leftEnd']),
      rightEnd: json['rightEnd'] == null ? null : intFromJson(json['rightEnd']),
      scores: {for (final p in Player.values) p: intFromJson(scores[p.name])},
      turn: Player.values.byName(json['turn'] as String),
      consecutivePasses: intFromJson(json['consecutivePasses']),
      roundWinner: playerFromJson(json['roundWinner']),
      matchWinner: playerFromJson(json['matchWinner']),
      pointsAwarded: intFromJson(json['pointsAwarded']),
      targetScore: intFromJson(json['targetScore']),
      round: intFromJson(json['round']),
    );
  }

  /// Les champs nullables utilisent le motif sentinelle : passer `null` les remet à null.
  DominoState copyWith({
    Map<Player, List<DominoTile>>? hands,
    List<DominoTile>? boneyard,
    List<PlacedTile>? chain,
    Object? leftEnd = _unset,
    Object? rightEnd = _unset,
    Map<Player, int>? scores,
    Player? turn,
    int? consecutivePasses,
    Object? roundWinner = _unset,
    Object? matchWinner = _unset,
    int? pointsAwarded,
  }) {
    return DominoState(
      hands: hands ?? this.hands,
      boneyard: boneyard ?? this.boneyard,
      chain: chain ?? this.chain,
      leftEnd: identical(leftEnd, _unset) ? this.leftEnd : leftEnd as int?,
      rightEnd: identical(rightEnd, _unset) ? this.rightEnd : rightEnd as int?,
      scores: scores ?? this.scores,
      turn: turn ?? this.turn,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      roundWinner: identical(roundWinner, _unset)
          ? this.roundWinner
          : roundWinner as Player?,
      matchWinner: identical(matchWinner, _unset)
          ? this.matchWinner
          : matchWinner as Player?,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      targetScore: targetScore,
      round: round,
    );
  }

  /// Même structure et mêmes clés que JSON.stringify(state) côté TypeScript.
  Map<String, dynamic> toJson() => {
        'hands': {
          for (final p in Player.values)
            p.name: [for (final t in hands[p]!) t.toJson()],
        },
        'boneyard': [for (final t in boneyard) t.toJson()],
        'chain': [for (final t in chain) t.toJson()],
        'leftEnd': leftEnd,
        'rightEnd': rightEnd,
        'scores': {for (final p in Player.values) p.name: scores[p]},
        'turn': turn.name,
        'consecutivePasses': consecutivePasses,
        'roundWinner': roundWinner?.name,
        'matchWinner': matchWinner?.name,
        'pointsAwarded': pointsAwarded,
        'targetScore': targetScore,
        'round': round,
      };
}

List<DominoTile> _shuffledTiles(RandomDouble random) {
  final tiles = <DominoTile>[];
  for (var a = 0; a <= 6; a += 1) {
    for (var b = a; b <= 6; b += 1) {
      tiles.add(DominoTile(id: '$a-$b', a: a, b: b));
    }
  }
  for (var index = tiles.length - 1; index > 0; index -= 1) {
    final swap = (random() * (index + 1)).floor();
    final tmp = tiles[index];
    tiles[index] = tiles[swap];
    tiles[swap] = tmp;
  }
  return tiles;
}

DominoState newDominoRound({
  required int targetScore,
  Map<Player, int>? scores,
  int round = 1,
  Player starter = Player.player,
  RandomDouble? random,
}) {
  final tiles = _shuffledTiles(random ?? math.Random().nextDouble);
  return DominoState(
    hands: {
      Player.player: tiles.sublist(0, 7),
      Player.opponent: tiles.sublist(7, 14),
    },
    boneyard: tiles.sublist(14),
    chain: const [],
    leftEnd: null,
    rightEnd: null,
    scores: scores ?? {Player.player: 0, Player.opponent: 0},
    turn: starter,
    consecutivePasses: 0,
    roundWinner: null,
    matchWinner: null,
    pointsAwarded: 0,
    targetScore: targetScore,
    round: round,
  );
}

bool canPlace(DominoTile tile, DominoState state, DominoSide side) {
  if (state.chain.isEmpty) return true;
  final end = side == DominoSide.left ? state.leftEnd : state.rightEnd;
  return tile.a == end || tile.b == end;
}

List<DominoTile> playableTiles(DominoState state, Player player) {
  return [
    for (final tile in state.hands[player]!)
      if (state.chain.isEmpty ||
          canPlace(tile, state, DominoSide.left) ||
          canPlace(tile, state, DominoSide.right))
        tile,
  ];
}

DominoState _finishRound(DominoState state, Player winner, int points) {
  final scores = {...state.scores, winner: state.scores[winner]! + points};
  return state.copyWith(
    scores: scores,
    roundWinner: winner,
    matchWinner: scores[winner]! >= state.targetScore ? winner : null,
    pointsAwarded: points,
  );
}

DominoTile? _tileById(List<DominoTile> tiles, String id) {
  for (final tile in tiles) {
    if (tile.id == id) return tile;
  }
  return null;
}

DominoState playDomino(
  DominoState state,
  Player player,
  String tileId,
  DominoSide side,
) {
  if (state.turn != player ||
      state.roundWinner != null ||
      state.matchWinner != null) {
    return state;
  }
  final tile = _tileById(state.hands[player]!, tileId);
  if (tile == null || !canPlace(tile, state, side)) return state;

  final PlacedTile placed;
  int? leftEnd = state.leftEnd;
  int? rightEnd = state.rightEnd;
  if (state.chain.isEmpty) {
    placed = PlacedTile(
      id: tile.id,
      a: tile.a,
      b: tile.b,
      left: tile.a,
      right: tile.b,
    );
    leftEnd = tile.a;
    rightEnd = tile.b;
  } else if (side == DominoSide.left) {
    final left = tile.a == state.leftEnd ? tile.b : tile.a;
    placed = PlacedTile(
      id: tile.id,
      a: tile.a,
      b: tile.b,
      left: left,
      right: left == tile.a ? tile.b : tile.a,
    );
    leftEnd = left;
  } else {
    final right = tile.a == state.rightEnd ? tile.b : tile.a;
    placed = PlacedTile(
      id: tile.id,
      a: tile.a,
      b: tile.b,
      left: right == tile.a ? tile.b : tile.a,
      right: right,
    );
    rightEnd = right;
  }

  final hands = Map<Player, List<DominoTile>>.from(state.hands);
  hands[player] = [
    for (final candidate in state.hands[player]!)
      if (candidate.id != tile.id) candidate,
  ];
  final chain = side == DominoSide.left && state.chain.isNotEmpty
      ? [placed, ...state.chain]
      : [...state.chain, placed];
  final next = state.copyWith(
    hands: hands,
    chain: chain,
    leftEnd: leftEnd,
    rightEnd: rightEnd,
    turn: other(player),
    consecutivePasses: 0,
  );
  if (hands[player]!.isEmpty) {
    final points = hands[other(player)]!.fold<int>(
      0,
      (sum, item) => sum + item.a + item.b,
    );
    return _finishRound(next, player, points);
  }
  return next;
}

DominoState drawDomino(DominoState state, Player player) {
  if (state.turn != player ||
      state.roundWinner != null ||
      state.matchWinner != null ||
      state.boneyard.isEmpty) {
    return state;
  }
  final tile = state.boneyard.first;
  final hands = Map<Player, List<DominoTile>>.from(state.hands);
  hands[player] = [...state.hands[player]!, tile];
  return state.copyWith(hands: hands, boneyard: state.boneyard.sublist(1));
}

int _handTotal(List<DominoTile> hand) =>
    hand.fold<int>(0, (sum, tile) => sum + tile.a + tile.b);

DominoState passDomino(DominoState state, Player player) {
  if (state.turn != player ||
      state.roundWinner != null ||
      state.matchWinner != null) {
    return state;
  }
  final consecutivePasses = state.consecutivePasses + 1;
  final next = state.copyWith(
    turn: other(player),
    consecutivePasses: consecutivePasses,
  );
  if (consecutivePasses < 2) return next;

  final playerTotal = _handTotal(state.hands[Player.player]!);
  final opponentTotal = _handTotal(state.hands[Player.opponent]!);
  // Égalité : victoire du joueur sans point, comme le source.
  if (playerTotal == opponentTotal) {
    return next.copyWith(roundWinner: Player.player, pointsAwarded: 0);
  }
  final winner = playerTotal < opponentTotal ? Player.player : Player.opponent;
  return _finishRound(next, winner, (playerTotal - opponentTotal).abs());
}
