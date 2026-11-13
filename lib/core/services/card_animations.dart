import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglage « Animations des cartes » (#224). Coupé par défaut : le comportement reste celui d'avant.
final ValueNotifier<bool> cardAnimations = ValueNotifier(false);

const cardAnimationsPrefsKey = 'kahwetne.cardAnimations';

/// Relit le réglage sauvegardé. Sans préférence lisible, il reste coupé.
Future<void> loadCardAnimations() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    cardAnimations.value = prefs.getBool(cardAnimationsPrefsKey) ?? false;
  } catch (_) {
    cardAnimations.value = false;
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
