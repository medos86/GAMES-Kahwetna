import 'package:material_ui/material_ui.dart';

import '../core/avatars/avatar_catalog.dart';
import '../core/avatars/turn_avatar_motion.dart';
import '../core/theme/comic_palette.dart';
import 'avatar_view.dart';

/// Médaillon d'avatar en relief (dégradé clair/sombre + ombre) pour le joueur dont c'est le tour.
///
/// Partagé par le Ludo (#665) et le Chkobba (#728) : le joueur actif est agrandi
/// ([activeSize]) et respire doucement ; les autres gardent [baseSize], atténués.
/// Sans animation (réglage système), le relief seul reste affiché.
class TurnAvatar extends StatefulWidget {
  const TurnAvatar({
    super.key,
    required this.tone,
    required this.active,
    required this.avatarId,
    required this.state,
    required this.semanticLabel,
    required this.baseSize,
    required this.activeSize,
  });

  /// Couleur du joueur : sert au relief du médaillon.
  final Color tone;
  final bool active;
  final String avatarId;
  final AvatarState state;
  final String semanticLabel;

  /// Taille de l'avatar inactif, en dp.
  final double baseSize;

  /// Taille de l'avatar du joueur dont c'est le tour, en dp.
  final double activeSize;

  @override
  State<TurnAvatar> createState() => _TurnAvatarState();
}

class _TurnAvatarState extends State<TurnAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant TurnAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Respiration seulement pour le joueur actif, et seulement si les animations sont voulues.
  void _sync() {
    if (widget.active && _animate) {
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.active ? widget.activeSize : widget.baseSize;
    final box = size + 6;
    final light = Color.lerp(widget.tone, ComicPalette.white, 0.45)!;
    final dark = Color.lerp(widget.tone, ComicPalette.ink, 0.35)!;
    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: box,
      height: box,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Relief : dégradé clair en haut à gauche, sombre en bas à droite.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, widget.tone, dark],
        ),
        boxShadow: widget.active
            ? [
                BoxShadow(
                  color: ComicPalette.ink.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: AvatarView(
          avatarId: widget.avatarId,
          state: widget.state,
          size: size,
          // Joueur dont c'est le tour : pleine opacité, sans grisé (#663).
          // Les autres restent atténués. Le relief de la couleur fait office d'anneau.
          isActive: widget.active,
          semanticLabel: widget.semanticLabel,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) => Transform.scale(
        scale: widget.active && _animate
            ? turnAvatarBreathScale(_breath.value)
            : 1,
        child: child,
      ),
      child: badge,
    );
  }
}
