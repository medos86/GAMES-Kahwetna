import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/core/i18n/translations.dart';
import 'package:kahwetne/core/strings.dart';

void main() {
  // Parité : chaque texte existe en français ET en arabe (issue #100).
  test('chaque clé a une traduction arabe et une française', () {
    expect(arTexts.keys.toSet(), frTexts.keys.toSet());
  });

  test('aucun texte vide', () {
    for (final entry in [...frTexts.entries, ...arTexts.entries]) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
  });

  test('chaque texte arabe contient des lettres arabes', () {
    final arabic = RegExp(r'[؀-ۿ]');
    for (final entry in arTexts.entries) {
      expect(arabic.hasMatch(entry.value), isTrue, reason: entry.key);
    }
  });

  test('t() suit la langue courante, avec repli sur le français', () {
    appLanguage.value = AppLanguage.fr;
    expect(Strings.menuStart, 'Commencer à jouer');
    appLanguage.value = AppLanguage.ar;
    expect(Strings.menuStart, 'ابدأ اللعب');
    expect(t('clé_inconnue'), 'clé_inconnue');
    appLanguage.value = AppLanguage.fr;
  });

  test('l\'arabe passe en RTL, le français en LTR', () {
    expect(isRtl(AppLanguage.ar), isTrue);
    expect(isRtl(AppLanguage.fr), isFalse);
    expect(localeOf(AppLanguage.ar).languageCode, 'ar');
  });

  test('tf remplace les paramètres {n} dans la langue courante', () {
    appLanguage.value = AppLanguage.fr;
    expect(tf('ludoPlayers', {'n': '2'}), '2 joueurs');
    appLanguage.value = AppLanguage.ar;
    expect(tf('ludoPlayers', {'n': '2'}), '2 لاعبين');
    appLanguage.value = AppLanguage.fr;
  });
}
