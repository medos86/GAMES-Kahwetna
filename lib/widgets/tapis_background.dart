import 'package:flutter/widgets.dart';

import '../core/theme/comic_palette.dart';

/// Fond « tapis » plein écran : fond bleu + masque de la photo (#705) répété sans changer son ratio
/// (alpha = encre du dessin), répété et teinté en or.
class TapisBackground extends StatelessWidget {
  const TapisBackground({super.key, this.color = ComicPalette.tunisBlue});

  /// Couleur de fond sous le motif (#752 : bleu BD pour la Chkobba).
  final Color color;

  static const String motifAsset = 'assets/images/tapis/tapis_masque.png';

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('tapis-background'),
      decoration: const BoxDecoration(
        color: color,
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
