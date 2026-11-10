import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/common.dart';
import '../../game/ludo.dart';

/// Couleurs humaines dans l'ordre du source : les N premières sont jouées par l'humain.
const ludoHumanOrder = [LudoColor.blue, LudoColor.yellow, LudoColor.red, LudoColor.green];

/// Délai d'un tour de l'IA selon le niveau (valeurs du source : 1100 / 850 / 600 ms).
Duration ludoRollDelay(LudoAiLevel level) => switch (level) {
      LudoAiLevel.facile => const Duration(milliseconds: 1100),
      LudoAiLevel.moyen => const Duration(milliseconds: 850),
      LudoAiLevel.difficile => const Duration(milliseconds: 600),
    };

/// État et actions d'une partie de Ludo (logique de LudoGameScreen.tsx).
/// Les règles restent dans lib/game/ludo.dart ; ce contrôleur ne fait que
/// programmer les tours de l'IA, comme le useEffect du source.
class LudoController extends ChangeNotifier {
  LudoController({
    required this.playerCount,
    required this.difficulty,
    RandomDouble? random,
  })  : _random = random,
        _game = newLudoGame();

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

  /// Pions jouables au tour de l'humain.
  Set<String> get legalIds => humanTurn ? legalTokenIds(_game).toSet() : const <String>{};

  bool get canRoll => humanTurn && _game.phase == LudoPhase.roll;

  /// Le joueur lance le dé.
  void roll() => _setGame(rollDice(_game, _random));

  /// Le joueur touche un pion (sans effet si le coup n'est pas légal).
  void tapToken(String tokenId) => _setGame(moveToken(_game, tokenId));

  /// Nouvelle partie, mêmes joueurs et niveau.
  void restart() => _setGame(newLudoGame());

  void _setGame(LudoState next) {
    if (identical(next, _game)) return;
    _game = next;
    _reschedule();
    notifyListeners();
  }

  /// Une seule action IA programmée à la fois, reprogrammée après chaque changement.
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;
    final aiTurn = !humanTurn && (_game.phase == LudoPhase.roll || _game.phase == LudoPhase.move);
    if (!aiTurn) return;

    _timer = Timer(ludoRollDelay(difficulty), () {
      if (_game.phase == LudoPhase.roll) {
        _setGame(rollDice(_game, _random));
        return;
      }
      final tokenId = chooseMove(_game, difficulty, _random);
      if (tokenId != null) _setGame(moveToken(_game, tokenId));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
