import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/sounds.dart';

/// Retour tactile et sonore d'une capture (#913).
///
/// Capture simple : une petite vibration. Chkobba ou 7AYA : double petite vibration
/// accompagnée d'un petit son.
class CaptureFeedback {
  CaptureFeedback._();

  @visibleForTesting
  static Future<void> Function() vibrate = HapticFeedback.lightImpact;

  /// Deuxième impulsion de la double vibration (sans minuteur : pas de timer en attente).
  @visibleForTesting
  static Future<void> Function() pulse = HapticFeedback.mediumImpact;

  @visibleForTesting
  static Future<void> Function(Sfx) playSound = Sounds.play;

  /// Joue le retour d'une capture. [special] vaut vrai pour Chkobba ou 7AYA.
  static Future<void> onCapture({required bool special}) async {
    // Le retour haptique n'est pas disponible partout (ex. tests sans binding) : jamais bloquant.
    try {
      if (!special) {
        await vibrate();
        return;
      }
      await vibrate();
      await pulse();
      await playSound(Sfx.capture);
    } catch (e) {
      debugPrint('Retour de capture indisponible : $e');
    }
  }
}
