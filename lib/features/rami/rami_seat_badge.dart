import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';

import '../../core/avatars/avatar_catalog.dart';
import '../../widgets/turn_avatar.dart';

/// Ordre de distribution : une carte à gauche, en haut, à droite, puis à moi en bas (#532, #589).
/// Les indices sont ceux des sièges (0 = moi, 1 = Ali à gauche, 2 = Karim en haut, 3 = Sami à droite).
const ramiDealSeatOrder = [1, 2, 3, 0];

/// Côté du tapis où s'affiche le badge d'un siège (#589, #838).
/// Sens horaire depuis moi : le joueur suivant est à ma gauche. Mon badge est en bas, à droite de la défausse (#861).
Alignment ramiSeatAlignment(int seat) {
  switch (seat) {
    case 0:
      return Alignment.bottomRight;
    case 1:
      return Alignment.centerLeft;
    case 2:
      return Alignment.topCenter;
    case 3:
      return Alignment.centerRight;
    default:
      throw ArgumentError.value(seat, 'seat', 'siège attendu (0 à 3)');
  }
}

/// Quart de tour du badge (#666) : les sièges latéraux (gauche, droite) sont écrits
/// verticalement, pour libérer de la place pour les cartes. Le haut reste horizontal.
int ramiSeatQuarterTurns(int seat) {
  if (seat == 1) return 3;
  if (seat == 3) return 1;
  return 0;
}

/// Badge d'un siège posé sur le tapis : médaillon d'avatar, agrandi quand c'est son tour (#838).
/// Le pseudo et le nombre de cartes ne sont plus affichés à côté de l'avatar (#887) : ils
/// sont dans le popup ouvert par [onTap], et restent lus par les lecteurs d'écran.
/// Passif et superposé, il ne prend aucune place dans la mise en page.
class RamiSeatBadge extends StatelessWidget {
  const RamiSeatBadge({
    super.key,
    required this.name,
    required this.cards,
    this.avatarId,
    this.avatarState = AvatarState.neutral,
    this.quarterTurns = 0,
    this.active = false,
    this.onTap,
  });

  final String name;
  final int cards;

  /// Avatar du siège (issue #552) ; absent, le badge reste textuel.
  final String? avatarId;
  final AvatarState avatarState;

  /// Quarts de tour appliqués au badge (#666) : 3 à gauche, 1 à droite, 0 en haut.
  final int quarterTurns;

  /// Joueur dont c'est le tour : médaillon agrandi et pastille dorée (#838).
  final bool active;

  /// Touche sur l'avatar : ouvre le popup du siège (#887).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = avatarId;
    final content = id == null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFE16B) : const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ComicPalette.ink, width: 2),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF20284B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        : TurnAvatar(
            tone: ComicPalette.ink,
            active: active,
            avatarId: id,
            state: avatarState,
            semanticLabel: name,
            baseSize: 28,
            activeSize: 40,
          );
    final labelled = Semantics(
      label: '$name, $cards cartes',
      button: onTap != null,
      child: ExcludeSemantics(child: content),
    );
    final tappable = onTap == null
        ? labelled
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: labelled,
          );
    if (quarterTurns == 0) return tappable;
    return RotatedBox(quarterTurns: quarterTurns, child: tappable);
  }
}
