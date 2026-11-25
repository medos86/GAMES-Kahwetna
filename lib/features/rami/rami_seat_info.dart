import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/comic_button.dart';
import '../../widgets/result_dialog.dart';

/// Popup d'un siège, ouvert en touchant son avatar (#887) : pseudo en titre,
/// puis score et nombre de cartes en main. Style BD, comme les autres boîtes de dialogue.
class RamiSeatInfo {
  const RamiSeatInfo._();

  static Future<void> show(
    BuildContext context, {
    required String name,
    required int score,
    required int cards,
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
          _SeatInfoLine(label: Strings.seatInfoScore, value: '$score'),
          _SeatInfoLine(label: Strings.seatInfoCards, value: '$cards'),
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

class _SeatInfoLine extends StatelessWidget {
  const _SeatInfoLine({required this.label, required this.value});

  final String label;
  final String value;

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
