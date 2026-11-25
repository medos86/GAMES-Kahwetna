import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglage « Animations des cartes » (#224). Activé par défaut (#900).
final ValueNotifier<bool> cardAnimations = ValueNotifier(true);

const cardAnimationsPrefsKey = 'kahwetne.cardAnimations';

/// Relit le réglage sauvegardé. Sans préférence lisible, il reste activé.
Future<void> loadCardAnimations() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    cardAnimations.value = prefs.getBool(cardAnimationsPrefsKey) ?? true;
  } catch (_) {
    cardAnimations.value = true;
  }
}

/// Change le réglage et le sauvegarde.
Future<void> setCardAnimations(bool enabled) async {
  cardAnimations.value = enabled;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(cardAnimationsPrefsKey, enabled);
  } catch (_) {
    // Préférence non sauvegardée : le réglage vaut pour la session en cours.
  }
}
