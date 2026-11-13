import 'package:material_ui/material_ui.dart';

import '../../core/services/card_animations.dart';

import '../../core/i18n/app_language.dart';
import '../../core/theme/comic_palette.dart';

/// Écran Paramètres (issue #116) : pour l'instant seul le choix de la langue (FR / عربي).
/// Accessible depuis le menu principal. Le choix est sauvegardé et appliqué tout de suite.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Direction explicite sur cet écran (#157) : la flèche et les libellés suivent la langue choisie.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Directionality(
        textDirection: isRtl(language) ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: ComicPalette.paper,
          appBar: AppBar(
            backgroundColor: ComicPalette.paper,
            foregroundColor: ComicPalette.ink,
            elevation: 0,
            title: Text(
              t('settingsTitle'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: ComicPalette.ink,
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  t('settingsDisplay').toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: ComicPalette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                // Ligne de réglage : au moins 48 px de haut, valeur à droite (règles UI de #116).
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('settingsLanguage'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ComicPalette.ink,
                          ),
                        ),
                      ),
                      SegmentedButton<AppLanguage>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          backgroundColor: ComicPalette.paper,
                          foregroundColor: ComicPalette.ink,
                          selectedBackgroundColor: ComicPalette.yellow,
                          selectedForegroundColor: ComicPalette.ink,
                          side: const BorderSide(
                            color: ComicPalette.ink,
                            width: 2,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        segments: [
                          ButtonSegment(
                            value: AppLanguage.fr,
                            label: Text(t('langFrench')),
                          ),
                          ButtonSegment(
                            value: AppLanguage.ar,
                            label: Text(t('langArabic')),
                          ),
                        ],
                        selected: {language},
                        onSelectionChanged: (selection) =>
                            setLanguage(selection.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Animations de cartes (#224) : coupées par défaut.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t('settingsCardAnimations'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ComicPalette.ink,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: cardAnimations,
                        builder: (context, on, _) => Switch(
                          value: on,
                          onChanged: setCardAnimations,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
