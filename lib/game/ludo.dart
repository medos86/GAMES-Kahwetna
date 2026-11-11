// Portage de src/app/game/ludo.ts (guide §5.4).
// Dart pur : aucun import Flutter dans lib/game/.
// Mêmes fonctions, même ordre des opérations, mêmes valeurs de retour.
// Une action refusée renvoie l'instance reçue (identical), comme le source.

import 'dart:math' as math;

import 'common.dart';

/// Couleurs dans l'ordre des tours (sens horaire autour du plateau).
enum LudoColor { red, green, yellow, blue }

enum LudoPhase { roll, move, end }

/// Niveau de l'IA (mêmes valeurs que Difficulty côté interface).
enum LudoAiLevel { facile, moyen, difficile }

/// Progression : 0 = base, 1..51 = piste, 52..56 = colonne d'arrivée, 57 = centre.
const ludoFinish = 57;
const ludoTrackLength = 52;

class Cell {
  const Cell(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) => other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row, $col)';
}

const ludoGoal = Cell(7, 7);

/// Piste extérieure de 52 cases, indexée dans le sens des tours (coordonnées du source).
const ludoTrack = <Cell>[
  Cell(6, 0), Cell(6, 1), Cell(6, 2), Cell(6, 3), Cell(6, 4), Cell(6, 5),
  Cell(5, 6), Cell(4, 6), Cell(3, 6), Cell(2, 6), Cell(1, 6), Cell(0, 6),
  Cell(0, 7),
  Cell(0, 8), Cell(1, 8), Cell(2, 8), Cell(3, 8), Cell(4, 8), Cell(5, 8),
  Cell(6, 9), Cell(6, 10), Cell(6, 11), Cell(6, 12), Cell(6, 13), Cell(6, 14),
  Cell(7, 14),
  Cell(8, 14), Cell(8, 13), Cell(8, 12), Cell(8, 11), Cell(8, 10), Cell(8, 9),
  Cell(9, 8), Cell(10, 8), Cell(11, 8), Cell(12, 8), Cell(13, 8), Cell(14, 8),
  Cell(14, 7),
  Cell(14, 6), Cell(13, 6), Cell(12, 6), Cell(11, 6), Cell(10, 6), Cell(9, 6),
  Cell(8, 5), Cell(8, 4), Cell(8, 3), Cell(8, 2), Cell(8, 1), Cell(8, 0),
  Cell(7, 0),
];

/// Indice de la case de départ de chaque couleur sur la piste.
int ludoStartIndex(LudoColor color) => switch (color) {
      LudoColor.red => 1,
      LudoColor.green => 14,
      LudoColor.yellow => 27,
      LudoColor.blue => 40,
    };

/// Cases de départ et étoiles (+8) : aucune capture possible.
final Set<int> ludoSafeIndexes = {
  for (final color in LudoColor.values) ludoStartIndex(color),
  for (final color in LudoColor.values) (ludoStartIndex(color) + 8) % ludoTrackLength,
};

/// Colonne d'arrivée de chaque couleur (progressions 52..56).
List<Cell> ludoHomeColumn(LudoColor color) => switch (color) {
      LudoColor.red => const [Cell(7, 1), Cell(7, 2), Cell(7, 3), Cell(7, 4), Cell(7, 5)],
      LudoColor.green => const [Cell(1, 7), Cell(2, 7), Cell(3, 7), Cell(4, 7), Cell(5, 7)],
      LudoColor.yellow => const [Cell(7, 13), Cell(7, 12), Cell(7, 11), Cell(7, 10), Cell(7, 9)],
      LudoColor.blue => const [Cell(13, 7), Cell(12, 7), Cell(11, 7), Cell(10, 7), Cell(9, 7)],
    };

final _defaultRandom = math.Random();

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

class Token {
  const Token({required this.id, required this.color, required this.progress});

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        id: json['id'] as String,
        color: LudoColor.values.byName(json['color'] as String),
        progress: json['progress'] as int,
      );

  final String id;
  final LudoColor color;
  final int progress;

  Token copyWith({int? progress}) =>
      Token(id: id, color: color, progress: progress ?? this.progress);

  Map<String, dynamic> toJson() => {'id': id, 'color': color.name, 'progress': progress};
}

