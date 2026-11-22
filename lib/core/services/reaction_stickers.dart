import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglage « Réactions BD » (#762). Activé par défaut.
final ValueNotifier<bool> reactionStickers = ValueNotifier(true);

const reactionStickersPrefsKey = 'kahwetne.reactionStickers';

/// Relit le réglage sauvegardé. Sans préférence lisible, il reste activé.
Future<void> loadReactionStickers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    reactionStickers.value = prefs.getBool(reactionStickersPrefsKey) ?? true;
  } catch (_) {
    reactionStickers.value = true;
  }
}

/// Change le réglage et le sauvegarde.
Future<void> setReactionStickers(bool enabled) async {
  reactionStickers.value = enabled;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(reactionStickersPrefsKey, enabled);
  } catch (_) {
    // Préférence non sauvegardée : le réglage vaut pour la session en cours.
  }
}
