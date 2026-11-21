import 'package:material_ui/material_ui.dart';

import '../../core/theme/ludo_backdrop_palette.dart';

/// Image-masque du fond Ludo (dessin en traits, compressé en WebP).
const ludoBackdropMaskAsset = 'assets/images/ludo/ludo_backdrop_mask.webp';

/// Fond du Ludo : dégradé bleu et dessin en traits appliqué comme masque.
class LudoBackdrop extends StatelessWidget {
  const LudoBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LudoBackdropPalette.top,
            LudoBackdropPalette.middle,
            LudoBackdropPalette.bottom,
          ],
        ),
      ),
      child: Image.asset(
        ludoBackdropMaskAsset,
        fit: BoxFit.cover,
        color: LudoBackdropPalette.maskTint,
        colorBlendMode: BlendMode.srcIn,
        gaplessPlayback: true,
      ),
    );
  }
}
