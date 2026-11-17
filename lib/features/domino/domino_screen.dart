import 'dart:math' as math;

import '../../core/audio/sounds.dart';

import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/comic/comic_panel.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/layout/device_metrics.dart';
import '../../core/i18n/app_language.dart';
import '../../core/strings.dart';
import '../../game/common.dart';
import '../../game/domino.dart';
import '../../widgets/pressable.dart';
import '../../widgets/texture_patterns.dart';
import '../menu/menu_models.dart';
import 'domino_controller.dart';
import 'domino_tiles.dart';
import '../../core/services/ad_free_service.dart';
import '../../widgets/exit_guard.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/result_dialog.dart';

part 'domino_parts/domino_header_score.dart';
part 'domino_parts/domino_table.dart';
part 'domino_parts/domino_hand_footer.dart';
part 'domino_parts/domino_overlay.dart';

/// Écran de jeu Domino (DominoGameScreen.tsx).
class DominoScreen extends StatefulWidget {
  const DominoScreen({
    super.key,
    required this.difficulty,
    required this.targetScore,
  });

  final Difficulty difficulty;
  final int targetScore;

  @override
  State<DominoScreen> createState() => _DominoScreenState();
}

class _DominoScreenState extends State<DominoScreen> {
  late final DominoController _controller = DominoController(
    store: const SharedPreferencesSavedGameStore(),
    targetScore: widget.targetScore,
    difficulty: widget.difficulty,
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;

  @override
  void initState() {
    super.initState();
    _controller.restore().then((_) {
      if (mounted) offerResume(context, _controller);
    });
    Sounds.preload().then((_) => Sounds.play(Sfx.draw));
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
    final metrics = DeviceMetrics(width: size.width, height: size.height);
    final unit = metrics.gameUnit;
    final sm = size.width >= 640;

    return ExitGuard(
      active: _controller.game.matchWinner == null,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final game = _controller.game;
          final idle = game.roundWinner == null;
          final playerTurn = game.turn == Player.player && idle;
          final opponentTurn = game.turn == Player.opponent && idle;
          return GameScaffold(
            showAd: !_adFree.value,
            // Trames du fond : points 4px (opacité 0.2) et rayures verticales 11px (opacité 0.1 × 0.2).
            background: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF8B4513)),
                const _WoodShadeBackground(),
                const DotPattern(
                  spacing: 4,
                  radius: 1,
                  color: Color(0x33000000),
                ),
                const StripePattern(
                  period: 11,
                  width: 1,
                  color: Color(0x05000000),
                  vertical: true,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  _Header(
                    difficulty: widget.difficulty,
                    unit: unit,
                    round: game.round,
                    target: game.targetScore,
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                  // Paysage : espacement réduit pour tenir dans la hauteur (#344).
                  SizedBox(height: sm ? unit * 0.25 : unit),
                  _ScoreStrip(
                    unit: unit,
                    game: game,
                    turnIsPlayer: playerTurn,
                    turnIsOpponent: opponentTurn,
                    onDrawTap: _controller.drawOrPass,
                    mustDraw: _controller.mustDraw,
                  ),
                  SizedBox(height: unit * (sm ? 0.2 : 0.6)),
                  _OpponentHand(
                    unit: unit,
                    count: game.hands[Player.opponent]!.length,
                  ),
                  SizedBox(height: unit * (sm ? 0.2 : 0.6)),
                  Expanded(
                    child: _Table(
                      unit: unit,
                      sm: sm,
                      controller: _controller,
                    ),
                  ),
                  SizedBox(height: unit * (sm ? 0.2 : 0.6)),
                  _Footer(
                    unit: unit,
                    sm: sm,
                    controller: _controller,
                  ),
                ],
              ),
            ),
            overlays: [
              if (game.roundWinner != null || game.matchWinner != null)
                Positioned.fill(
                  child: DominoRoundOverlay(
                    game: game,
                    onNext: _controller.startNextRound,
                    onRestart: _controller.restart,
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
