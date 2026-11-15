part of '../ludo_screen.dart';

class _Board extends StatelessWidget {
  const _Board({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final u = side / ludoBoardUnits;
        final legal = controller.legalIds;
        return Semantics(
          label: t('ludoBoard'),
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _brown, width: 6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final color in LudoColor.values)
                      _cornerHouse(color, u),
                    for (final color in LudoColor.values)
                      for (var slot = 0; slot < ludoBaseSlots.length; slot++)
                        _at(
                          left: (ludoCorner(color).col +
                                  ludoBaseSlots[slot][1] -
                                  0.4) *
                              u,
                          top: (ludoCorner(color).row +
                                  ludoBaseSlots[slot][0] -
                                  0.4) *
                              u,
                          size: 0.8 * u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _brown.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    for (var index = 0; index < ludoTrack.length; index++)
                      _trackCell(index, ludoTrack[index], u),
                    for (final color in LudoColor.values)
                      for (var step = 0;
                          step < ludoHomeColumn(color).length;
                          step++)
                        _at(
                          left: ludoHomeColumn(color)[step].col * u,
                          top: ludoHomeColumn(color)[step].row * u,
                          size: u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _toneOf(color).fill,
                              border: Border.all(
                                color: _brown.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                    _at(
                      left: 6 * u,
                      top: 6 * u,
                      size: 3 * u,
                      child: const _CenterPiece(),
                    ),
                    for (final placed in layoutTokens(controller.game.tokens))
                      AnimatedPositioned(
                        key: ValueKey(placed.token.id),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        left: placed.x * u - _tokenHitSize(placed.size * u) / 2,
                        top: placed.y * u - _tokenHitSize(placed.size * u) / 2,
                        width: _tokenHitSize(placed.size * u),
                        height: _tokenHitSize(placed.size * u),
                        child: _TokenButton(
                          token: placed.token,
                          clickable: legal.contains(placed.token.id),
                          onTap: () => controller.tapToken(placed.token.id),
                          visualSize: placed.size * u,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Carré positionné dans le Stack du plateau (coordonnées en pixels). Doit rester un `Positioned`
/// direct : un Stack ne accepte pas un widget qui en enveloppe un autre.
Positioned _at({
  required double left,
  required double top,
  required double size,
  required Widget child,
}) =>
    Positioned(left: left, top: top, width: size, height: size, child: child);

Positioned _cornerHouse(LudoColor color, double u) {
  final corner = ludoCorner(color);
  final tone = _toneOf(color);
  return _at(
    left: corner.col * u,
    top: corner.row * u,
    size: 6 * u,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brown, width: 3),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.84,
          heightFactor: 0.84,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tone.fill.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    ),
  );
}

Positioned _trackCell(int index, Cell cell, double u) {
  LudoColor? starter;
  for (final color in LudoColor.values) {
    if (ludoStartIndex(color) == index) starter = color;
  }
  final isSafe = ludoSafeIndexes.contains(index);
  return _at(
    left: cell.col * u,
    top: cell.row * u,
    size: u,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: starter != null ? _toneOf(starter).fill : _cream,
        border: Border.all(color: _brown.withValues(alpha: 0.3)),
      ),
      child: isSafe && starter == null
          ? Center(
              child: Icon(
                Icons.star,
                size: u * 0.7,
                color: const Color(0xFFFFD653),
              ),
            )
          : null,
    ),
  );
}

class _CenterPiece extends StatelessWidget {
  const _CenterPiece();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: SweepGradient(
          startAngle: -math.pi / 4,
          colors: [
            Color(0xFFFFD653),
            Color(0xFF1676D2),
            Color(0xFFE43F5F),
            Color(0xFF49C9A7),
            Color(0xFFFFD653),
          ],
          stops: [0, 0.25, 0.5, 0.75, 1],
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.4,
          heightFactor: 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _cream,
              shape: BoxShape.circle,
              border: Border.all(color: _brown, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zone tactile d'un pion : au moins 44 px (issue #23), même si le pion dessiné est plus petit.
double _tokenHitSize(double visual) => math.max(visual, 44);

class _TokenButton extends StatelessWidget {
  const _TokenButton({
    required this.token,
    required this.clickable,
    required this.onTap,
    required this.visualSize,
  });

  final Token token;
  final bool clickable;
  final VoidCallback onTap;

  /// Taille du pion dessiné, centré dans la zone tactile.
  final double visualSize;

  @override
  Widget build(BuildContext context) {
    final tone = _toneOf(token.color);
    return Semantics(
      button: clickable,
      label: tf('sPawn', {'c': tone.name}) + (clickable ? t('sToMove') : ''),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: clickable ? onTap : null,
        child: Center(
          child: SizedBox(
            width: visualSize,
            height: visualSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [Colors.white, tone.fill, tone.dark],
                  stops: const [0.1, 0.38, 1],
                ),
                border: Border.all(
                  color: clickable ? Colors.white : _brown,
                  width: clickable ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(color: _brown, offset: Offset(0, 3)),
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 8,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
