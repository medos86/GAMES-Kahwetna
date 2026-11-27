import 'dart:math' as math;

import '../../core/audio/sounds.dart';

import 'package:material_ui/material_ui.dart';

import '../../core/theme/comic_palette.dart';
import '../../core/theme/scoba_palette.dart';
import '../../core/theme/game_style.dart';

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
import '../../core/services/game_end_watcher.dart';
import '../../core/services/interstitial_service.dart';
import '../../core/services/game_end_sequence.dart';
import '../../widgets/exit_guard.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/trophy_badge.dart';
import '../../widgets/game_header.dart';
import '../../core/avatars/avatar_catalog.dart';
import '../../core/avatars/game_avatars.dart';
import '../../widgets/turn_avatar.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/round_result_panel.dart';
import '../../widgets/game_rays_background.dart';

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
  // Avatars [joueur, adversaire] (issue #555) ; 0 = joueur.
  List<String> _avatarIds = [defaultAvatar.id, 'lion'];

  late final DominoController _controller = DominoController(
    store: const SharedPreferencesSavedGameStore(),
    targetScore: widget.targetScore,
    difficulty: widget.difficulty,
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;
  final GameEndSequence _endSeq = GameEndSequence();
  late final GameEndWatcher _endWatcher = GameEndWatcher(
    isEnded: () => _controller.game.matchWinner != null,
    onEnded: () => _endSeq.start(InterstitialService.instance.onGameFinished),
  );

  @override
  void initState() {
    super.initState();
    InterstitialService.instance.preload();
    loadGameAvatars(seats: 2).then((ids) {
      if (mounted) setState(() => _avatarIds = ids);
    });
    _controller.addListener(_endWatcher.check);
    _controller.restore().then((_) {
      if (mounted) offerResume(context, _controller);
    });
    Sounds.preload().then((_) => Sounds.play(Sfx.draw));
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
    _endSeq.dispose();
    _adFree.removeListener(_onAdFreeChanged);
    _controller.removeListener(_endWatcher.check);
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
    // Petit écran (hauteur < 700) : espaces verticaux réduits pour tenir.
    final compact = size.height < 700;

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
            // Fond rayons propre au Domino (#806).
            background: const GameRaysBackground(gameName: 'Domino'),
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
                  SizedBox(
                    height: sm ? unit * 0.25 : (compact ? unit * 0.5 : unit),
                  ),
                  Expanded(
                    child: Container(
                      key: const ValueKey('domino-felt'),
                      margin: EdgeInsets.fromLTRB(
                        4,
                        compact ? 2 : 6,
                        4,
                        compact ? 2 : 6,
                      ),
                      padding: EdgeInsets.all(compact ? 2 : 6),
                      decoration: BoxDecoration(
                        color: ComicPalette.tableWood,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black, width: 3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DecoratedBox(
                          decoration: ScobaPalette.tapisPremiumDecoration,
                          child: Column(
                            children: [
                              SizedBox(
                                height: unit * (sm || compact ? 0.2 : 0.6),
                              ),
                              _OpponentHand(
                                unit: unit,
                                count: game.hands[Player.opponent]!.length,
                                seat: _ScoreBox(
                                  label: t('opponentShort'),
                                  value: game.scores[Player.opponent]!,
                                  color: const Color(0xFFB91C1C),
                                  active: opponentTurn,
                                  unit: unit,
                                  avatarId: _avatarIds[Player.opponent.index],
                                  avatarState: dominoAvatarState(
                                    game,
                                    Player.opponent,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: unit * (sm || compact ? 0.2 : 0.6),
                              ),
                              Expanded(
                                child: _Table(
                                  unit: unit,
                                  sm: sm,
                                  controller: _controller,
                                ),
                              ),
                              SizedBox(
                                height: unit * (sm || compact ? 0.2 : 0.6),
                              ),
                              _Footer(
                                unit: unit,
                                sm: sm,
                                controller: _controller,
                                pile: _Pile(
                                  unit: unit,
                                  count: game.boneyard.length,
                                  bounce: _controller.mustDraw &&
                                      game.boneyard.isNotEmpty,
                                ),
                                seat: _ScoreBox(
                                  label: t('you'),
                                  value: game.scores[Player.player]!,
                                  color: const Color(0xFF047857),
                                  active: playerTurn,
                                  unit: unit,
                                  avatarId: _avatarIds[Player.player.index],
                                  avatarState: dominoAvatarState(
                                    game,
                                    Player.player,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            overlays: [
              if (game.roundWinner != null || game.matchWinner != null)
                Positioned.fill(
                  child: DominoRoundOverlay(
                    revealed: _endSeq.revealed,
                    game: game,
                    avatarIds: _avatarIds,
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
