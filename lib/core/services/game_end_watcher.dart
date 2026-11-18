/// Détecte la fin d'une partie et la signale une seule fois (issue #472).
///
/// Chaque écran de jeu appelle [check] à chaque changement d'état ; [onEnded]
/// n'est déclenché qu'à la transition « en cours → terminée ».
class GameEndWatcher {
  GameEndWatcher({required this.isEnded, required this.onEnded});

  /// Vrai quand la partie courante est terminée.
  final bool Function() isEnded;

  /// Appelé une fois par fin de partie.
  final void Function() onEnded;

  bool _notified = false;

  void check() {
    if (!isEnded()) {
      _notified = false;
      return;
    }
    if (_notified) return;
    _notified = true;
    onEnded();
  }
}
