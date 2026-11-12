import '../../core/services/persistent_game_controller.dart';

import 'dart:async';

import '../../core/audio/sounds.dart';
import '../../game/chkobba.dart';
import '../../game/common.dart';

/// Choix de capture en attente quand une carte peut prendre plusieurs combinaisons.
class PendingCapture {
  const PendingCapture(this.cardId, this.options);

  final String cardId;
  final List<List<ChkobbaCard>> options;
}

/// État et actions d'une partie de Chkobba (logique de GameScreen.tsx).
/// Les règles restent dans lib/game/chkobba.dart ; ce contrôleur gère les délais et la séquence des tours.
/// Emplacement fixe de chaque carte du tapis. Une carte garde son emplacement tant qu'elle est sur la table ;
/// une carte nouvelle prend le plus petit emplacement libre ; un emplacement libéré est réutilisable.
Map<String, int> assignTableSlots(Map<String, int> previous, List<String> ids) {
  final present = ids.toSet();
  final slots = <String, int>{
    for (final entry in previous.entries)
      if (present.contains(entry.key)) entry.key: entry.value,
  };
  final taken = slots.values.toSet();
  var next = 0;
  for (final id in ids) {
    if (slots.containsKey(id)) continue;
    while (taken.contains(next)) {
      next++;
    }
    slots[id] = next;
    taken.add(next);
  }
  return slots;
}

class ChkobbaController extends PersistentGameController {
  ChkobbaController({
    required this.targetScore,
    required this.level,
    RandomDouble? random,
    ChkobbaState? initialState,
    super.store,
  })  : _random = random,
        _game =
            initialState ?? newMatch(targetScore: targetScore, random: random),
        super(gameKey: 'chkobba');

  final int targetScore;
  final ChkobbaAiLevel level;
  final RandomDouble? _random;

  ChkobbaState _game;
  ChkobbaRoundScore? _roundSummary;
  Player? _hayaBy;
  String? _opponentChoice;

  /// Décision de l'adversaire : prend-il une prise s'il en a une (facile seulement).
  bool _opponentCaptures = true;
  PendingCapture? _pendingCapture;

  Timer? _timer;
  Timer? _hayaTimer;

  ChkobbaState get game => _game;

  Map<String, int> _tableSlots = {};

  /// Emplacements des cartes du tapis, stables d'un coup à l'autre.
  Map<String, int> tableSlots() {
    _tableSlots = assignTableSlots(_tableSlots, [
      for (final card in _game.table) card.id,
    ]);
    return Map.unmodifiable(_tableSlots);
  }

  ChkobbaRoundScore? get roundSummary => _roundSummary;
  Player? get hayaBy => _hayaBy;
  PendingCapture? get pendingCapture => _pendingCapture;

  /// Carte que l'adversaire a montrée et va jouer (phase 1 terminée).
  String? get revealedCardId {
    final id = _opponentChoice;
    if (id == null) return null;
    return _game.hands[Player.opponent]!.any((c) => c.id == id) ? id : null;
  }

  bool get isOpponentThinking =>
      _game.winner == null &&
      _game.turn == Player.opponent &&
      _game.hands[Player.opponent]!.isNotEmpty;

  /// Le joueur clique sur une de ses cartes.
  void tapPlayerCard(String cardId) {
    if (_game.winner != null || _game.turn != Player.player) return;
    final options = getCaptureOptions(_game, Player.player, cardId);
    if (options.length > 1) {
      _pendingCapture = PendingCapture(cardId, options);
      notifyListeners();
      return;
    }
    _playPlayerCard(cardId);
  }

  /// Le joueur choisit une prise parmi plusieurs.
  void choosePendingCapture(List<ChkobbaCard> option) {
    final pending = _pendingCapture;
    if (pending == null) return;
    _playPlayerCard(
      pending.cardId,
      chosenIds: option.map((c) => c.id).toList(),
    );
  }

