import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'translations.dart';

/// Langues de l'application (issue #100 : FR et AR).
enum AppLanguage { fr, ar }

/// Langue courante. Modifier `appLanguage.value` pour changer de langue.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.fr);

/// Clé de sauvegarde de la langue choisie (#116).
const String languagePrefsKey = 'kahwetne.language';

/// Relit la langue sauvegardée. À appeler une fois au démarrage ; sans sauvegarde, reste en français.
Future<void> loadLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(languagePrefsKey);
    for (final language in AppLanguage.values) {
      if (language.name == saved) appLanguage.value = language;
    }
  } catch (_) {
    // Stockage indisponible : on garde le français par défaut.
  }
}

/// Change la langue et la sauvegarde. L'interface se met à jour immédiatement.
Future<void> setLanguage(AppLanguage language) async {
  appLanguage.value = language;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(languagePrefsKey, language.name);
  } catch (_) {
    // Échec d'écriture : la langue reste active pour la session.
  }
}

/// Vrai en arabe : la mise en page passe en RTL.
bool isRtl(AppLanguage language) => language == AppLanguage.ar;

Locale localeOf(AppLanguage language) => Locale(language.name);

/// Texte de la langue courante. Repli sur le français, puis sur la clé elle-même.
String t(String key) {
  if (appLanguage.value == AppLanguage.ar) {
    return arTexts[key] ?? frTexts[key] ?? key;
  }
  return frTexts[key] ?? key;
}

/// Texte avec remplacements `{nom}` (ex. `tf('ludoPlayers', {'n': '2'})`). Repli sur la clé.
String tf(String key, Map<String, String> args) {
  var text = t(key);
  args.forEach((name, value) => text = text.replaceAll('{$name}', value));
  return text;
}
