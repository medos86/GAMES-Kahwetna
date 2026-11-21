import 'package:material_ui/material_ui.dart';

import '../core/theme/comic_palette.dart';
import 'avatar_view.dart';
import 'pressable.dart';

/// Pastille « avatar + pseudo » du menu (issue #546). Tap : ouvre les réglages du profil.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.name,
    required this.avatarId,
    required this.onTap,
  });

  final String name;
  final String avatarId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Pressable(
        semanticLabel: name,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: const Color(0x66141630),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarView(avatarId: avatarId, size: 40, semanticLabel: name),
              const SizedBox(width: 8),
              // Pseudo en MAJUSCULES, style BD (#721) : Bangers, contour d'encre.
              // FittedBox ne réduit que si la largeur ne suffit vraiment pas.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _comicName(name.toUpperCase()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Texte BD : remplissage blanc, contour d'encre (même principe que le titre).
  Widget _comicName(String text) {
    const size = 24.0;
    final base = TextStyle(
      fontFamily: 'Bangers',
      fontSize: size,
      height: 1,
      letterSpacing: 1.5,
    );
    return Stack(
      children: [
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.14
              ..strokeJoin = StrokeJoin.round
              ..color = ComicPalette.ink,
          ),
        ),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: base.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
