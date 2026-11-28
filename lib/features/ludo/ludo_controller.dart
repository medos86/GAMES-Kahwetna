import '../../core/services/persistent_game_controller.dart';

import 'dart:async';

import '../../core/audio/sounds.dart';
import '../../game/common.dart';
import '../../game/ludo.dart';
import 'ludo_layout.dart';

/// Couleurs humaines dans l'ordre du source : les N premières sont jouées par l'humain.
const ludoHumanOrder = [
  LudoColor.blue,
  LudoColor.red,
  LudoColor.green,
  LudoColor.yellow,
];

/// Délai de l'IA quand la fin de partie est accélérée (#387).
const ludoFastAiDelay = Duration(milliseconds: 150);

/// Pause après un lancer sans coup possible (ou trois 6) : le dé secoue la tête
/// « non » et le tour ne passe qu'ensuite, pour que le joueur comprenne (#855).
const ludoNoMoveHold = Duration(milliseconds: 1500);

/// Délai avant qu'un pion unique jouable avance seul (#388).
const ludoAutoMoveDelay = Duration(milliseconds: 700);

/// Délai d'un tour de l'IA selon le niveau (valeurs du source : 1100 / 850 / 600 ms).
Duration ludoRollDelay(LudoAiLevel level) => switch (level) {
      LudoAiLevel.facile => const Duration(milliseconds: 1100),
      LudoAiLevel.moyen => const Duration(milliseconds: 850),
      LudoAiLevel.difficile => const Duration(milliseconds: 600),
    };

/// État et actions d'une partie de Ludo (logique de LudoGameScreen.tsx).
/// Les règles restent dans lib/game/ludo.dart ; ce contrôleur ne fait que
/// programmer les tours de l'IA, comme le useEffect du source.
class LudoController extends PersistentGameController {
  LudoController({
    required this.playerCount,
    required this.difficulty,
    RandomDouble? random,
    super.store,
  })  : _random = random,
        _game = newLudoGame(),
        super(gameKey: 'ludo');

  /// Nombre de joueurs humains (1 à 4).
  final int playerCount;
  final LudoAiLevel difficulty;
  final RandomDouble? _random;

  LudoState _game;
  Timer? _timer;
  bool _disposed = false;

  /// Animation du dernier coup en cours : personne ne lance ni ne joue (#778).
  Timer? _settleTimer;
  bool get _settling => _settleTimer != null;

  LudoState get game => _game;

  /// Joueur dont le tour est affiché : pendant la pause « non », c'est encore celui qui a lancé.
  LudoColor? _holdColor;
  LudoColor get shownTurn => _holdColor ?? _game.turn;

  /// Joueur qui a lancé sans coup possible, pendant la pause ; null sinon.
  LudoColor? get refusedColor => _holdColor;

  /// Attente (ms) avant la galipette de la victime du dernier coup : l'attaquant arrive d'abord (#882).
  int _victimDelayMs = 0;
  int get victimDelayMs => _victimDelayMs;

  /// Son de capture, joué au départ de la galipette de la victime (#882).
  Timer? _captureSfxTimer;

  List<LudoColor> get humans => ludoHumanOrder.take(playerCount).toList();

  /// Une seule personne jouant : on affiche « Toi » au lieu de « Bleu ».
  bool get solo => humans.length == 1;

  bool get humanTurn => humans.contains(_game.turn);

  /// Fin affichée seulement quand le dernier pion est arrivé (#1089) :
  /// le phase « end » est posé dès le calcul du coup, avant l'animation.
  bool get roundOver => _game.phase == LudoPhase.end && !_settling;

  /// Tous les joueurs humains sont arrivés : l'IA finit seule (#387).
  bool get humansDone =>
      humans.every((color) => _game.rankings.contains(color));

  /// Proposer le choix « finir la partie » ou « voir la fin ».
  bool get choiceOpen =>
      humansDone && !_settling && _game.phase != LudoPhase.end && !_choiceMade;

  bool _choiceMade = false;
  bool _fastAi = false;

  /// L'IA enchaîne vite jusqu'à la fin (#387).
  void finishGame() {
    _choiceMade = true;
    _fastAi = true;
    _reschedule();
    notifyListeners();
  }

  /// Regarder la fin : l'IA finit sa marche à vitesse normale, et le menu
  /// de fin n'apparaît qu'une fois la dernière arrivée jouée.
  void showEnd() {
    _choiceMade = true;
    _fastAi = false;
    _reschedule();
    notifyListeners();
  }

  /// Pions jouables au tour de l'humain.
  Set<String> get legalIds {
    if (!humanTurn || _settling) return const <String>{};
    return legalTokenIds(_game).toSet();
  }

  bool get canRoll => humanTurn && !_settling && _game.phase == LudoPhase.roll;

  /// Le joueur lance le dé.
  void roll() {
    if (_settling) return;
    final next = rollDice(_game, _random);
    if (!identical(next, _game)) Sounds.play(Sfx.dice);
    _setGame(next);
  }

