// Rendu des dominos : demi-tuile avec ses points, tuile de la main, serpentin de la chaîne.
// Géométrie reprise de DominoGameScreen.tsx (DominoHalf, DominoFace, ChainTile, DominoChain).

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/i18n/app_language.dart';
import '../../core/strings.dart';
import '../../game/domino.dart';
import 'domino_chain_layout.dart';

const _pipColor = Color(0xFF17304B);
// Issue #686 : face teintée du bleu du tapis (au lieu d'un crème blanc isolé),
// pour que les pierres fassent partie du tapis. Contraste des points vérifié en test.
const _faceColor = Color(0xFFF3FAFD);

/// Couleurs publiques des pierres (utilisées par les tests de contraste).
const Color dominoPipColor = _pipColor;
const Color dominoFaceColor = _faceColor;
const _edgeColor = Color(0xFF24364B);
// Style cartoon : contour sombre épais et ombre dure.
const _outlineColor = Color(0xFF1B2A44);
const _shadowColor = Color(0xFF0B1A33);

/// Position des points par valeur (mêmes emplacements que pipPositions du source).
const _pipLayouts = <int, List<String>>{
  0: [],
  1: ['center'],
  2: ['top-left', 'bottom-right'],
  3: ['top-left', 'center', 'bottom-right'],
  4: ['top-left', 'top-right', 'bottom-left', 'bottom-right'],
  5: ['top-left', 'top-right', 'center', 'bottom-left', 'bottom-right'],
  6: [
    'top-left',
    'top-right',
    'middle-left',
    'middle-right',
    'bottom-left',
    'bottom-right',
  ],
};

/// Une moitié de domino : des points à 18 % du bord, comme le CSS source.
class _HalfPainter extends CustomPainter {
  const _HalfPainter(this.value, {this.rotated = false});

  final int value;
  // Pierre posée à plat : le motif de points tourne de 90°, comme sur une vraie pierre.
  final bool rotated;

  @override
  void paint(Canvas canvas, Size size) {
    if (!rotated) {
      _paintPips(canvas, size);
      return;
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 2);
    canvas.translate(-size.height / 2, -size.width / 2);
    _paintPips(canvas, Size(size.height, size.width));
    canvas.restore();
  }

  void _paintPips(Canvas canvas, Size size) {
    final paint = Paint()..color = _pipColor;
    // Points ronds (même diamètre en largeur et en hauteur), taille proportionnelle à la plus petite dimension.
    final pipD = math.min(size.width, size.height) * 0.24;
    final pipW = pipD;
    final pipH = pipD;
    const inset = 0.18;
    for (final position in _pipLayouts[value] ?? const <String>[]) {
      final double x;
      final double y;
      switch (position) {
        case 'top-left':
          x = size.width * inset;
          y = size.height * inset;
        case 'top-right':
          x = size.width - size.width * inset - pipW;
          y = size.height * inset;
        case 'middle-left':
          x = size.width * inset;
          y = (size.height - pipH) / 2;
        case 'middle-right':
          x = size.width - size.width * inset - pipW;
          y = (size.height - pipH) / 2;
        case 'center':
          x = (size.width - pipW) / 2;
          y = (size.height - pipH) / 2;
        case 'bottom-left':
          x = size.width * inset;
          y = size.height - size.height * inset - pipH;
        default: // bottom-right
          x = size.width - size.width * inset - pipW;
          y = size.height - size.height * inset - pipH;
      }
      canvas.drawOval(Rect.fromLTWH(x, y, pipW, pipH), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HalfPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.rotated != rotated;
}

/// Tuile complète (fond crème, bordure foncée, ombre dure). `horizontal` la couche à plat.
class DominoFace extends StatelessWidget {
  const DominoFace({
    super.key,
    required this.first,
    required this.second,
    required this.width,
    required this.height,
    this.horizontal = false,
    this.highlight = false,
  });

  final int first;
  final int second;
  final double width;
  final double height;
  final bool horizontal;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final halves = [
      // SizedBox.expand : sans cela, CustomPaint garde une taille nulle dans l'axe libre et rien ne s'affiche.
      Expanded(
        child: SizedBox.expand(
          child: CustomPaint(painter: _HalfPainter(first, rotated: horizontal)),
        ),
      ),
      horizontal
          ? Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: _edgeColor.withValues(alpha: 0.5),
            )
          : Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              color: _edgeColor.withValues(alpha: 0.5),
            ),
      Expanded(
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _HalfPainter(second, rotated: horizontal),
          ),
        ),
      ),
    ];
    return Semantics(
      label: tf('sTile', {'a': '$first', 'b': '$second'}),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _faceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _outlineColor, width: 3),
          boxShadow: [
            const BoxShadow(color: _shadowColor, offset: Offset(0, 4)),
            if (highlight)
              const BoxShadow(color: Color(0xFFFDE047), spreadRadius: 3),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              horizontal ? Row(children: halves) : Column(children: halves),
              // Reflet cartoon : bande claire en haut à gauche, sans bloquer le toucher.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment(0.3, 0.3),
                        colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tuile posée dans la chaîne. Horizontale dans une rangée, verticale au virage.
class ChainTile extends StatelessWidget {
  const ChainTile({
    super.key,
    required this.tile,
    required this.length,
    required this.turn,
    required this.reverse,
    this.highlight = false,
    this.onTap,
  });

  final PlacedTile tile;
  final double length;
  final bool turn;
  final bool reverse;
  final bool highlight;
  final void Function(TapUpDetails details)? onTap;

  @override
  Widget build(BuildContext context) {
    final first = (turn || !reverse) ? tile.left : tile.right;
    final second = (turn || !reverse) ? tile.right : tile.left;
    final width = turn ? length / 2 : length;
    final height = turn ? length : length / 2;
    final face = DominoFace(
      first: first,
      second: second,
      width: width,
      height: height,
      horizontal: !turn,
      highlight: highlight,
    );
    if (onTap == null) return face;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: onTap,
      child: face,
    );
  }
}

