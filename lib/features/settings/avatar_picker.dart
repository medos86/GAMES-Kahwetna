import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/pressable.dart';

/// Grille de choix d'avatar en bottom sheet (issue #548).
/// Retourne l'identifiant choisi, ou null si annulé. [takenIds] : avatars grisés (#549).
Future<String?> showAvatarPicker(
  BuildContext context, {
  required String currentId,
  Set<String> takenIds = const {},
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: ComicPalette.paper,
    builder: (_) => _AvatarPickerSheet(
      currentId: currentId,
      takenIds: takenIds,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  const _AvatarPickerSheet({required this.currentId, required this.takenIds});

  final String currentId;
  final Set<String> takenIds;

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late String _selected = widget.currentId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Strings.pickerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: ComicPalette.ink,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final avatar in avatarCatalog)
                  _Choice(
                    avatarId: avatar.id,
                    selected: avatar.id == _selected,
                    taken: widget.takenIds.contains(avatar.id),
                    onTap: () => setState(() => _selected = avatar.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(Strings.pickerCancel),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(Strings.pickerConfirm),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.avatarId,
    required this.selected,
    required this.taken,
    required this.onTap,
  });

  final String avatarId;
  final bool selected;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: avatarId,
      onTap: taken ? null : onTap,
      child: Opacity(
        opacity: taken ? 0.35 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ComicPalette.yellow : Colors.transparent,
              width: 4,
            ),
          ),
          child: AvatarView(
            avatarId: avatarId,
            size: 64,
            semanticLabel: avatarId,
          ),
        ),
      ),
    );
  }
}
