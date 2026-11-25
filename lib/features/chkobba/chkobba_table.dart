import 'package:material_ui/material_ui.dart';

import '../../core/theme/game_style.dart';
import '../../core/theme/scoba_palette.dart';
import '../../widgets/comic/action_burst.dart';

/// Tapis de Chkobba (#745) : feutre vert sans cadre intérieur (#766 retiré), cartes en grille.
/// `cards` contient un élément par emplacement ; null = emplacement vide.
class ChkobbaTable extends StatelessWidget {
  const ChkobbaTable({
    super.key,
    required this.cards,
    required this.columns,
    this.emptyLabel,
  });

  final List<Widget?> cards;
  final int columns;

  /// Texte affiché au centre quand la table est vide (« Chkobba ! »).
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final tableEmpty = cards.whereType<Widget>().isEmpty;

    // Feutre plein, sans trame de points (comme Rami) : seul le vert reste.
    // Les cartes se rangent depuis le haut à gauche, sans cases vides (style Rami).
    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: ScobaPalette.tapisVert),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final card in cards)
                    if (card != null) _CardInCell(child: card),
                ],
              ),
            ),
          ),
          if (tableEmpty && emptyLabel != null)
            Center(
              child: ChkobbaBanner(
                text: emptyLabel!,
                colors: GameStyle.current.chkobbaGradient,
                angle: -0.1,
              ),
            ),
        ],
      ),
    );
  }
}

/// Largeur maximale d'une carte posée sur le tapis : plus petites pour alléger le tapis.
const double kChkobbaTableCardWidth = 52;

/// Carte posée sur le tapis : proportions 5/7 conservées, largeur plafonnée.
class _CardInCell extends StatelessWidget {
  const _CardInCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kChkobbaTableCardWidth,
      child: AspectRatio(aspectRatio: 5 / 7, child: child),
    );
  }
}

/// Bannière comic (texte contouré, dégradé, légèrement penchée) : « Chkobba ! », « 7AYA ! ».
class ChkobbaBanner extends StatelessWidget {
  const ChkobbaBanner({
    super.key,
    required this.text,
    required this.colors,
    this.angle = -0.1,
    this.burstSize = 150,
  });

  final String text;
  final List<Color> colors;
  final double angle;

  /// Taille de l'éclat BD (style comic) : plus petite pour « 7AYA ! » (#364).
  final double burstSize;

  @override
  Widget build(BuildContext context) {
    // Style BD (issue #97) : éclat d'impact au lieu de la bannière dégradée.
    if (kComicChkobba) return ActionBurst(text: text, size: burstSize);
    final style = GameStyle.current;
    const base = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      height: 1.1,
    );
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: style.outline, width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = style.outline,
              ),
            ),
            Text(text, style: base.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
