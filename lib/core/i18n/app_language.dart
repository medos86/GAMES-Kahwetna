import 'package:flutter/material.dart';

import 'translations.dart';

/// Langues de l'application (issue #100 : FR et AR).
enum AppLanguage { fr, ar }

/// Langue courante. Modifier `appLanguage.value` pour changer de langue.
final ValueNotifier<AppLanguage> appLanguage = ValueNotifier(AppLanguage.fr);

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
