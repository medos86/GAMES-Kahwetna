import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/coinche.dart';
import '../../game/common.dart';
import '../menu/menu_models.dart';

/// État et actions d'une partie de Coinche (logique de CoincheGameScreen.tsx).
///
/// Les règles restent dans lib/game/coinche.dart. Ce contrôleur ne fait que
/// programmer les tours de l'IA et les transitions (ramassage, fin de manche, donne),
/// avec les mêmes délais que les useEffect du source.
class CoincheController extends ChangeNotifier {
  CoincheController({
    required this.target,
    required this.difficulty,
    RandomDouble? random,
  })  : _random = random,
        _match = newMatch(target),
        _round = dealRound(firstDealer, random) {
    _reschedule();
  }

  final int target;
  final Difficulty difficulty;
  final RandomDouble? _random;

  CoincheMatch _match;
  RoundState _round;
  CoincheRoundResult? _summary;
  CoincheSuit? _choiceMode;
  int? _choiceValue;
  Timer? _timer;
  bool _disposed = false;

  CoincheMatch get match => _match;
  RoundState get round => _round;

  /// Récapitulatif de la manche terminée, affiché tant qu'il n'est pas fermé.
  CoincheRoundResult? get summary => _summary;

  CoincheSuit? get choiceMode => _choiceMode;
  int? get choiceValue => _choiceValue;

  /// Le jeu aléatoire est réservé au niveau facile (même règle que le source).
  bool get randomPlay => difficulty == Difficulty.facile;

  bool get isBiddingTurn => _round.phase == CoinchePhase.bidding && _round.turn == Seat.south;

  bool get isHumanPlayTurn => _round.phase == CoinchePhase.playing && _round.turn == Seat.south;

  /// Main du joueur, triée comme le source.
  List<CoincheCard> get hand => sortHand(_round.hands[Seat.south]!);

  /// Identifiants des cartes jouables au tour du joueur.
  Set<String> get legalIds => isHumanPlayTurn
      ? legalCards(_round, Seat.south).map((card) => card.id).toSet()
      : const <String>{};

  int get minValue => minBidValue(_round);

  bool get canContre {
    final contract = _round.contract;
    return contract != null && contract.multiplier == 1 && teamOf(contract.seat) == Team.ew;
  }

  bool get canSurcoinche {
    final contract = _round.contract;
    return contract != null && contract.multiplier == 2 && teamOf(contract.seat) == Team.ns;
  }

  void setChoiceMode(CoincheSuit mode) {
    _choiceMode = mode;
    notifyListeners();
  }

  void setChoiceValue(int value) {
    _choiceValue = value;
    notifyListeners();
  }

  /// Annonce de l'humain : passe, contre, surcoinche, ou valeur + atout choisis.
  void callBid(BidAction action) {
    _choiceMode = null;
    _choiceValue = null;
    _setRound(placeBid(_round, Seat.south, action));
  }

  /// Valide l'annonce construite dans le panneau (valeur + atout).
  void announce() {
    final mode = _choiceMode;
    final value = _choiceValue;
    if (mode == null || value == null) return;
    callBid(ValueBid(value, mode));
  }

  void playHuman(String cardId) => _setRound(playCard(_round, Seat.south, cardId));

  /// Ferme le récapitulatif et donne la manche suivante.
  void nextRound() {
    _summary = null;
    _setRound(dealRound(nextSeat(_round.dealer), _random));
  }

  /// Nouvelle partie complète, même cible.
  void restart() {
    _match = newMatch(target);
    _summary = null;
    _choiceMode = null;
    _choiceValue = null;
    _setRound(dealRound(firstDealer, _random));
  }

  void _setRound(RoundState next) {
    if (identical(next, _round)) return;
    _round = next;
    _reschedule();
    notifyListeners();
  }

  /// Équivalent des useEffect de CoincheGameScreen : un seul minuteur actif à la fois,
  /// reprogrammé après chaque changement d'état.
  void _reschedule() {
    _timer?.cancel();
    _timer = null;
    if (_disposed) return;
    final round = _round;

    switch (round.phase) {
      case CoinchePhase.bidding:
        final turn = round.turn;
        if (turn == null || turn == Seat.south) return;
        _timer = Timer(const Duration(milliseconds: 900), () {
          _setRound(placeBid(_round, turn, chooseBid(_round, turn)));
        });
        break;
      case CoinchePhase.playing:
        if (round.trick.length == 4) {
          _timer = Timer(const Duration(milliseconds: 1400), () {
            _setRound(collectTrick(_round));
          });
          return;
        }
        final turn = round.turn;
        if (turn == null || turn == Seat.south) return;
        _timer = Timer(const Duration(milliseconds: 900), () {
          _setRound(playCard(_round, turn, chooseCard(_round, turn, randomPlay, _random)));
        });
        break;
      case CoinchePhase.done:
        if (_summary != null) return;
        _timer = Timer(const Duration(milliseconds: 1200), () {
          final result = scoreRound(_round);
          if (result == null) return;
          _match = applyRound(_match, result);
          _summary = result;
          notifyListeners();
        });
        break;
      case CoinchePhase.redeal:
        _timer = Timer(const Duration(milliseconds: 1200), () {
          _setRound(dealRound(nextSeat(_round.dealer), _random));
        });
        break;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
