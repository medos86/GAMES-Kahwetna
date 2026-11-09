import 'dart:async';
import 'dart:math' as math;

import '../../core/audio/sounds.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/layout/device_metrics.dart';
import '../../game/common.dart';
import '../../game/domino.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/pressable.dart';
import '../../widgets/texture_patterns.dart';
import '../menu/menu_models.dart';
import 'domino_controller.dart';
import 'domino_tiles.dart';

const _adFreeKey = 'kahwetne-ad-free-until';

/// Écran de jeu Domino (DominoGameScreen.tsx).
class DominoScreen extends StatefulWidget {
  const DominoScreen({super.key, required this.difficulty, required this.targetScore});

  final Difficulty difficulty;
  final int targetScore;

  @override
  State<DominoScreen> createState() => _DominoScreenState();
}

class _DominoScreenState extends State<DominoScreen> {
  late final DominoController _controller = DominoController(
    targetScore: widget.targetScore,
    difficulty: widget.difficulty,
  );
  bool _adFree = false;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    Sounds.preload().then((_) => Sounds.play(Sfx.draw));
    _loadAdFree();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAdFree() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = prefs.getInt(_adFreeKey) ?? 0;
    final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
    if (!mounted) return;
    if (remaining <= 0) return;
    setState(() => _adFree = true);
    _adTimer = Timer(Duration(milliseconds: remaining), () {
      if (mounted) setState(() => _adFree = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final metrics = DeviceMetrics(width: size.width, height: size.height);
    final unit = metrics.gameUnit;
    final sm = size.width >= 640;

    return Scaffold(
      backgroundColor: const Color(0xFF8B4513),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final game = _controller.game;
          return Stack(
            children: [
              const _WoodBackground(),
              // Trames du fond : points 4px (opacité 0.2) et rayures verticales 11px (opacité 0.1 × 0.2).
              const Positioned.fill(child: DotPattern(spacing: 4, radius: 1, color: Color(0x33000000))),
              const Positioned.fill(child: StripePattern(period: 11, width: 1, color: Color(0x05000000), vertical: true)),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, _adFree ? 12 : 88),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          _Header(unit: unit, round: game.round, target: game.targetScore, onMenu: () => Navigator.of(context).maybePop()),
                          SizedBox(height: unit),
                          _ScoreStrip(unit: unit, game: game, turnIsPlayer: game.turn == Player.player && game.roundWinner == null, turnIsOpponent: game.turn == Player.opponent && game.roundWinner == null, onDrawTap: _controller.drawOrPass, mustDraw: _controller.mustDraw),
                          SizedBox(height: unit * 0.6),
                          _OpponentHand(unit: unit, count: game.hands[Player.opponent]!.length),
                          SizedBox(height: unit * 0.6),
                          Expanded(child: _Table(unit: unit, sm: sm, controller: _controller)),
                          SizedBox(height: unit * 0.6),
                          _Footer(unit: unit, sm: sm, controller: _controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!_adFree) const Positioned(left: 8, right: 8, bottom: 8, child: AdBanner()),
              if (game.roundWinner != null || game.matchWinner != null)
                _RoundOverlay(
                  game: game,
                  onNext: _controller.startNextRound,
                  onRestart: _controller.restart,
                  onMenu: () => Navigator.of(context).maybePop(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _WoodBackground extends StatelessWidget {
  const _WoodBackground();

  @override
  Widget build(BuildContext context) {
    // Dégradé d'ombre en haut : approximation des couches de bois du source.
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4D000000), Color(0x00000000)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unit, required this.round, required this.target, required this.onMenu});

  final double unit;
  final int round;
  final int target;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    // text-[calc(var(--game-unit)*0.75)], et 0.9 à partir du seuil sm (640 px) comme dans le source.
    final titleSize = unit * (MediaQuery.sizeOf(context).width >= 640 ? 0.9 : 0.75);
    return Row(
      children: [
        Pressable(
          semanticLabel: 'Menu',
          onTap: onMenu,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: unit, vertical: unit * 0.55),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0xFF4A2A10), spreadRadius: 3),
                BoxShadow(color: Color(0xFF4A2A10), offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: unit, color: const Color(0xFF7E22CE)),
                SizedBox(width: unit * 0.4),
                Text('Menu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: unit * 0.85, color: const Color(0xFF7E22CE))),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: unit * 0.5),
            child: Column(
              children: [
                Text(
                  'KAHWETNE · DOMINO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'RobotoSlab',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: titleSize * 0.16,
                    color: const Color(0xFFFFF1BD),
                    shadows: const [Shadow(offset: Offset(1, 2), color: Color(0xFF4A2A10))],
                  ),
                ),
                Text(
                  'Manche $round',
                  style: TextStyle(
                    fontSize: unit * 0.8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [Shadow(offset: Offset(1, 2), color: Color(0xFF4A2A10))],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: unit * 3,
          height: unit * 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.emoji_events, size: unit * 3, color: const Color(0xFFFBBF24)),
              Positioned(
                top: unit * 0.4,
                child: Text(
                  '$target',
                  style: TextStyle(fontSize: unit * 0.8, fontWeight: FontWeight.w900, color: const Color(0xFF20284B)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({
    required this.unit,
    required this.game,
    required this.turnIsPlayer,
    required this.turnIsOpponent,
    required this.onDrawTap,
    required this.mustDraw,
  });

  final double unit;
  final DominoState game;
  final bool turnIsPlayer;
  final bool turnIsOpponent;
  final VoidCallback onDrawTap;
  final bool mustDraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2A10), spreadRadius: 3),
          BoxShadow(color: Color(0xFF4A2A10), offset: Offset(0, 4), spreadRadius: 3),
        ],
      ),
      child: Stack(
        children: [
          // Points de la barre de score : radial-gradient #000 1px, 6px, opacité 0.1.
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const DotPattern(spacing: 6, radius: 1, color: Color(0x1A000000)),
            ),
          ),
          Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreBox(
            label: 'Vous',
            value: game.scores[Player.player]!,
            color: const Color(0xFF047857),
            active: turnIsPlayer,
            unit: unit,
          ),
          _Pile(unit: unit, count: game.boneyard.length, bounce: mustDraw && game.boneyard.isNotEmpty),
          _ScoreBox(
            label: 'Adv.',
            value: game.scores[Player.opponent]!,
            color: const Color(0xFFB91C1C),
            active: turnIsOpponent,
            unit: unit,
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value, required this.color, required this.active, required this.unit});

  final String label;
  final int value;
  final Color color;
  final bool active;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label == 'Adv.') ...[
          Text(label.toUpperCase(), style: TextStyle(fontSize: unit * 0.7, fontWeight: FontWeight.w900, color: color)),
          SizedBox(width: unit * 0.3),
        ],
        Container(
          constraints: BoxConstraints(minWidth: unit * 3.2),
          height: unit * 2.8,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
            boxShadow: active ? const [BoxShadow(color: Color(0xFFFFF1BD), spreadRadius: 3)] : null,
          ),
          child: Text('$value', style: TextStyle(fontSize: unit * 1.4, fontWeight: FontWeight.w900, color: color)),
        ),
        if (label == 'Vous') ...[
          SizedBox(width: unit * 0.3),
          Text(label.toUpperCase(), style: TextStyle(fontSize: unit * 0.7, fontWeight: FontWeight.w900, color: color)),
        ],
      ],
    );
  }
}

class _Pile extends StatelessWidget {
  const _Pile({required this.unit, required this.count, required this.bounce});

  final double unit;
  final int count;
  final bool bounce;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: unit * 2,
          height: unit * 2,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: unit,
                height: unit * 1.5,
                decoration: BoxDecoration(color: const Color(0xFFC63D55), border: Border.all(color: Colors.black, width: 2)),
              ),
              Positioned(
                right: -unit * 0.2,
                top: -unit * 0.2,
                child: Container(
                  constraints: BoxConstraints(minWidth: unit * 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF5),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text('$count', style: TextStyle(fontSize: unit * 0.55, fontWeight: FontWeight.w900, color: const Color(0xFF20284B))),
                ),
              ),
            ],
          ),
        ),
        Text('PIOCHE', style: TextStyle(fontSize: unit * 0.55, fontWeight: FontWeight.w900, letterSpacing: 1, color: const Color(0xFF17213D))),
      ],
    );
  }
}

