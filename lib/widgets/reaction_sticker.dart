import 'package:material_ui/material_ui.dart';

import '../core/reactions/reaction_mood.dart';
import '../core/services/card_animations.dart';

/// Sticker BD de réaction, affiché à côté d'un avatar (#760).
///
/// Une seule apparition : échelle 0,6 → 1 en 250 ms, sans boucle.
/// Réduire les animations (système ou réglage de l'app) : affichage immédiat.
/// [IgnorePointer] : ne bloque jamais les cartes ni les boutons.
/// Sans humeur ([mood] nul) : rien n'est rendu, aucune place n'est réservée.
class ReactionSticker extends StatelessWidget {
  const ReactionSticker({
    super.key,
    required this.mood,
    this.size = 48,
    this.semanticLabel = 'Réaction',
  });

  final ReactionMood? mood;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final current = mood;
    if (current == null) return const SizedBox.shrink();
    final animate =
        cardAnimations.value && !MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(current),
          tween: Tween<double>(begin: animate ? 0.6 : 1, end: 1),
          duration:
              animate ? const Duration(milliseconds: 250) : Duration.zero,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Image.asset(
            current.assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
          ),
        ),
      ),
    );
  }
}
