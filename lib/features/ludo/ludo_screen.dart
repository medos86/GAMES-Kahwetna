import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../../game/ludo.dart';
import '../../widgets/ad_banner.dart';
import '../menu/menu_models.dart';
import 'ludo_controller.dart';
import 'ludo_layout.dart';
import '../../core/services/ad_free_service.dart';

/// Clé partagée avec le mode sans pub (même nom que le web).
const _ink = Color(0xFF20284B);
const _cream = Color(0xFFFFF8E7);
const _brown = Color(0xFF4A2A10);
const _pipAxis = [22.0, 50.0, 78.0];

/// Points allumés sur chaque face du dé (grille 3 × 3 : index = ligne × 3 + colonne).
const _pipLayout = <int, List<int>>{
  1: [4],
  2: [0, 8],
  3: [0, 4, 8],
  4: [0, 2, 6, 8],
  5: [0, 2, 4, 6, 8],
  6: [0, 2, 3, 5, 6, 8],
};

class _Tone {
  const _Tone(this.fill, this.dark, this.tint, this.name);
  final Color fill;
  final Color dark;
  final Color tint;
  final String name;
}

_Tone _toneOf(LudoColor color) => switch (color) {
      LudoColor.red => const _Tone(Color(0xFFE43F5F), Color(0xFF8F203D), Color(0xFFFFD3DC), 'Rouge'),
      LudoColor.green => const _Tone(Color(0xFF49C9A7), Color(0xFF14705B), Color(0xFFC9F5E8), 'Vert'),
      LudoColor.yellow => const _Tone(Color(0xFFFFD653), Color(0xFF9A6B00), Color(0xFFFFF1BF), 'Jaune'),
      LudoColor.blue => const _Tone(Color(0xFF1676D2), Color(0xFF0B3F7A), Color(0xFFCFE5FB), 'Bleu'),
    };

String _colorName(LudoColor color, bool solo) =>
    solo && color == LudoColor.blue ? 'Toi' : _toneOf(color).name;

String _noteText(LudoNote note, bool solo) {
  final label = (LudoColor c) => _colorName(c, solo);
  return switch (note) {
    NoMoveNote() => '${label(note.color)} : aucun coup possible',
    ThreeSixesNote() => '${label(note.color)} : trois 6 de suite, tour perdu',
    CapturedNote(:final victims) =>
      'Capture : ${victims.map(label).join(', ')} renvoyé(s) à la base',
    FinishedNote(:final place) =>
      '${label(note.color)} arrive ${place == 1 ? '1er' : '${place}e'} !',
  };
}

/// Écran du Ludo. Logique dans LudoController et lib/game/ludo.dart.
class LudoScreen extends StatefulWidget {
  const LudoScreen({super.key, required this.difficulty, required this.players});

