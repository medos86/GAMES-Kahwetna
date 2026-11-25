import 'package:material_ui/material_ui.dart';

import '../../core/i18n/app_language.dart';
import '../../core/services/card_animations.dart';
import '../../core/services/reaction_stickers.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/comic/comic_backdrop.dart';
import '../../widgets/comic/comic_panel.dart';
import 'age_section.dart';
import 'profile_section.dart';

/// Écran Paramètres (issue #116) : langue et animations de cartes, ainsi que le profil
/// et l'âge. Accessible depuis le bouton Configuration du menu principal.
/// Le choix est sauvegardé et appliqué tout de suite.
///
/// Réglages regroupés par thème (issue #636) : Profil, Affichage, Âge.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mise en page en LTR même en arabe (#241) : les réglages gardent leur place d'une langue à l'autre.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, language, _) => Directionality(
        textDirection: TextDirection.ltr,
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
          body: ComicBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profil en tête des réglages (#547) : pseudo et avatar.
                  const ProfileSection(),
                  const SizedBox(height: 24),
                  // Réponse à la question d'âge, modifiable (issue #568).
                  const AgeSection(),
                  const SizedBox(height: 24),
                  _SettingsGroup(
                    title: t('settingsDisplay'),
                    children: [
                      _SettingRow(
                        label: t('settingsLanguage'),
                        trailing: SegmentedButton<AppLanguage>(
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
                      ),
                      // Animations de cartes (#224) : activées par défaut (#900).
                      _SettingRow(
                        label: t('settingsCardAnimations'),
                        trailing: ValueListenableBuilder<bool>(
                          valueListenable: cardAnimations,
                          builder: (context, on, _) => Switch(
                            value: on,
                            onChanged: setCardAnimations,
                          ),
                        ),
                      ),
                      // Réactions BD à côté des avatars (#762) : activées par défaut.
                      _SettingRow(
                        label: t('settingsReactionStickers'),
                        trailing: ValueListenableBuilder<bool>(
                          valueListenable: reactionStickers,
                          builder: (context, on, _) => Switch(
                            value: on,
                            onChanged: setReactionStickers,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Groupe de réglages : titre en capitales, puis les lignes dans une case BD (issue #636).
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: ComicPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        ComicPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// Ligne de réglage : au moins 48 px de haut, valeur à droite (règles UI de #116).
class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ComicPalette.ink,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
