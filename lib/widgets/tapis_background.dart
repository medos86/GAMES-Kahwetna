import 'package:flutter/widgets.dart';

import '../core/theme/comic_palette.dart';

/// Fond « tapis » plein écran : feutre uni + motif de la porte utilisé comme masque
/// (alpha = encre du dessin), répété et teinté en or.
class TapisBackground extends StatelessWidget {
  const TapisBackground({super.key});

  static const String motifAsset = 'assets/images/tapis/tapis_motif.png';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('tapis-background'),
      decoration: const BoxDecoration(
        color: ComicPalette.felt,
        image: DecorationImage(
          image: AssetImage(motifAsset),
          repeat: ImageRepeat.repeat,
          scale: 2.0,
          colorFilter: ColorFilter.mode(
            Color(0x66FFE16B),
            BlendMode.srcIn,
          ),
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