class _OpponentHand extends StatelessWidget {
  const _OpponentHand({required this.unit, required this.count});

  final double unit;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: unit * 3.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: unit * 0.15),
              child: Container(
                width: unit * 1.9,
                height: unit * 3.4,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD94A61), Color(0xFF8F203D)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: _edge, width: 2),
                  boxShadow: const [BoxShadow(color: Color(0xFF4A1022), offset: Offset(0, 3))],
                ),
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Container(height: 2, color: const Color(0xB3FFE16B)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _edge = Color(0xFF24364B);

class _Table extends StatelessWidget {
  const _Table({required this.unit, required this.sm, required this.controller});

  final double unit;
  final bool sm;
  final DominoController controller;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final status = _status(controller);
    final ends = controller.chainEnds;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: sm ? 20 : 8, vertical: sm ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4A2A10), width: 6),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A2A10), spreadRadius: 3),
          BoxShadow(color: Color(0x59281405), offset: Offset(0, 8), blurRadius: 20, spreadRadius: 3),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Tapis : rayures blanches 4px (opacité 0.08 × 0.08), points noirs 8px (opacité 0.1).
            const Positioned.fill(child: StripePattern(period: 4, width: 2, color: Color(0x02FFFFFF))),
            const Positioned.fill(child: StripePattern(period: 4, width: 2, color: Color(0x02FFFFFF), vertical: true)),
            const Positioned.fill(child: DotPattern(spacing: 8, radius: 1, color: Color(0x1A000000))),
            Column(
        children: [
          Text(
            status,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: sm ? 14 : 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [Shadow(offset: Offset(1, 1), color: Color(0xFF123B2B))],
            ),
          ),
          SizedBox(height: sm ? 12 : 8),
          Expanded(
            child: game.chain.isEmpty
                ? Center(
                    child: Text(
                      'La première pierre ouvre la partie',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.45)),
                    ),
                  )
                : DominoChain(
                    chain: game.chain,
                    leftOpen: ends?.left ?? false,
                    rightOpen: ends?.right ?? false,
                    onEndTap: controller.playSelected,
                  ),
          ),
        ],
      ),
          ],
        ),
      ),
    );
  }

  String _status(DominoController c) {
    final game = c.game;
    if (game.roundWinner != null) return 'Manche terminée';
    final playerTurn = game.turn == Player.player;
    if (game.chain.isEmpty) {
      return playerTurn ? 'À toi d’ouvrir la chaîne' : 'Le voisin ouvre la chaîne…';
    }
    if (!playerTurn) return 'Le voisin réfléchit…';
    if (c.selectedTile != null) return 'Touche l’extrémité où poser la pierre';
    if (c.playable.isNotEmpty) return 'Touche une pierre pour jouer';
    return game.boneyard.isNotEmpty ? 'Aucun coup possible : pioche' : 'Aucun coup possible : passe';
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.unit, required this.sm, required this.controller});

  final double unit;
  final bool sm;
  final DominoController controller;

  void _onTile(BuildContext context, DominoTile tile, bool playable, bool canAct) {
    if (canAct && playable) {
      controller.tapTile(tile);
      return;
    }
    if (canAct) controller.flagInvalid(tile.id);
  }

  void _onDraw(BuildContext context) {
    final game = controller.game;
    final canAct = game.turn == Player.player && game.roundWinner == null;
    if (!canAct || controller.playable.isNotEmpty) {
      // Pas de notification : le bouton tremble pour dire que l'action n'est pas possible.
      controller.flagDrawInvalid();
      return;
    }
    controller.drawOrPass();
  }

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final playable = controller.playable.map((t) => t.id).toSet();
    final canAct = game.turn == Player.player && game.roundWinner == null;

    final label = game.boneyard.isNotEmpty ? 'Piocher' : 'Passer';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A2A10), width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFF4A2A10), offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TA MAIN · ${game.hands[Player.player]!.length} PIERRES',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF20284B)),
                ),
              ),
              _ShakeOnTrigger(
                trigger: controller.drawInvalidCount,
                child: Pressable(
                semanticLabel: label,
                onTap: () => _onDraw(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF5A3C), Color(0xFFD71920)]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4A0A0A), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0xFFFF8A4C), spreadRadius: 3)],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: sm ? 96 : 76,
            child: game.hands[Player.player]!.isEmpty
                ? const Center(
                    child: Text('Main vide — belle pose !', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0x9920284B))),
                  )
                : _HandScroller(
                    children: [
                      for (final tile in game.hands[Player.player]!)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _ShakeOnTrigger(
                            trigger: controller.invalidTileId == tile.id ? controller.invalidCount : 0,
                            child: _HandTile(
                              tile: tile,
                              sm: sm,
                              selected: controller.selectedTileId == tile.id,
                              enabled: canAct && playable.contains(tile.id),
                              onTap: () => _onTile(context, tile, playable.contains(tile.id), canAct),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Main horizontale : quand une pierre est piochée, la main défile jusqu'à la dernière pierre.
class _HandScroller extends StatefulWidget {
  const _HandScroller({required this.children});

  final List<Widget> children;

  @override
  State<_HandScroller> createState() => _HandScrollerState();
}

class _HandScrollerState extends State<_HandScroller> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant _HandScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length > oldWidget.children.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: widget.children,
    );
  }
}

/// Fait trembler son enfant quand [trigger] change (et qu'il est non nul).
class _ShakeOnTrigger extends StatelessWidget {
  const _ShakeOnTrigger({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: trigger == 0 ? 0.0 : 1.0, end: 0.0),
      duration: const Duration(milliseconds: 380),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(math.sin(v * math.pi * 4) * 8 * v, 0),
        child: child,
      ),
      child: child,
    );
  }
}

