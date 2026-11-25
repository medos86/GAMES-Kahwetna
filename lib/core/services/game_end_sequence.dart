import 'dart:async';

import 'package:flutter/foundation.dart';

/// Séquence de fin de partie : la pub passe d'abord, l'animation gain/perte ensuite.
///
/// [start] lance la pub (fournie par l'appelant) et ne révèle la fin qu'à sa
/// fermeture. Sans pub (mode sans pub, pas chargée, erreur), la fin est révélée
/// tout de suite. Une erreur de pub ne bloque jamais l'écran de fin.
/// Chaque nouvelle fin repart de « non révélée » (issue #932).
class GameEndSequence {
  final ValueNotifier<bool> _revealed = ValueNotifier<bool>(false);

  /// `true` quand l'écran de fin (et son animation) peut être affiché.
  ValueListenable<bool> get revealed => _revealed;

  /// Lance la pub puis révèle la fin. Ne se termine pas toujours tout de suite.
  void start(Future<Object?> Function() showAd) {
    _revealed.value = false;
    unawaited(_run(showAd));
  }

  Future<void> _run(Future<Object?> Function() showAd) async {
    try {
      await showAd();
    } catch (_) {
      // Optionnel : la pub ne doit jamais bloquer le résultat.
    } finally {
      _revealed.value = true;
    }
  }

  /// Remet la séquence à zéro (nouvelle partie).
  void reset() => _revealed.value = false;

  void dispose() => _revealed.dispose();
}
