import 'package:material_ui/material_ui.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../widgets/avatar_view.dart';

/// Avatar miniature posé sur le bord d'un paquet, à la place du pseudo (#942).
/// Un simple médaillon : la couleur du siège encadre l'avatar.
class RamiMeldOwnerTag extends StatelessWidget {
  const RamiMeldOwnerTag({
    super.key,
    required this.avatarId,
    required this.color,
    this.state = AvatarState.neutral,
  });

  /// Taille du médaillon, en pixels logiques.
  static const double size = 16;

  final String avatarId;
  final Color color;
  final AvatarState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('rami-meld-owner-tag'),
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 1),
      ),
      child: AvatarView(
        avatarId: avatarId,
        state: state,
        size: size,
        semanticLabel: 'Avatar du paquet',
      ),
    );
  }
}