/// Chaîne posée autour de la première pierre (#930, #960). La pierre d'ouverture reste au centre
/// et chaque pierre a une place fixe : ajouter une pierre ne déplace jamais les autres.
/// Le zoom ne réduit la chaîne que lorsqu'elle déborde du tapis.
class DominoChain extends StatefulWidget {
  const DominoChain({
    super.key,
    required this.chain,
    required this.leftOpen,
    required this.rightOpen,
    required this.onEndTap,
    this.openingId,
  });

  final List<PlacedTile> chain;
  final bool leftOpen;
  final bool rightOpen;
  final void Function(DominoSide side) onEndTap;

  /// Id de la première pierre posée. Sans lui (partie rechargée), la pierre du milieu sert de centre.
  final String? openingId;

  @override
  State<DominoChain> createState() => _DominoChainState();
}

class _DominoChainState extends State<DominoChain> {
  final _scroll = ScrollController();
  bool _centered = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _openingIndex() {
    final chain = widget.chain;
    final id = widget.openingId;
    final index =
        id == null ? -1 : chain.indexWhere((tile) => tile.id == id);
    return index >= 0 ? index : chain.length ~/ 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chain = widget.chain;
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth;
        // Demi-largeur du tapis en unités de demi-pierre (pair).
        final halfWidth = availableWidth >= 480 ? 8 : 6;
        // Taille de départ : la chaîne commence grande (#960, #1022).
        final startUnit = chainStartUnit(
          width: availableWidth,
          halfWidth: halfWidth,
        );
        // Zoom arrière seulement si la largeur déborde ; le serpent est recalé à ce zoom (#1036).
        final fitted = layoutChainFitted(
          count: chain.length,
          openIndex: _openingIndex(),
          width: availableWidth,
          unit: startUnit,
        );
        final slots = fitted.slots;
        // Taille réelle à l'écran : le zoom est appliqué à la taille de pierre, sans transformation.
        final unit = startUnit * fitted.scale;
        final length = unit * 2;
        // Hauteur du contenu : au moins l'écran, sinon on défile verticalement sans réduire les pierres.
        final contentHeight = math.max(
          availableHeight,
          2 * chainHalfHeight(slots: slots, unit: unit),
        );

        if (!_centered) {
          // Au premier affichage, on se place au milieu : la pierre d'ouverture reste visible.
          _centered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scroll.hasClients) return;
            _scroll.jumpTo(_scroll.position.maxScrollExtent / 2);
          });
        }

        final last = chain.length - 1;
        final tiles = <Widget>[];
        for (var i = 0; i < chain.length; i++) {
          final slot = slots[i];
          final sides = <DominoSide>[
            if (i == 0 && widget.leftOpen) DominoSide.left,
            if (i == last && widget.rightOpen) DominoSide.right,
          ];
          void Function(TapUpDetails)? onTap;
          if (sides.isNotEmpty) {
            onTap = (details) {
              if (sides.length == 1) {
                widget.onEndTap(sides.first);
              } else {
                final tileWidth = slot.vertical ? unit : length;
                widget.onEndTap(
                  details.localPosition.dx < tileWidth / 2
                      ? DominoSide.left
                      : DominoSide.right,
                );
              }
            };
          }
          final tile = ChainTile(
            tile: chain[i],
            length: length,
            turn: slot.vertical,
            reverse: slot.reverse,
            highlight: onTap != null,
            onTap: onTap,
          );
          // Position absolue depuis le centre fixe : la pierre d'ouverture (x=-1..1, y=0..1) est centrée.
          tiles.add(
            Positioned(
              key: ValueKey(chain[i].id),
              left: availableWidth / 2 + slot.x * unit,
              top: contentHeight / 2 + (slot.y - 0.5) * unit,
              width: slot.width * unit,
              height: slot.height * unit,
              child: sides.isNotEmpty
                  ? Semantics(
                      button: true,
                      label: Strings.dominoPlaceHere,
                      child: tile,
                    )
                  : tile,
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scroll,
          child: SizedBox(
            width: availableWidth,
            height: contentHeight,
            child: Stack(clipBehavior: Clip.none, children: tiles),
          ),
        );
      },
    );
  }
}
