import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../core/avatars/avatar_catalog.dart';
import '../../core/avatars/game_avatars.dart';
import '../../game/ludo.dart';
import '../menu/menu_models.dart';
import 'ludo_backdrop.dart';
import 'ludo_controller.dart';
import 'ludo_layout.dart';
import '../../core/i18n/app_language.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/game_end_watcher.dart';
import '../../core/services/interstitial_service.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/game_header.dart';
import '../../widgets/pulse_glow.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/dialog_button.dart';
import '../../widgets/round_result_panel.dart';

part 'ludo_parts/ludo_header_players.dart';
part 'ludo_parts/ludo_die.dart';
part 'ludo_parts/ludo_board.dart';
part 'ludo_parts/ludo_footer_end.dart';

/// Clé partagée avec le mode sans pub (même nom que le web).
const _ink = Color(0xFF20284B);
const _cream = Color(0xFFFFF8E7);
const _brown = Color(0xFF4A2A10);

/// Étoile des cases sûres (#596, #623) : or doré, contraste ≥ 3:1 sur le crème.
const Color kLudoSafeStarColor = Color(0xFFB8860B);
const _pipAxis = [22.0, 50.0, 78.0];

/// Couleurs de joueurs (#597) : identiques aux valeurs de [_toneOf].
const kLudoFills = <LudoColor, Color>{
  LudoColor.red: Color(0xFFFF6F00),
  LudoColor.green: Color(0xFF00BF8B),
  LudoColor.yellow: Color(0xFFE69F00),
  LudoColor.blue: Color(0xFF008BD9),
};

class _Tone {
  const _Tone(this.fill, this.dark, this.tint, this.name);
  final Color fill;
  final Color dark;
  final Color tint;
  final String name;
}

/// Palette Okabe-Ito (#597), distinguable en daltonisme ; voir [kLudoFills].
_Tone _toneOf(LudoColor color) => switch (color) {
      LudoColor.red => const _Tone(
          Color(0xFFFF6F00),
          Color(0xFF7A3300),
          Color(0xFFFFE0CC),
          'Rouge',
        ),
      LudoColor.green => const _Tone(
          Color(0xFF00BF8B),
          Color(0xFF00503B),
          Color(0xFFCCF0E5),
          'Vert',
        ),
      LudoColor.yellow => const _Tone(
          Color(0xFFE69F00),
          Color(0xFF6E4A00),
          Color(0xFFFFF0CC),
          'Jaune',
        ),
      LudoColor.blue => const _Tone(
          Color(0xFF008BD9),
          Color(0xFF003F66),
          Color(0xFFCCE4F2),
          'Bleu',
        ),
    };

String _colorName(LudoColor color, bool solo) =>
    solo && color == LudoColor.blue ? 'Toi' : _toneOf(color).name;

String _noteText(LudoNote note, bool solo) {
  String label(LudoColor c) => _colorName(c, solo);
  return switch (note) {
    // Formulé au passé : la note reste affichée après que le tour a changé (#155).
    NoMoveNote() =>
      'Précédent : ${label(note.color)} n\'avait aucun coup possible',
    ThreeSixesNote() => '${label(note.color)} : trois 6 de suite, tour perdu',
    CapturedNote(:final victims) =>
      'Capture : ${victims.map(label).join(', ')} renvoyé(s) à la base',
    FinishedNote(:final place) =>
      '${label(note.color)} arrive ${place == 1 ? '1er' : '${place}e'} !',
  };
}

/// Écran du Ludo. Logique dans LudoController et lib/game/ludo.dart.
class LudoScreen extends StatefulWidget {
  const LudoScreen({
    super.key,
    required this.difficulty,
    required this.players,
  });

  final Difficulty difficulty;
  final int players;

  @override
  State<LudoScreen> createState() => _LudoScreenState();
}

class _LudoScreenState extends State<LudoScreen> {
  // Avatar de chaque couleur (issue #553), vide tant que le profil n'est pas lu.
  Map<LudoColor, String> _avatarByColor = const {};

  late final LudoController _controller = LudoController(
    store: const SharedPreferencesSavedGameStore(),
    playerCount: widget.players,
    difficulty: _aiLevel(widget.difficulty),
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;
  late final GameEndWatcher _endWatcher = GameEndWatcher(
    isEnded: () => _controller.roundOver,
    onEnded: () => unawaited(InterstitialService.instance.onGameFinished()),
  );

  static LudoAiLevel _aiLevel(Difficulty d) =>
      aiLevelFor(LudoAiLevel.values, d);

  @override
  void initState() {
    super.initState();
    InterstitialService.instance.preload();
    loadGameAvatars(seats: 4).then((ids) {
      if (mounted) setState(() => _avatarByColor = ludoAvatarByColor(ids));
    });
    _controller.addListener(_endWatcher.check);
    _controller.restore().then((_) {
      if (mounted) offerResume(context, _controller);
    });
    _adFree.addListener(_onAdFreeChanged);
  }

  @override
  void dispose() {
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
    final landscapeShort = size.width > size.height && size.height <= 520;

    return ExitGuard(
      active: !_controller.roundOver,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return GameScaffold(
            showAd: !_adFree.value,
            background: const LudoBackdrop(),
            overlays: [
              if (c.roundOver)
                Positioned.fill(
                  child: _EndDialog(
                    controller: c,
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                ),
              if (c.choiceOpen)
                Positioned.fill(
                  child: _ChoiceDialog(
                    onFinish: c.finishGame,
                    onShowEnd: c.showEnd,
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  _Header(controller: c),
                  const SizedBox(height: 8),
                  Expanded(
                    child: landscapeShort
                        ? Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: _Board(controller: c),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: size.width * 0.42,
                                // Défilable : sur paysage court, la colonne
                                // déborderait (#340).
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PlayerRow(
                                        controller: c,
                                        top: true,
                                        avatarIds: _avatarByColor,
                                      ),
                                      const SizedBox(height: 8),
                                      _PlayerRow(
                                        controller: c,
                                        top: false,
                                        avatarIds: _avatarByColor,
                                      ),
                                      const SizedBox(height: 8),
                                      _Footer(controller: c),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _PlayerRow(
                                controller: c,
                                top: true,
                                avatarIds: _avatarByColor,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: _Board(controller: c),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PlayerRow(
                                controller: c,
                                top: false,
                                avatarIds: _avatarByColor,
                              ),
                              const SizedBox(height: 8),
                              _Footer(controller: c),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
