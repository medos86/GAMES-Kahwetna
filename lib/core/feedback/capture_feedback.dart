import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/sounds.dart';

/// Retour tactile et sonore d'une capture (#913).
///
/// Capture simple : une petite vibration. Chkobba ou 7AYA : double petite vibration
/// accompagnée d'un petit son.
class CaptureFeedback {
  CaptureFeedback._();

  /// Pause entre les deux impulsions de la double vibration.
  static const Duration doublePulseGap = Duration(milliseconds: 120);

  @visibleForTesting
  static Future<void> Function() vibrate = HapticFeedback.lightImpact;

  @visibleForTesting
  static Future<void> Function() pulse = HapticFeedback.lightImpact;

  @visibleForTesting
  static Future<void> Function(Duration) wait =
      (duration) => Future<void>.delayed(duration);

  @visibleForTesting
  static Future<void> Function(Sfx) playSound = Sounds.play;

  /// Joue le retour d'une capture. [special] vaut vrai pour Chkobba ou 7AYA.
  static Future<void> onCapture({required bool special}) async {
    if (!special) {
      await vibrate();
      return;
    }
    await pulse();
    await wait(doublePulseGap);
    await pulse();
    await playSound(Sfx.capture);
  }
}