class _HandTile extends StatelessWidget {
  const _HandTile({required this.tile, required this.sm, required this.selected, required this.enabled, required this.onTap});

  final DominoTile tile;
  final bool sm;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Domino ${tile.a} et ${tile.b}${enabled ? ', jouable' : ', non jouable'}',
      onTap: onTap,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, selected ? -8 : 0, 0),
        child: Opacity(
          opacity: 1,
          child: DominoFace(
            first: tile.a,
            second: tile.b,
            width: sm ? 44 : 36,
            height: sm ? 88 : 68,
            highlight: selected,
          ),
        ),
      ),
    );
  }
}

class _RoundOverlay extends StatelessWidget {
  const _RoundOverlay({required this.game, required this.onNext, required this.onRestart, required this.onMenu});

  final DominoState game;
  final VoidCallback onNext;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final matchOver = game.matchWinner != null;
    final title = matchOver
        ? (game.matchWinner == Player.player ? 'Victoire !' : 'Le voisin gagne')
        : (game.roundWinner == Player.player ? 'Bien joué !' : 'On remet ça ?');
    final points = game.pointsAwarded;
    final canContinue = game.roundWinner != null && game.matchWinner == null;

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xB3071B20),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(28),
            constraints: const BoxConstraints(maxWidth: 384),
            decoration: BoxDecoration(
              color: const Color(0xFF11343A),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF4D28A), width: 2),
              boxShadow: const [BoxShadow(color: Color(0x80000000), offset: Offset(0, 20), blurRadius: 70)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFF4D28A), borderRadius: BorderRadius.circular(16)),
                  child: Icon(matchOver ? Icons.emoji_events : Icons.radio_button_checked, size: 32, color: const Color(0xFF694B13)),
                ),
                const SizedBox(height: 20),
                Text(
                  matchOver ? 'PARTIE TERMINÉE' : 'MANCHE ${game.round} TERMINÉE',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.6, color: Color(0xFFF4D28A)),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'RobotoSlab', fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score ${game.scores[Player.player]} – ${game.scores[Player.opponent]} · +$points point${points == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xB3FFFFFF)),
                ),
                const SizedBox(height: 24),
                _OverlayButton(
                  label: canContinue ? 'Manche suivante' : 'Rejouer',
                  onTap: canContinue ? onNext : onRestart,
                ),
                const SizedBox(height: 16),
                Pressable(
                  semanticLabel: 'Retour au menu',
                  onTap: onMenu,
                  child: const Text('Retour au menu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0x99FFFFFF))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE17B), Color(0xFFF2B74E)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0xFFAE7131), offset: Offset(0, 5))],
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF3D351F))),
      ),
    );
  }
}
