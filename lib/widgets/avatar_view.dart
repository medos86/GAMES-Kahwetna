import 'package:material_ui/material_ui.dart';

import '../core/avatars/avatar_catalog.dart';
import '../core/avatars/avatar_config.dart';
import '../core/services/card_animations.dart';
import '../core/theme/comic_palette.dart';

/// Avatar dans un cercle, dans l'état demandé (issue #545).
///
/// [size] est en dp. Les petites tailles (barre de score) sont permises : la cible
/// tactile de 48 dp est alors assurée par le parent. Sans image, affiche l'initiale
/// de [semanticLabel] sur fond neutre.
///
/// [isActive] (issue #557) : joueur dont c'est le tour. Actif : pleine opacité,
/// anneau et léger agrandissement. Inactif : opacité 0,55, sans anneau.
/// Les transitions suivent le réglage des animations (#224).
class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    required this.avatarId,
    this.state = AvatarState.neutral,
    this.size = 48,
    this.semanticLabel = 'Avatar',
    this.isActive = true,
  });

  final String avatarId;
  final AvatarState state;
  final double size;
  final String semanticLabel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarById(avatarId);
    final displaySize = effectiveAvatarSize(size);
    final duration = cardAnimations.value
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final image = SizedBox(
      width: displaySize,
      height: displaySize,
      child: Image.asset(
        avatar.assetFor(state),
        fit: BoxFit.cover,
        filterQuality: AvatarConfig.filterQuality,
        errorBuilder: (_, __, ___) => _InitialFallback(
          label: semanticLabel,
          size: displaySize,
        ),
      ),
    );
    final ring = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? ComicPalette.yellow : Colors.transparent,
          width: 3,
        ),
      ),
      child: ClipOval(child: image),
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: AnimatedScale(
        scale: isActive ? 1.08 : 1,
        duration: duration,
        child: AnimatedOpacity(
          opacity: isActive ? 1 : 0.55,
          duration: duration,
          child: ring,
        ),
      ),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return ColoredBox(
      color: const Color(0xFFE0E0E0),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
