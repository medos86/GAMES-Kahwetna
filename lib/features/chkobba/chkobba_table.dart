import 'dart:ui' show Offset;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/game_style.dart';
import '../../core/theme/scoba_palette.dart';
import '../../widgets/comic/action_burst.dart';
import 'chkobba_table_layout.dart';

/// Tapis de Chkobba (#745) : feutre vert sans cadre intérieur (#766 retiré).
/// `cards` contient un élément par emplacement ; null = emplacement vide.
/// Les cartes sont posées au centre du tapis et ne bougent pas quand une autre part (voir [chkobbaCellOffset]).
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
    const cardHeight = kChkobbaTableCardWidth * 7 / 5;

    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: ScobaPalette.tapisPremiumDecoration,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final centre = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight / 2,
              );
              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    if (cards[i] != null)
                      _placed(
                        centre: centre,
                        offset: chkobbaCellOffset(i, columns),
                        height: cardHeight,
                        child: cards[i]!,
                      ),
                ],
              );
            },
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

  static Widget _placed({
    required Offset centre,
    required Offset offset,
    required double height,
    required Widget child,
  }) {
    const w = kChkobbaTableCardWidth;
    return Positioned(
      left: centre.dx + offset.dx * (w + kChkobbaTableGap) - w / 2,
      top: centre.dy + offset.dy * (height + kChkobbaTableGap) - height / 2,
      width: w,
      height: height,
      child: _CardInCell(child: child),
    );
  }
}

/// Largeur d'une carte posée sur le tapis : assez grande pour rester lisible (#908).
const double kChkobbaTableCardWidth = 68;

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
