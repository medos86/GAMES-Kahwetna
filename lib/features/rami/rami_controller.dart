import '../../core/services/persistent_game_controller.dart';
import '../../core/services/saved_game_store.dart';

import 'dart:async';

import '../../game/common.dart';
import '../../game/rami.dart' as rules;
import '../../core/audio/sounds.dart';
import '../../core/strings.dart';

/// Délai d'une action de l'IA (550 ms dans le source).
const ramiAiDelay = Duration(milliseconds: 550);

/// Tri de la main : par couleur ou par valeur (sortHand du source).
enum RamiSortMode { suit, rank }

/// Où une carte glissée a été relâchée. L'écran le calcule à partir de la position du doigt.
sealed class RamiDropTarget {
  const RamiDropTarget();
}

/// Sur une carte de la main ; [after] = relâchée à droite du milieu de la carte.
final class RamiDropHand extends RamiDropTarget {
  const RamiDropHand(this.id, {required this.after});

  final String id;
  final bool after;
}

final class RamiDropMeld extends RamiDropTarget {
  const RamiDropMeld(this.id);

  final String id;
}

final class RamiDropTable extends RamiDropTarget {
  const RamiDropTable();
}

final class RamiDropDiscard extends RamiDropTarget {
  const RamiDropDiscard();
}

/// Tri stable par couleur ou par valeur, jokers à la fin (comme sortHand du source).
List<rules.RamiCard> sortRamiHand(
  List<rules.RamiCard> hand,
  RamiSortMode mode,
) {
  int suitOrder(rules.RamiCard card) => card.isJoker ? 4 : card.suit!.index;
  int rankKey(rules.RamiCard card) => card.isJoker ? 99 : card.rank;
  int compare(rules.RamiCard a, rules.RamiCard b) {
    final bySuit = suitOrder(a) - suitOrder(b);
    final byRank = rankKey(a) - rankKey(b);
    if (mode == RamiSortMode.suit) {
      return bySuit != 0 ? bySuit : byRank;
    }
    return byRank != 0 ? byRank : bySuit;
  }

  final indexed = [
    for (var i = 0; i < hand.length; i++) (index: i, card: hand[i]),
  ];
  indexed.sort((x, y) {
    final c = compare(x.card, y.card);
    return c != 0 ? c : x.index.compareTo(y.index);
  });
  return [for (final entry in indexed) entry.card];
}

/// État et actions d'une partie de Rami (logique de RamiGameScreen.tsx).
/// Les règles restent dans lib/game/rami.dart ; ce contrôleur gère la sélection,
/// l'ordre de la main et le tour de l'IA, comme les useState et useEffect du source.
class RamiController extends PersistentGameController {
  RamiController({
    required this.targetScore,
    required this.difficulty,
    this.onMessage,
    RandomDouble? random,
    SavedGameStore? store,
  })  : _random = random,
        _game = rules.newMatch(targetScore, random),
        super(store: store, gameKey: 'rami') {
    if (store == null) _reschedule();
  }

  final int targetScore;
  final rules.RamiAiLevel difficulty;

  /// Message d'erreur ou d'information pour l'écran (un coup refusé).
  final void Function(String message)? onMessage;
  final RandomDouble? _random;

  rules.RamiState _game;
  final List<String> _selected = [];
  List<String> _order = [];
  Timer? _timer;
  bool _disposed = false;

  rules.RamiState get game => _game;

  List<String> get selected => List.unmodifiable(_selected);

  bool get myTurn => _game.turn == 0 && _game.phase != rules.RamiPhase.end;

  bool get canDraw => myTurn && _game.phase == rules.RamiPhase.draw;

  bool get canPlay => myTurn && _game.phase == rules.RamiPhase.play;

  bool get opened => _game.opened[0];

  List<rules.RamiCard> get hand => _game.hands[0];

  rules.RamiCard? get top => _game.discard.isEmpty ? null : _game.discard.last;

  /// Main affichée : l'ordre choisi par le joueur, les nouvelles cartes à la fin.
  List<rules.RamiCard> get displayed {
    final byId = {for (final card in hand) card.id: card};
    final known = [
      for (final id in _order)
        if (byId[id] != null) byId[id]!,
    ];
    if (known.isEmpty) return sortRamiHand(hand, RamiSortMode.suit);
    final seen = {for (final card in known) card.id};
    return [
      ...known,
      for (final card in hand)
        if (!seen.contains(card.id)) card,
    ];
  }

  /// Paquets valides formés par des cartes voisines dans la main affichée.
  List<List<rules.RamiCard>> get groups => rules.meldGroups(displayed);

  /// Numéro de paquet de chaque carte (pour la barre colorée).
  Map<String, int> get groupOf {
    final map = <String, int>{};
    final all = groups;
    for (var i = 0; i < all.length; i++) {
      for (final card in all[i]) {
        map[card.id] = i;
      }
    }
    return map;
  }

  int get readyPoints =>
      groups.fold(0, (sum, group) => sum + rules.pointsOf(group));

  int get stagedPoints =>
      _game.staged.fold(0, (sum, cards) => sum + rules.pointsOf(cards));

  List<rules.RamiCard> get selectedCards => [
        for (final card in displayed)
          if (_selected.contains(card.id)) card,
      ];

  bool get selectionIsMeld =>
      selectedCards.length >= 3 && rules.isValidMeld(selectedCards);

  bool get layEligible => canPlay && opened && _selected.length == 1;

  /// Paquet à poser pour une carte glissée : la sélection si elle est valide, sinon le paquet voisin.
  List<rules.RamiCard> groupFor(String id) {
    if (_selected.contains(id) &&
        selectedCards.length >= 3 &&
        rules.isValidMeld(selectedCards)) {
      return selectedCards;
    }
    for (final group in groups) {
      if (group.any((card) => card.id == id)) return group;
    }
    return const <rules.RamiCard>[];
  }

