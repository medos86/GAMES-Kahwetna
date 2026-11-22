import 'package:material_ui/material_ui.dart';

import '../core/reactions/reaction_mood.dart';
import '../core/services/card_animations.dart';

/// Durée de l'apparition du sticker (#760, #788 : plus lente pour bien la voir).
const Duration reactionPopDuration = Duration(milliseconds: 450);

/// Échelle de départ : le sticker part petit et grossit jusqu'à sa taille (#788).
const double reactionPopStartScale = 0.2;

/// Sticker BD de réaction, affiché à côté d'un avatar (#760).
///
/// Une seule apparition : échelle 0,2 → 1 avec rebond, sans boucle ni clignotement.
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
    final reduce = MediaQuery.disableAnimationsOf(context);
    final animate = cardAnimations.value && !reduce;
    final begin = animate ? reactionPopStartScale : 1.0;
    final duration = animate ? reactionPopDuration : Duration.zero;
    return IgnorePointer(
      child: Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(current),
          tween: Tween<double>(begin: begin, end: 1),
          duration: duration,
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Image.asset(
            current.assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return SizedBox(width: size, height: size);
            },
          ),
        ),
      ),
    );
  }
}
