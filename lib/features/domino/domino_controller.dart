import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/audio/sounds.dart';
import '../../game/common.dart';
import '../../game/domino.dart';
import '../../game/domino_ai.dart';
import '../menu/menu_models.dart';

/// État et actions d'une partie de Domino (logique de DominoGameScreen.tsx).
/// Les règles restent dans lib/game/ ; ce contrôleur gère le tour de l'IA et la sélection.
class DominoController extends ChangeNotifier {
  DominoController({
    required this.targetScore,
    required this.difficulty,
    RandomDouble? random,
  })  : _random = random,
        _game = newDominoRound(targetScore: targetScore, random: random);

  final int targetScore;
  final Difficulty difficulty;
  final RandomDouble? _random;

  DominoState _game;
  String? _selectedTileId;
  Timer? _aiTimer;

  DominoState get game => _game;

  String? get selectedTileId => _selectedTileId;

  List<DominoTile> get playable => playableTiles(_game, Player.player);

  DominoTile? get selectedTile {
    for (final tile in _game.hands[Player.player]!) {
      if (tile.id == _selectedTileId) return tile;
    }
    return null;
  }

  /// Le joueur ne peut rien poser : il doit piocher (ou passer).
  bool get mustDraw =>
      _game.turn == Player.player && _game.roundWinner == null && playable.isEmpty;

  bool get isAiTurn =>
      _game.turn == Player.opponent && _game.roundWinner == null && _game.matchWinner == null;

  /// Extrémités où la tuile sélectionnée peut se poser (null si rien à proposer).
  ({bool left, bool right})? get chainEnds {
    final tile = selectedTile;
    if (tile == null || _game.turn != Player.player || _game.roundWinner != null) return null;
    return (
      left: canPlace(tile, _game, DominoSide.left),
      right: canPlace(tile, _game, DominoSide.right),
    );
  }

  /// Délai de l'IA selon le niveau (valeurs du source : 1250 / 950 / 650 ms).
  Duration get aiDelay => switch (difficulty) {
        Difficulty.difficile => const Duration(milliseconds: 650),
        Difficulty.moyen => const Duration(milliseconds: 950),
        Difficulty.facile => const Duration(milliseconds: 1250),
      };

  /// Touche une tuile : la pose directement, ou demande le choix de l'extrémité si les deux conviennent.
  void tapTile(DominoTile tile) {
    if (_game.turn != Player.player ||
        _game.roundWinner != null ||
        !playable.any((candidate) => candidate.id == tile.id)) {
      return;
    }
    final fitsLeft = canPlace(tile, _game, DominoSide.left);
    final fitsRight = canPlace(tile, _game, DominoSide.right);
    if (_game.chain.isNotEmpty && fitsLeft && fitsRight && _game.leftEnd != _game.rightEnd) {
      _selectedTileId = _selectedTileId == tile.id ? null : tile.id;
      notifyListeners();
      return;
    }
    _selectedTileId = null;
    _update(playDomino(_game, Player.player, tile.id, fitsRight ? DominoSide.right : DominoSide.left));
  }

  /// Pose la tuile sélectionnée à l'extrémité choisie.
  void playSelected(DominoSide side) {
    final id = _selectedTileId;
    if (id == null) return;
    _selectedTileId = null;
    _update(playDomino(_game, Player.player, id, side));
  }

  /// Pioche si aucun coup n'est possible, sinon ne fait rien ; sans pioche disponible, passe.
  void drawOrPass() {
    if (playable.isNotEmpty) return;
    _update(_game.boneyard.isNotEmpty
        ? drawDomino(_game, Player.player)
        : passDomino(_game, Player.player));
  }

  void startNextRound() {
    _selectedTileId = null;
    _update(newDominoRound(
      targetScore: targetScore,
      scores: _game.scores,
      round: _game.round + 1,
      starter: _game.roundWinner ?? Player.player,
      random: _random,
    ));
  }

  void restart() {
    _selectedTileId = null;
    _update(newDominoRound(targetScore: targetScore, random: _random));
  }

  /// Pierre refusée : sert à faire trembler la pierre concernée (le compteur change à chaque refus).
  String? invalidTileId;
  int invalidCount = 0;

  /// Pioche refusée : fait trembler le bouton (sans message).
  int drawInvalidCount = 0;

  void flagDrawInvalid() {
    drawInvalidCount++;
    notifyListeners();
  }

  void flagInvalid(String tileId) {
    invalidTileId = tileId;
    invalidCount++;
    notifyListeners();
  }

  void _update(DominoState next) {
    _playSoundFor(_game, next);
    _game = next;
    if (next.roundWinner != null) _selectedTileId = null;
    notifyListeners();
    _scheduleAi();
  }

  /// Choisit le son selon ce qui a changé entre deux états.
  void _playSoundFor(DominoState prev, DominoState next) {
    if (next.matchWinner != null && prev.matchWinner == null) {
      Sounds.play(next.matchWinner == Player.player ? Sfx.win : Sfx.lose);
    } else if (next.roundWinner != null && prev.roundWinner == null) {
      Sounds.play(next.roundWinner == Player.player ? Sfx.win : Sfx.lose);
    } else if (next.round != prev.round || (prev.roundWinner != null && next.roundWinner == null)) {
      // Nouvelle manche : distribution des dominos.
      Sounds.play(Sfx.draw);
    } else if (next.chain.length > prev.chain.length) {
      Sounds.play(Sfx.place);
    } else if (next.boneyard.length < prev.boneyard.length) {
      Sounds.play(Sfx.draw);
    } else if (next.turn != prev.turn) {
      Sounds.play(Sfx.pass);
    }
  }

  /// Équivalent du useEffect source : à chaque changement, relance le délai si c'est le tour de l'IA.
  void _scheduleAi() {
    _aiTimer?.cancel();
    if (!isAiTurn) return;
    _aiTimer = Timer(aiDelay, _aiStep);
  }

  void _aiStep() {
    final move = chooseOpponentMove(_game);
    switch (move.action) {
      case DominoAction.play:
        _update(playDomino(_game, Player.opponent, move.tile!.id, move.side!));
      case DominoAction.draw:
        _update(drawDomino(_game, Player.opponent));
      case DominoAction.pass:
        _update(passDomino(_game, Player.opponent));
    }
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }
}