  /// Un tap sélectionne ou désélectionne une carte.
  void tap(String id) {
    if (!canPlay) return;
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void drawFromStock() {
    if (!canDraw) return;
    Sounds.play(Sfx.draw);
    _keepOrder();
    _apply(rules.drawStock(_game, _random));
  }

  void drawFromDiscard() {
    if (!canDraw) return;
    Sounds.play(Sfx.draw);
    _keepOrder();
    _apply(rules.drawDiscard(_game));
  }

  /// Fige l'ordre affiché avant une pioche : la carte piochée arrive alors à la fin de la main.
  void _keepOrder() {
    if (_order.isEmpty) _order = [for (final card in displayed) card.id];
  }

  /// Pose la sélection comme combinaison.
  void pose() =>
      _apply(rules.poseMeld(_game, List.of(_selected)), Strings.notAMeld);

  /// Valide l'ouverture (51 points minimum).
  void commit() => _apply(
        rules.commitOpening(_game),
        'Il faut au moins ${rules.ramiOpenMin} points pour ouvrir',
      );

  void cancel() => _apply(rules.cancelStaged(_game));

  void layOffCard(String cardId, String meldId) {
    if (!opened) {
      onMessage?.call("Ouvre d'abord avec ${rules.ramiOpenMin} points");
      return;
    }
    if (_game.staged.isNotEmpty) {
      onMessage?.call(Strings.ramiFinishOpeningFirst);
      return;
    }
    _apply(rules.layOff(_game, cardId, meldId), Strings.ramiCannotLayOff);
  }

  /// Ajoute la carte sélectionnée sur une combinaison de la table.
  void layOffSelected(String meldId) {
    if (_selected.length != 1) {
      onMessage?.call(Strings.ramiSelectCardThenMeld);
      return;
    }
    layOffCard(_selected.first, meldId);
  }

  void discardOne(String cardId) {
    if (_game.staged.isNotEmpty) {
      onMessage?.call(Strings.ramiFinishOrCancel);
      return;
    }
    final failure = cardId == _game.takenId
        ? Strings.ramiCannotDiscardTaken
        : Strings.ramiDiscardRefused;
    _apply(rules.discardCard(_game, cardId), failure);
  }

  /// Défausse la carte sélectionnée.
  void discardSelected() {
    if (_selected.length != 1) {
      onMessage?.call(Strings.ramiSelectDiscard);
      return;
    }
    discardOne(_selected.first);
  }

  void sortBy(RamiSortMode mode) {
    _order = [for (final card in sortRamiHand(hand, mode)) card.id];
    notifyListeners();
  }

  /// Relâcher une carte de la main devant une autre la déplace à cet endroit.
  void _moveCard(String id, String targetId, bool after) {
    if (id == targetId) return;
    final ids = [
      for (final card in displayed)
        if (card.id != id) card.id,
    ];
    final at = ids.indexOf(targetId);
    if (at < 0) return;
    ids.insert(after ? at + 1 : at, id);
    _order = ids;
    notifyListeners();
  }

  /// Traite le relâchement d'une carte glissée selon sa cible.
  void dropCard(String id, RamiDropTarget? target) {
    if (target == null) return;
    final t = target;
    if (t is RamiDropHand) {
      _moveCard(id, t.id, t.after);
      return;
    }
    if (!canPlay) {
      onMessage?.call(canDraw ? Strings.drawFirst : Strings.waitTurn);
      return;
    }
    if (t is RamiDropDiscard) {
      discardOne(id);
      return;
    }
    if (t is RamiDropMeld) {
      layOffCard(id, t.id);
      return;
    }
    // Relâché sur la table : il faut un paquet d'au moins 3 cartes.
    final ids = [for (final card in groupFor(id)) card.id];
    if (ids.length < 3) {
      onMessage?.call(Strings.ramiFormFirst);
      return;
    }
    _apply(rules.poseMeld(_game, ids), Strings.notAMeld);
  }

  void nextRound() {
    _game = rules.nextRound(_game, _random);
    _selected.clear();
    _order = [];
    _reschedule();
    notifyListeners();
  }

  void restart() {
    _game = rules.newMatch(targetScore, _random);
    _selected.clear();
    _order = [];
    _reschedule();
    notifyListeners();
  }

  /// Applique une action du joueur. Une action refusée renvoie le même état (identical) et prévient l'écran.
  void _apply(rules.RamiState next, [String? failure]) {
    if (identical(next, _game)) {
      if (failure != null) onMessage?.call(failure);
      return;
    }
    _game = next;
    _selected.clear();
    _reschedule();
    notifyListeners();
  }

  /// Une seule action IA programmée à la fois, reprogrammée après chaque changement.
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || _game.phase == rules.RamiPhase.end || _game.turn == 0)
      return;
    _timer = Timer(ramiAiDelay, _aiStep);
  }

  void _aiStep() {
    _timer = null;
    final next = rules.aiStep(_game, difficulty, _random);
    // Sans progrès, on s'arrête : le même état relancerait la même action.
    if (identical(next, _game)) return;
    _game = next;
    _reschedule();
    notifyListeners();
  }

  @override
  Map<String, dynamic>? snapshot() =>
      _game.matchWinner != null ? null : _game.toJson();

  @override
  void applySnapshot(Map<String, dynamic> json) =>
      _game = rules.RamiState.fromJson(json);

  @override
  void startFresh() => _reschedule();

  @override
  void newGame() => restart();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
