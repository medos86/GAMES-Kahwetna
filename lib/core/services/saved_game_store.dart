import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sauvegarde d'une partie en cours, une clé par jeu (#112).
abstract interface class SavedGameStore {
  Future<Map<String, dynamic>?> load(String game);
  Future<void> save(String game, Map<String, dynamic> json);
  Future<void> clear(String game);
}

/// Stockage réel : `shared_preferences`, une entrée JSON par jeu.
class SharedPreferencesSavedGameStore implements SavedGameStore {
  const SharedPreferencesSavedGameStore();

  static String keyFor(String game) => 'kahwetne-save-$game';

  @override
  Future<Map<String, dynamic>?> load(String game) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyFor(game));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      await prefs.remove(keyFor(game));
      return null;
    }
  }

  @override
  Future<void> save(String game, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyFor(game), jsonEncode(json));
  }

  @override
  Future<void> clear(String game) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyFor(game));
  }
}
