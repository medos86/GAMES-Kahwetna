import 'package:material_ui/material_ui.dart';

import '../core/avatars/avatar_catalog.dart';

/// Avatar dans un cercle, dans l'état demandé (issue #545).
///
/// [size] est en dp. Les petites tailles (barre de score) sont permises : la cible
/// tactile de 48 dp est alors assurée par le parent. Sans image, affiche l'initiale
/// de [semanticLabel] sur fond neutre.
class AvatarView extends StatelessWidget {
  const AvatarView({
    super.key,
    required this.avatarId,
    this.state = AvatarState.neutral,
    this.size = 48,
    this.semanticLabel = 'Avatar',
  });

  final String avatarId;
  final AvatarState state;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final avatar = avatarById(avatarId);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            avatar.assetFor(state),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _InitialFallback(
              label: semanticLabel,
              size: size,
            ),
          ),
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
