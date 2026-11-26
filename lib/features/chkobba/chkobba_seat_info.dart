import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/comic_button.dart';
import '../../widgets/result_dialog.dart';

/// Popup d'un joueur de la Chkobba, ouvert en touchant son avatar (#984) :
/// nombre de cartes gagnées et nombre de Chkobbas, lus dans l'état de jeu.
/// Se ferme par le bouton « Fermer » ou en touchant hors de la boîte.
class ChkobbaSeatInfo {
  const ChkobbaSeatInfo._();

  static Future<void> show(
    BuildContext context, {
    required String name,
    required int wonCards,
    required int chkobbas,
    required String avatarId,
    required AvatarState avatarState,
  }) {
    return ResultDialog.show<void>(
      context,
      dismissible: true,
      builder: (dialogContext) => ResultDialog(
        title: name,
        accent: ComicPalette.gold,
        children: [
          Center(
            child: AvatarView(
              avatarId: avatarId,
              state: avatarState,
              size: 72,
              semanticLabel: name,
            ),
          ),
          const SizedBox(height: 12),
          _ChkobbaSeatInfoLine(
            label: Strings.seatWonCards,
            value: '$wonCards',
            valueKey: const ValueKey('seat-info:won'),
          ),
          _ChkobbaSeatInfoLine(
            label: Strings.seatChkobbas,
            value: '$chkobbas',
            valueKey: const ValueKey('seat-info:chkobbas'),
          ),
        ],
        actions: [
          ComicButton(
            label: Strings.close,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}

class _ChkobbaSeatInfoLine extends StatelessWidget {
  const _ChkobbaSeatInfoLine({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.current;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 20,
                letterSpacing: 0.8,
                color: ComicPalette.ink,
              ),
            ),
          ),
          Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: style.felt,
            ),
          ),
        ],
      ),
    );
  }
}
