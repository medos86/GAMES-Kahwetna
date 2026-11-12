import 'dart:async';

import 'package:flutter/foundation.dart';

import 'saved_game_store.dart';

/// Base des contrôleurs de partie qui sauvegardent la partie en cours (#112).
///
/// - Chaque notification enregistre l'état (sauf pendant la question « Reprendre ? »).
/// - Partie terminée : la sauvegarde est effacée.
/// - Sans [store] (tests) : aucune sauvegarde, comportement inchangé.
abstract class PersistentGameController extends ChangeNotifier {
  PersistentGameController({this.store, required this.gameKey});

  final SavedGameStore? store;
  final String gameKey;

  bool _ready = false;
  Map<String, dynamic>? _saved;

  /// Vrai quand une partie sauvegardée attend la décision du joueur.
  bool get awaitingResume => _saved != null;

  /// État à sauvegarder, ou null si la partie est terminée.
  @protected
  Map<String, dynamic>? snapshot();

  /// Remet en place un état sauvegardé.
  @protected
  void applySnapshot(Map<String, dynamic> json);

  /// Relance le jeu après un état restauré (minuteurs IA, etc.).
  @protected
  void startFresh();

  /// Démarre une nouvelle partie du même réglage.
  @protected
  void newGame();

  @override
  void notifyListeners() {
    if (_ready && store != null && _saved == null) _persist();
    super.notifyListeners();
  }

  void _persist() {
    final s = store;
    if (s == null) return;
    final json = snapshot();
    unawaited(json == null ? s.clear(gameKey) : s.save(gameKey, json));
  }

  /// À appeler une fois après la construction, avant d'afficher le jeu.
  Future<void> restore() async {
    final s = store;
    if (s == null) {
      _ready = true;
      return;
    }
    final saved = await s.load(gameKey);
    _ready = true;
    if (saved != null) {
      _saved = saved;
      super.notifyListeners();
      return;
    }
    startFresh();
  }

  /// « Reprendre » : remet la partie sauvegardée en place.
  void resume() {
    final json = _saved;
    if (json == null) return;
    _saved = null;
    applySnapshot(json);
    startFresh();
    notifyListeners();
  }

  /// « Nouvelle partie » : efface la sauvegarde de ce jeu et repart à zéro.
  Future<void> discardSaved() async {
    _saved = null;
    await store?.clear(gameKey);
    newGame();
  }
}