  void cancelPendingCapture() {
    if (_pendingCapture == null) return;
    _pendingCapture = null;
    notifyListeners();
  }

  void _playPlayerCard(String cardId, {List<String>? chosenIds}) {
    final result = playCard(_game, Player.player, cardId, chosenIds: chosenIds);
    _pendingCapture = null;
    _apply(
      result.state,
      haya: result.haya ? Player.player : null,
      sfx: Sfx.place,
    );
  }

  /// Fin de manche confirmée : nouvelle manche (le donneur alterne), sauf si la partie est finie.
  void continueAfterRound() {
    final summary = _roundSummary;
    if (summary == null) return;
    final state = summary.state;
    _roundSummary = null;
    if (state.winner == null) {
      _game = dealRound(
        scores: state.scores,
        starter: other(state.starter),
        round: state.round + 1,
        targetScore: state.targetScore,
        random: _random,
      );
    }
    _opponentChoice = null;
    _update();
  }

  void startNewGame() {
    _roundSummary = null;
    _pendingCapture = null;
    _opponentChoice = null;
    _game = newMatch(targetScore: targetScore, random: _random);
    _update();
  }

  void _apply(ChkobbaState next, {Player? haya, Sfx? sfx}) {
    _game = next;
    _opponentChoice = null;
    if (haya != null) {
      _hayaBy = haya;
      _hayaTimer?.cancel();
      _hayaTimer = Timer(const Duration(milliseconds: 1800), () {
        _hayaBy = null;
        notifyListeners();
      });
    }
    if (sfx != null) Sounds.play(sfx);
    _update();
  }

  /// Notifie l'interface puis programme la prochaine étape automatique (équivalent des useEffect du source).
  void _update() {
    notifyListeners();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final state = _game;
    if (_roundSummary != null || state.winner != null) return;

    // Manche épuisée : on redistribue tant que le paquet n'est pas vide, sinon on compte les points.
    if (state.hands[Player.player]!.isEmpty &&
        state.hands[Player.opponent]!.isEmpty) {
      if (state.deck.isNotEmpty) {
        _timer = Timer(const Duration(milliseconds: 1000), () {
          _game = dealHands(_game);
          Sounds.play(Sfx.draw);
          _update();
        });
      } else {
        _timer = Timer(const Duration(milliseconds: 1500), () {
          final result = scoreRound(_game);
          _game = result.state;
          _roundSummary = result;
          if (result.state.winner != null) {
            Sounds.play(
              result.state.winner == Player.player ? Sfx.win : Sfx.lose,
            );
          }
          _update();
        });
      }
      return;
    }

    if (!isOpponentThinking) return;
    final revealed = revealedCardId;
    if (revealed == null) {
      // Phase 1 : l'adversaire choisit et montre sa carte.
      _timer = Timer(const Duration(milliseconds: 1000), () {
        final move = chooseOpponentMove(_game, level, random: _random);
        _opponentChoice = move.cardId;
        _opponentCaptures = move.capture;
        notifyListeners();
        _schedule();
      });
    } else {
      // Phase 2 : il joue la carte montrée.
      _timer = Timer(const Duration(milliseconds: 1200), () {
        final result = playCard(
          _game,
          Player.opponent,
          revealed,
          discardOnly: !_opponentCaptures,
        );
        _apply(
          result.state,
          haya: result.haya ? Player.opponent : null,
          sfx: Sfx.place,
        );
      });
    }
  }

  @override
  Map<String, dynamic>? snapshot() =>
      _game.winner != null ? null : _game.toJson();

  @override
  void applySnapshot(Map<String, dynamic> json) =>
      _game = ChkobbaState.fromJson(json);

  @override
  void startFresh() => _schedule();

  @override
  void newGame() => startNewGame();

  @override
  void dispose() {
    _timer?.cancel();
    _hayaTimer?.cancel();
    super.dispose();
  }
}
