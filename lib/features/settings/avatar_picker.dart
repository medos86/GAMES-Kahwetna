import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/pressable.dart';

/// Grille de choix d'avatar en bottom sheet (issue #548).
/// Retourne l'identifiant choisi, ou null si annulé. [takenIds] : avatars pris (#549).
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

/// Feuille de choix (issue #637) : aperçu en haut, grille à sélection visible
/// sans seulement la couleur, validation explicite (Choisir / Annuler).
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
    // Toucher un avatar ne fait que l'aperçu : rien n'est enregistré avant Choisir.
    final isCurrent = _selected == widget.currentId;
    return SafeArea(
      child: SingleChildScrollView(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarView(
                  avatarId: _selected,
                  size: 72,
                  semanticLabel: _selected,
                ),
                const SizedBox(width: 12),
                Text(
                  isCurrent ? Strings.pickerCurrent : Strings.pickerPreview,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ComicPalette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
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

/// Case d'un avatar. Sélection : fond jaune, contour épais et pastille ✓ (pas
/// seulement la couleur). Pris : estompé avec l'étiquette « Pris » (#549).
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
    return Semantics(
      selected: selected,
      child: Pressable(
        semanticLabel: avatarId,
        onTap: taken ? null : onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: taken ? 0.35 : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ComicPalette.yellow : Colors.transparent,
                  border: Border.all(
                    color: selected ? ComicPalette.ink : Colors.transparent,
                    width: 4,
                  ),
                ),
                child: AvatarView(
                  avatarId: avatarId,
                  size: 52,
                  semanticLabel: avatarId,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ComicPalette.ink,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: ComicPalette.white,
                    ),
                  ),
                ),
              ),
            if (taken)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ComicPalette.ink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    Strings.pickerTaken,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: ComicPalette.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