  final Difficulty difficulty;
  final int players;

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  late final LudoController _controller = LudoController(
    playerCount: widget.players,
    difficulty: _aiLevel(widget.difficulty),
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;

  static LudoAiLevel _aiLevel(Difficulty d) => switch (d) {
        Difficulty.facile => LudoAiLevel.facile,
        Difficulty.moyen => LudoAiLevel.moyen,
        Difficulty.difficile => LudoAiLevel.difficile,
      };

  @override
  void initState() {
    super.initState();
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
    _adFree.removeListener(_onAdFreeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onAdFreeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscapeShort = size.width > size.height && size.height <= 520;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B4F9C), Color(0xFF1676D2), Color(0xFF2A8CE6)],
          ),
        ),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final c = _controller;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, _adFree.value ? 12 : 88),
                    child: Column(
                      children: [
                        _Header(controller: c),
                        const SizedBox(height: 8),
                        Expanded(
                          child: landscapeShort
                              ? Row(
                                  children: [
                                    Expanded(child: Center(child: _BoardWithDice(controller: c))),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: size.width * 0.42,
                                      child: Column(
                                        children: [
                                          _Players(controller: c),
                                          const Spacer(),
                                          _Footer(controller: c),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _Players(controller: c),
                                    const SizedBox(height: 8),
                                    Expanded(child: Center(child: _BoardWithDice(controller: c))),
                                    const SizedBox(height: 8),
                                    _Footer(controller: c),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_adFree.value) const Positioned(left: 8, right: 8, bottom: 8, child: AdBanner()),
                if (c.roundOver)
                  Positioned.fill(
                    child: _EndDialog(
                      controller: c,
                      onMenu: () => Navigator.of(context).maybePop(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.playerCount;
    return Row(
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: Color(0xFF0B3F7A)),
                  SizedBox(width: 4),
                  Text('Menu', style: TextStyle(color: Color(0xFF0B3F7A), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'KAHWETNE · LUDO',
                style: TextStyle(color: Color(0xFFFFE16B), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13),
              ),
              Text(
                'لودو · $count joueur${count > 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _Players extends StatelessWidget {
  const _Players({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    return Row(
      children: [
        for (final color in LudoColor.values)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: game.turn == color && !controller.roundOver ? const Color(0xFFFFE16B) : _brown,
                  width: game.turn == color && !controller.roundOver ? 3 : 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _toneOf(color).fill,
                          shape: BoxShape.circle,
                          border: Border.all(color: _brown),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _colorName(color, controller.solo).toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${game.tokens.where((t) => t.color == color && t.progress == ludoFinish).length}/4',
                    style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    _placeText(game.rankings.indexOf(color) + 1),
                    style: const TextStyle(color: Color(0x99202848), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _placeText(int place) {
    if (place == 0) return 'au centre';
    return '${place == 1 ? '1er' : '${place}e'} ✓';
  }
}

/// Taille d'un dé et marge réservée autour du plateau pour les quatre emplacements.
const _dieSize = 44.0;
const _dieMargin = 36.0;

/// Plateau entouré des quatre emplacements de dé, un par coin de maison :
/// joueur 1 (bleu) en bas à gauche, 2 (jaune) en bas à droite,
/// 3 (rouge) en haut à gauche, 4 (vert) en haut à droite.
class _BoardWithDice extends StatelessWidget {
  const _BoardWithDice({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(_dieMargin),
          child: _Board(controller: controller),
        ),
        for (final color in LudoColor.values) _positionedDie(color),
      ],
    );
  }

  Widget _positionedDie(LudoColor color) {
    final corner = ludoCorner(color);
    final isLeft = corner.col == 0;
    final isTop = corner.row == 0;
    return Positioned(
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      child: _DieSlot(controller: controller, color: color),
    );
  }
}

/// Emplacement fixe du dé d'une couleur. Le dé n'apparaît dans cet emplacement
/// que lorsque cette couleur vient de lancer ; sinon il reste en placeholder.
class _DieSlot extends StatelessWidget {
  const _DieSlot({required this.controller, required this.color});

  final LudoController controller;
  final LudoColor color;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final tone = _toneOf(color);
    final rolledHere = game.diceOwner == color && game.dice != null;
    final active = game.turn == color && !controller.roundOver;
    return Container(
      decoration: active
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0xFFFFE16B), spreadRadius: 3)],
            )
          : null,
      child: KeyedSubtree(
        key: rolledHere ? ValueKey('roll-${game.rollId}') : ValueKey('idle-${color.name}'),
        child: _Die(value: rolledHere ? game.dice : null, tone: tone.fill, size: _dieSize),
      ),
    );
  }
}

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
          label: 'Plateau de Ludo',
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
                    for (final color in LudoColor.values) _cornerHouse(color, u),
                    for (final color in LudoColor.values)
                      for (var slot = 0; slot < ludoBaseSlots.length; slot++)
                        _at(
                          left: (ludoCorner(color).col + ludoBaseSlots[slot][1] - 0.4) * u,
                          top: (ludoCorner(color).row + ludoBaseSlots[slot][0] - 0.4) * u,
                          size: 0.8 * u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _brown.withValues(alpha: 0.5), width: 2),
                            ),
                          ),
                        ),
                    for (var index = 0; index < ludoTrack.length; index++)
                      _trackCell(index, ludoTrack[index], u),
                    for (final color in LudoColor.values)
                      for (var step = 0; step < ludoHomeColumn(color).length; step++)
                        _at(
                          left: ludoHomeColumn(color)[step].col * u,
                          top: ludoHomeColumn(color)[step].row * u,
                          size: u,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _toneOf(color).fill,
                              border: Border.all(color: _brown.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                    _at(left: 6 * u, top: 6 * u, size: 3 * u, child: const _CenterPiece()),
                    for (final placed in layoutTokens(controller.game.tokens))
                      AnimatedPositioned(
                        key: ValueKey(placed.token.id),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        left: (placed.x - placed.size / 2) * u,
                        top: (placed.y - placed.size / 2) * u,
                        width: placed.size * u,
                        height: placed.size * u,
                        child: _TokenButton(
                          token: placed.token,
                          clickable: legal.contains(placed.token.id),
                          onTap: () => controller.tapToken(placed.token.id),
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
Positioned _at({required double left, required double top, required double size, required Widget child}) =>
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
            ? Center(child: Icon(Icons.star, size: u * 0.7, color: const Color(0xFFFFD653)))
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

class _TokenButton extends StatelessWidget {
  const _TokenButton({required this.token, required this.clickable, required this.onTap});

  final Token token;
  final bool clickable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = _toneOf(token.color);
    return Semantics(
      button: clickable,
      label: 'Pion ${tone.name}${clickable ? ', à déplacer' : ''}',
      child: GestureDetector(
        onTap: clickable ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [Colors.white, tone.fill, tone.dark],
              stops: const [0.1, 0.38, 1],
            ),
            border: Border.all(color: clickable ? Colors.white : _brown, width: clickable ? 3 : 2),
            boxShadow: const [
              BoxShadow(color: _brown, offset: Offset(0, 3)),
              BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final LudoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final turnName = _colorName(game.turn, solo);
    final prompt = controller.roundOver
        ? ''
        : game.note != null
            ? _noteText(game.note!, solo)
            : controller.humanTurn
                ? game.phase == LudoPhase.roll
                    ? '${solo ? 'À toi' : 'À $turnName'} : lance le dé'
                    : 'Touche un pion en surbrillance'
                : '$turnName joue…';
    final tone = _toneOf(game.turn);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _brown, width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOUR : ${turnName.toUpperCase()}',
                  style: TextStyle(color: _ink.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900),
                ),
                Text(
                  prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),
          if (controller.canRoll)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: tone.fill,
                foregroundColor: game.turn == LudoColor.yellow ? const Color(0xFF513B00) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: controller.roll,
              child: const Text('Lancer le dé', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }
}

/// Dé : tourne et rebondit à chaque lancer (le widget est recréé pour chaque rollId).
class _Die extends StatelessWidget {
  const _Die({super.key, required this.value, required this.tone, this.size = 56});

  final int? value;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final face = value ?? 5;
    final pips = _pipLayout[face]!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.rotate(
        angle: (1 - t) * -200 * math.pi / 180,
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: Semantics(
        label: value != null ? 'Dé : $value' : 'Dé',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E9),
            borderRadius: BorderRadius.circular(size * 0.21),
            border: Border.all(color: const Color(0xFF24364B), width: 3),
          ),
          child: Stack(
            children: [
              for (final index in pips)
                Align(
                  alignment: Alignment(
                    _pipAxis[index % 3] / 50 - 1,
                    _pipAxis[index ~/ 3] / 50 - 1,
                  ),
                  child: Opacity(
                    opacity: value != null ? 1 : 0.2,
                    child: Container(
                      width: size * 0.21,
                      height: size * 0.21,
                      decoration: BoxDecoration(
                        color: tone,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF24364B), width: 1.5),
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

class _EndDialog extends StatelessWidget {
  const _EndDialog({required this.controller, required this.onMenu});

  final LudoController controller;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final solo = controller.solo;
    final first = game.rankings.first;
    final title = solo && first == LudoColor.blue
        ? 'Victoire !'
        : '${_colorName(first, solo)} gagne';

    return ColoredBox(
        color: const Color(0xB3052A52),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3F7A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFFFD653), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 48, color: Color(0xFFFFD653)),
                    const SizedBox(height: 8),
                    const Text(
                      'PARTIE TERMINÉE',
                      style: TextStyle(color: Color(0xFFFFD653), fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    for (var i = 0; i < game.rankings.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: _toneOf(game.rankings[i]).fill,
                              child: Text('${i + 1}', style: const TextStyle(color: _ink, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _colorName(game.rankings[i], solo),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE17B),
                          foregroundColor: const Color(0xFF3D351F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: controller.restart,
                        child: const Text('Rejouer', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                    TextButton(
                      onPressed: onMenu,
                      child: const Text('Retour au menu', style: TextStyle(color: Colors.white60)),
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
