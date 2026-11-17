import '../../core/services/persistent_game_controller.dart';

import 'dart:async';

import '../../core/audio/sounds.dart';
import '../../game/common.dart';
import '../../game/ludo.dart';

/// Couleurs humaines dans l'ordre du source : les N premières sont jouées par l'humain.
const ludoHumanOrder = [
  LudoColor.blue,
  LudoColor.yellow,
  LudoColor.red,
  LudoColor.green,
];

/// Délai de l'IA quand la fin de partie est accélérée (#387).
const ludoFastAiDelay = Duration(milliseconds: 150);

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

  LudoState get game => _game;

  List<LudoColor> get humans => ludoHumanOrder.take(playerCount).toList();

  /// Une seule personne jouant : on affiche « Toi » au lieu de « Bleu ».
  bool get solo => humans.length == 1;

  bool get humanTurn => humans.contains(_game.turn);

  bool get roundOver => _game.phase == LudoPhase.end;

  /// Tous les joueurs humains sont arrivés : l'IA finit seule (#387).
  bool get humansDone =>
      humans.every((color) => _game.rankings.contains(color));

  /// Proposer le choix « finir la partie » ou « voir la fin ».
  bool get choiceOpen => humansDone && !roundOver && !_choiceMade;

  bool _choiceMade = false;
  bool _fastAi = false;

  /// L'IA enchaîne vite jusqu'à la fin (#387).
  void finishGame() {
    _choiceMade = true;
    _fastAi = true;
    _reschedule();
    notifyListeners();
  }

  /// La partie se termine tout de suite, avec le classement actuel (#387).
  void showEnd() {
    _choiceMade = true;
    _setGame(endLudoGameNow(_game));
  }

  /// Pions jouables au tour de l'humain.
  Set<String> get legalIds =>
      humanTurn ? legalTokenIds(_game).toSet() : const <String>{};

  bool get canRoll => humanTurn && _game.phase == LudoPhase.roll;

  /// Le joueur lance le dé.
  void roll() {
    final next = rollDice(_game, _random);
    if (!identical(next, _game)) Sounds.play(Sfx.dice);
    _setGame(next);
  }

  /// Le joueur touche un pion (sans effet si le coup n'est pas légal).
  void tapToken(String tokenId) {
    final next = moveToken(_game, tokenId);
    if (!identical(next, _game)) Sounds.play(Sfx.place);
    _setGame(next);
  }

  /// Nouvelle partie, mêmes joueurs et niveau.
  void restart() {
    _choiceMade = false;
    _fastAi = false;
    _setGame(newLudoGame());
  }

  void _setGame(LudoState next) {
    if (identical(next, _game)) return;
    _game = next;
    _reschedule();
    notifyListeners();
  }

  /// Une seule action programmée à la fois, reprogrammée après chaque changement.
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;
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
        _setGame(rollDice(_game, _random));
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
    super.dispose();
  }
}