  /// Le joueur touche un pion (sans effet si le coup n'est pas légal).
  void tapToken(String tokenId) {
    if (_settling) return;
    final next = moveToken(_game, tokenId);
    _setGame(next);
  }

  /// Nouvelle partie, mêmes joueurs et niveau.
  void restart() {
    _settleTimer?.cancel();
    _settleTimer = null;
    _captureSfxTimer?.cancel();
    _captureSfxTimer = null;
    _holdColor = null;
    _choiceMade = false;
    _fastAi = false;
    _lastFaces.clear();
    _setGame(newLudoGame());
  }

  /// Dernière face obtenue par chaque couleur : son dé la garde affichée (pas de retour à 5).
  final Map<LudoColor, int> _lastFaces = {};

  /// Face à afficher pour le dé de [color] : sa dernière valeur, null avant son premier lancer.
  int? lastFaceOf(LudoColor color) => _lastFaces[color];

  void _setGame(LudoState next) {
    if (identical(next, _game)) return;
    if (next.dice != null &&
        next.diceOwner != null &&
        next.rollId != _game.rollId) {
      _lastFaces[next.diceOwner!] = next.dice!;
    }
    final sfx = ludoMoveSfx(_game, next);
    if (sfx != null) Sounds.play(sfx);
    _victimDelayMs = ludoVictimDelayFor(_game.tokens, next.tokens);
    if (next.note is CapturedNote) {
      _captureSfxTimer?.cancel();
      _captureSfxTimer = Timer(
        Duration(milliseconds: _victimDelayMs),
        () => Sounds.play(Sfx.capture),
      );
    }
    final settle = ludoMoveSettleMs(_game.tokens, next.tokens);
    final refused = next.note is NoMoveNote || next.note is ThreeSixesNote;
    final freshRoll = next.rollId != _game.rollId && next.diceOwner != null;
    _game = next;
    if (settle > 0) {
      _settleTimer?.cancel();
      _settleTimer = Timer(Duration(milliseconds: settle), _endSettle);
    } else if (refused && freshRoll) {
      // Lancer sans coup : le dé dit « non » et le tour reste à ce joueur un instant (#855).
      Sounds.play(Sfx.pass);
      _holdColor = next.diceOwner;
      _settleTimer?.cancel();
      _settleTimer = Timer(ludoNoMoveHold, _endSettle);
    }
    _reschedule();
    notifyListeners();
  }

  /// Fin de l'animation du coup : le tour suivant peut enfin démarrer.
  void _endSettle() {
    _settleTimer = null;
    _holdColor = null;
    _reschedule();
    notifyListeners();
  }

  /// Une seule action programmée à la fois, reprogrammée après chaque changement.
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed || _settling) return;
    if (humanTurn) {
      // Un seul pion jouable : il avance tout seul après un court instant (#388).
      if (_game.phase != LudoPhase.move || legalIds.length != 1) return;
      final tokenId = legalIds.first;
      _timer = Timer(ludoAutoMoveDelay, () => tapToken(tokenId));
      return;
    }
    final aiTurn =
        _game.phase == LudoPhase.roll || _game.phase == LudoPhase.move;
    if (!aiTurn) return;

    final delay = _fastAi ? ludoFastAiDelay : ludoRollDelay(difficulty);
    _timer = Timer(delay, () {
      if (_game.phase == LudoPhase.roll) {
        _setGame(rollDice(_game, _random, difficulty));
        return;
      }
      final tokenId = chooseMove(_game, difficulty, _random);
      if (tokenId != null) _setGame(moveToken(_game, tokenId));
    });
  }

  @override
  Map<String, dynamic>? snapshot() =>
      _game.phase == LudoPhase.end ? null : _game.toJson();

  @override
  void applySnapshot(Map<String, dynamic> json) =>
      _game = LudoState.fromJson(json);

  @override
  void startFresh() => _reschedule();

  @override
  void newGame() => restart();

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _captureSfxTimer?.cancel();
    _captureSfxTimer = null;
    super.dispose();
  }
}

/// Son d'un coup de Ludo (issue #794) : pion joué, entrée maison, sinon pas de pion.
/// Une capture joue d'abord le pion qui avance ; le son de capture part avec la galipette (#882).
/// Null si aucun pion n'a bougé (lancer de dé seul, tour passé).
Sfx? ludoMoveSfx(LudoState before, LudoState after) {
  if (!_anyTokenMoved(before.tokens, after.tokens)) return null;
  final note = after.note;
  if (note is FinishedNote) return Sfx.pawnHome;
  return Sfx.pawnMove;
}

bool _anyTokenMoved(List<Token> before, List<Token> after) {
  final oldProgress = {for (final t in before) t.id: t.progress};
  return after.any((t) => oldProgress[t.id] != t.progress);
}