/// Note affichée après une action (sealed : une variante par cas du source).
sealed class LudoNote {
  const LudoNote(this.color);

  factory LudoNote.fromJson(Map<String, dynamic> json) {
    final color = LudoColor.values.byName(json['color'] as String);
    return switch (json['kind']) {
      'noMove' => NoMoveNote(color),
      'threeSixes' => ThreeSixesNote(color),
      'captured' => CapturedNote(color, [
          for (final v in json['victims'] as List) LudoColor.values.byName(v as String),
        ]),
      'finished' => FinishedNote(color, json['place'] as int),
      _ => throw FormatException('Note Ludo inconnue : ${json['kind']}'),
    };
  }

  final LudoColor color;

  Map<String, dynamic> toJson();
}

final class NoMoveNote extends LudoNote {
  const NoMoveNote(super.color);

  @override
  Map<String, dynamic> toJson() => {'kind': 'noMove', 'color': color.name};
}

final class ThreeSixesNote extends LudoNote {
  const ThreeSixesNote(super.color);

  @override
  Map<String, dynamic> toJson() => {'kind': 'threeSixes', 'color': color.name};
}

final class CapturedNote extends LudoNote {
  const CapturedNote(super.color, this.victims);

  final List<LudoColor> victims;

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'captured',
        'color': color.name,
        'victims': [for (final v in victims) v.name],
      };
}

final class FinishedNote extends LudoNote {
  const FinishedNote(super.color, this.place);

  final int place;

  @override
  Map<String, dynamic> toJson() => {'kind': 'finished', 'color': color.name, 'place': place};
}

const Object _unset = Object();

class LudoState {
  const LudoState({
    required this.tokens,
    required this.turn,
    required this.phase,
    required this.dice,
    required this.sixes,
    required this.rankings,
    required this.rollId,
    required this.diceOwner,
    required this.note,
  });

  factory LudoState.fromJson(Map<String, dynamic> json) => LudoState(
        tokens: [for (final t in json['tokens'] as List) Token.fromJson(t as Map<String, dynamic>)],
        turn: LudoColor.values.byName(json['turn'] as String),
        phase: LudoPhase.values.byName(json['phase'] as String),
        dice: json['dice'] as int?,
        sixes: json['sixes'] as int,
        rankings: [for (final c in json['rankings'] as List) LudoColor.values.byName(c as String)],
        rollId: json['rollId'] as int,
        diceOwner: json['diceOwner'] == null
            ? null
            : LudoColor.values.byName(json['diceOwner'] as String),
        note: json['note'] == null
            ? null
            : LudoNote.fromJson(json['note'] as Map<String, dynamic>),
      );

  final List<Token> tokens;
  final LudoColor turn;
  final LudoPhase phase;
  final int? dice;
  final int sixes;
  final List<LudoColor> rankings;
  final int rollId;
  final LudoColor? diceOwner;
  final LudoNote? note;

