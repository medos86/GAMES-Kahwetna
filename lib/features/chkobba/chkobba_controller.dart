import '../../core/services/persistent_game_controller.dart';

import 'dart:async';

import '../../core/audio/sounds.dart';
import '../../core/feedback/capture_feedback.dart';
import '../../core/reactions/reaction_mood.dart';
import '../../core/services/reaction_stickers.dart';
import '../../game/chkobba.dart';
import '../../game/chkobba_reactions.dart';
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

  /// Durée d'affichage de la bannière « 7AYA ! » : courte pour ne pas masquer le plateau (#364).
  static const hayaDuration = Duration(milliseconds: 1000);

  Player? _hayaBy;

  /// Qui vient de faire une Chkobba (table vidée hors dernier coup) : bannière au centre du tapis (#176).
  Player? _chkobbaBy;
  Timer? _chkobbaTimer;

  /// Cartes qui ont fait les Chkobba de chaque joueur, gardées sous son tas (#594, #626). Vidées à chaque manche.
  final Map<Player, List<ChkobbaCard>> _chkobbaCards = {};
  String? _opponentChoice;

  /// Décision de l'adversaire : prend-il une prise s'il en a une (facile seulement).
  bool _opponentCaptures = true;
  PendingCapture? _pendingCapture;

  Timer? _timer;
  Timer? _hayaTimer;

  /// Stickers de réaction affichés près des avatars (#761).
  static const reactionDuration = Duration(milliseconds: 2000);
  Timer? _reactionTimer;
  Map<Player, ReactionMood> _reactions = const {};

  /// Humeur à afficher près de l'avatar de [player], ou null.
  ReactionMood? reactionOf(Player player) => _reactions[player];

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

  Player? get chkobbaBy => _chkobbaBy;

  /// Carte de Chkobba posée sous le tas de [p], ou null (#594).
  ChkobbaCard? chkobbaCardOf(Player p) {
    final cards = _chkobbaCards[p];
    return cards == null || cards.isEmpty ? null : cards.last;
  }

  /// Toutes les cartes de Chkobba de [p], dans l'ordre où elles ont été faites (#626).
  List<ChkobbaCard> chkobbaCardsOf(Player p) =>
      List.unmodifiable(_chkobbaCards[p] ?? const <ChkobbaCard>[]);
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
      chkobba: result.chkobba ? Player.player : null,
      capturer: _capturerOf(_game, result.state),
      sfx: Sfx.place,
    );
  }

  /// Fin de manche confirmée : nouvelle manche (le donneur alterne), sauf si la partie est finie.
  void continueAfterRound() {
    final summary = _roundSummary;
    if (summary == null) return;
    final state = summary.state;
    _roundSummary = null;
    _chkobbaCards.clear();
    if (state.winner == null) {
      Sounds.play(Sfx.cardDeal);
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
    _chkobbaCards.clear();
    _pendingCapture = null;
    _opponentChoice = null;
    _game = newMatch(targetScore: targetScore, random: _random);
    _update();
  }

  /// Joueur dont la pile de prises s'est agrandie entre [before] et [after] (#788).
  static Player? _capturerOf(ChkobbaState before, ChkobbaState after) {
    for (final p in Player.values) {
      if (after.won[p]!.length > before.won[p]!.length) return p;
    }
    return null;
  }

  void _apply(
    ChkobbaState next, {
    Player? haya,
    Player? chkobba,
    Player? capturer,
    Sfx? sfx,
  }) {
    _game = next;
    _opponentChoice = null;
    if (chkobba != null) {
      (_chkobbaCards[chkobba] ??= []).add(next.won[chkobba]!.last);
      _chkobbaBy = chkobba;
      _chkobbaTimer?.cancel();
      _chkobbaTimer = Timer(hayaDuration, () {
        _chkobbaBy = null;
        notifyListeners();
      });
    }
    if (haya != null) {
      _hayaBy = haya;
      _hayaTimer?.cancel();
      _hayaTimer = Timer(hayaDuration, () {
        _hayaBy = null;
        notifyListeners();
      });
    }
    _showReactions(
      chkobbaReactions(chkobba: chkobba, haya: haya, capturer: capturer),
    );
    if (sfx != null) Sounds.play(sfx);
    if (capturer != null) {
      // Retour tactile : double vibration pour Chkobba / 7AYA (#913).
      CaptureFeedback.onCapture(special: chkobba != null || haya != null);
    }
    _update();
  }

  void _showReactions(Map<Player, ReactionMood> moods) {
    if (moods.isEmpty || !reactionStickers.value) return;
    _reactions = moods;
    _reactionTimer?.cancel();
    _reactionTimer = Timer(reactionDuration, () {
      _reactions = const {};
      notifyListeners();
    });
  }

  /// Notifie l'interface puis programme la prochaine étape automatique (équivalent des useEffect du source).
  void _update() {
    notifyListeners();
    _schedule();
  }

  /// Vrai depuis une redonne en cours de manche (son joué) jusqu'à sa lecture par l'écran.
  bool _dealt = false;

  /// Lit et réinitialise le drapeau de redonne : l'écran anime alors la distribution (#redonne).
  bool takeDeal() {
    final dealt = _dealt;
    _dealt = false;
    return dealt;
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
          Sounds.play(Sfx.cardDeal);
          _dealt = true;
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
          chkobba: result.chkobba ? Player.opponent : null,
          capturer: _capturerOf(_game, result.state),
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
    _chkobbaTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }
}