  /// Les champs nullables (dice, diceOwner, note) se remettent à null avec une valeur explicite.
  LudoState copyWith({
    List<Token>? tokens,
    LudoColor? turn,
    LudoPhase? phase,
    Object? dice = _unset,
    int? sixes,
    List<LudoColor>? rankings,
    int? rollId,
    Object? diceOwner = _unset,
    Object? note = _unset,
  }) {
    return LudoState(
      tokens: tokens ?? this.tokens,
      turn: turn ?? this.turn,
      phase: phase ?? this.phase,
      dice: identical(dice, _unset) ? this.dice : dice as int?,
      sixes: sixes ?? this.sixes,
      rankings: rankings ?? this.rankings,
      rollId: rollId ?? this.rollId,
      diceOwner: identical(diceOwner, _unset) ? this.diceOwner : diceOwner as LudoColor?,
      note: identical(note, _unset) ? this.note : note as LudoNote?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tokens': [for (final t in tokens) t.toJson()],
        'turn': turn.name,
        'phase': phase.name,
        'dice': dice,
        'sixes': sixes,
        'rankings': [for (final c in rankings) c.name],
        'rollId': rollId,
        'diceOwner': diceOwner?.name,
        'note': note?.toJson(),
      };
}

// ---------------------------------------------------------------------------
// Règles
// ---------------------------------------------------------------------------

LudoState newLudoGame([LudoColor starter = LudoColor.blue]) => LudoState(
      tokens: [
        for (final color in LudoColor.values)
          for (var slot = 0; slot < 4; slot++)
            Token(id: '${color.name}-$slot', color: color, progress: 0),
      ],
      turn: starter,
      phase: LudoPhase.roll,
      dice: null,
      sixes: 0,
      rankings: const [],
      rollId: 0,
      diceOwner: null,
      note: null,
    );

/// Indice sur la piste d'une progression de 1 à 51 ; null pour la base et la colonne d'arrivée.
int? trackIndex(LudoColor color, int progress) {
  if (progress < 1 || progress > 51) return null;
  return (ludoStartIndex(color) + progress - 1) % ludoTrackLength;
}

Cell? cellOf(Token token) {
  if (token.progress == 0) return null;
  if (token.progress == ludoFinish) return ludoGoal;
  if (token.progress >= 52) return ludoHomeColumn(token.color)[token.progress - 52];
  return ludoTrack[trackIndex(token.color, token.progress) ?? 0];
}

/// Un 6 est nécessaire pour sortir de la base. Null si le coup est impossible.
int? _advance(int progress, int dice) {
  if (progress == 0) return dice == 6 ? 1 : null;
  final next = progress + dice;
  return next <= ludoFinish ? next : null;
}

List<Token> _availableTokens(LudoState state, int dice) => state.tokens
    .where((token) => token.color == state.turn && _advance(token.progress, dice) != null)
    .toList();

List<String> legalTokenIds(LudoState state) {
  final dice = state.dice;
  if (state.phase != LudoPhase.move || dice == null) return const [];
  return [for (final token in _availableTokens(state, dice)) token.id];
}

LudoColor _nextActive(LudoState state) {
  final start = state.turn.index;
  for (var step = 1; step <= LudoColor.values.length; step++) {
    final color = LudoColor.values[(start + step) % LudoColor.values.length];
    if (!state.rankings.contains(color)) return color;
  }
  return state.turn;
}

LudoState _passTurn(LudoState state) => state.copyWith(
      turn: _nextActive(state),
      phase: LudoPhase.roll,
      sixes: 0,
    );

LudoState rollDice(LudoState state, [RandomDouble? random]) {
  if (state.phase != LudoPhase.roll) return state;
  final draw = random ?? _defaultRandom.nextDouble;
  final dice = (draw() * 6).floor() + 1;
  final sixes = dice == 6 ? state.sixes + 1 : 0;
  final rolled = state.copyWith(
    dice: dice,
    sixes: sixes,
    diceOwner: state.turn,
    rollId: state.rollId + 1,
    note: null,
  );
  if (sixes == 3) {
    return _passTurn(rolled.copyWith(note: ThreeSixesNote(state.turn)));
  }
  if (_availableTokens(rolled, dice).isEmpty) {
    return _passTurn(rolled.copyWith(note: NoMoveNote(state.turn)));
  }
  return rolled.copyWith(phase: LudoPhase.move);
}

LudoState moveToken(LudoState state, String tokenId) {
  final index = state.tokens.indexWhere((item) => item.id == tokenId);
  if (index < 0) return state;
  final token = state.tokens[index];
  final dice = state.dice;
  if (token.color != state.turn || state.phase != LudoPhase.move || dice == null) return state;
  final progress = _advance(token.progress, dice);
  if (progress == null) return state;

  final landing = trackIndex(token.color, progress);
  final victims = <LudoColor>[];
  final tokens = <Token>[];
  for (final item in state.tokens) {
    if (item.id == tokenId) {
      tokens.add(item.copyWith(progress: progress));
      continue;
    }
    final isVictim = landing != null &&
        !ludoSafeIndexes.contains(landing) &&
        item.color != token.color &&
        trackIndex(item.color, item.progress) == landing;
    if (!isVictim) {
      tokens.add(item);
      continue;
    }
    victims.add(item.color);
    tokens.add(item.copyWith(progress: 0));
  }

  final finishedNow = tokens
      .where((item) => item.color == token.color)
      .every((item) => item.progress == ludoFinish);
  var next = state.copyWith(
    tokens: tokens,
    note: victims.isNotEmpty ? CapturedNote(token.color, victims) : null,
  );

  if (finishedNow) {
    final rankings = [...state.rankings, token.color];
    next = next.copyWith(
      rankings: rankings,
      note: FinishedNote(token.color, rankings.length),
    );
    if (rankings.length == LudoColor.values.length - 1) {
      final last = LudoColor.values.firstWhere(
        (color) => !rankings.contains(color),
        orElse: () => token.color,
      );
      return next.copyWith(rankings: [...rankings, last], phase: LudoPhase.end, sixes: 0);
    }
  }

  if (dice == 6 && !finishedNow) return next.copyWith(phase: LudoPhase.roll);
  return _passTurn(next);
}

bool _isThreatened(LudoState state, LudoColor color, int index) => state.tokens.any((item) {
      if (item.color == color) return false;
      final from = trackIndex(item.color, item.progress);
      if (from == null) return false;
      final distance = (index - from + ludoTrackLength) % ludoTrackLength;
      return distance >= 1 && distance <= 6;
    });

/// Score moyen : avancée, sortie, cases sûres et captures (sans anticipation).
double _scoreMove(LudoState state, Token token, int dice) {
  final progress = _advance(token.progress, dice) ?? token.progress;
  var score = progress / 10;
  if (token.progress == 0) score += 4;
  if (progress == ludoFinish) score += 10;

  final index = trackIndex(token.color, progress);
  if (index != null) {
    if (ludoSafeIndexes.contains(index)) {
      score += 3;
    } else {
      final victims = state.tokens
          .where((item) => item.color != token.color && trackIndex(item.color, item.progress) == index)
          .length;
      score += victims * 8;
    }
  }
  return score;
}

/// Score difficile : anticipe les coups adverses.
/// - Capturer un pion adverse vaut plus s'il est avancé (il a plus perdu).
/// - Sortir de la base sur un 6 est encouragé ; une case exposée à un adversaire est pénalisée.
/// - Quitter une case menacée pour une case sûre est récompensé.
double _scoreHard(LudoState state, Token token, int dice) {
  final progress = _advance(token.progress, dice) ?? token.progress;
  var score = progress / 10;
  if (token.progress == 0) score += 6;
  if (progress == ludoFinish) score += 10;
  if (progress >= 52 && progress < ludoFinish) score += 2;

  final index = trackIndex(token.color, progress);
  if (index != null) {
    for (final item in state.tokens) {
      if (item.color == token.color || trackIndex(item.color, item.progress) != index) continue;
      if (ludoSafeIndexes.contains(index)) break;
      score += 8 + item.progress / 4;
    }
    if (ludoSafeIndexes.contains(index)) {
      score += 3;
    } else if (_isThreatened(state, token.color, index)) {
      score -= 6;
    }
  }

  final from = trackIndex(token.color, token.progress);
  if (from != null && _isThreatened(state, token.color, from) && (index == null || !_isThreatened(state, token.color, index))) {
    score += 2;
  }

  // Menace : pions adverses 1 à 6 cases devant la nouvelle case (capturables au tour suivant).
  if (index != null) {
    var targets = 0;
    for (final item in state.tokens) {
      if (item.color == token.color) continue;
      final at = trackIndex(item.color, item.progress);
      if (at == null || ludoSafeIndexes.contains(at)) continue;
      final distance = (at - index + ludoTrackLength) % ludoTrackLength;
      if (distance >= 1 && distance <= 6) targets++;
    }
    score += 1.5 * targets;
  }
  return score;
}

/// Id du pion à déplacer (null si aucun coup). Facile : au hasard ; moyen : scores ; difficile : scores anticipés.
String? chooseMove(LudoState state, LudoAiLevel level, [RandomDouble? random]) {
  final options = legalTokenIds(state);
  if (options.isEmpty) return null;
  if (level == LudoAiLevel.facile) {
    final draw = random ?? _defaultRandom.nextDouble;
    return options[(draw() * options.length).floor()];
  }

  final dice = state.dice ?? 0;
  var best = options.first;
  var bestScore = double.negativeInfinity;
  for (final id in options) {
    final token = state.tokens.firstWhere((item) => item.id == id);
    final score = level == LudoAiLevel.difficile
        ? _scoreHard(state, token, dice)
        : _scoreMove(state, token, dice);
    if (score > bestScore) {
      best = id;
      bestScore = score;
    }
  }
  return best;
}
