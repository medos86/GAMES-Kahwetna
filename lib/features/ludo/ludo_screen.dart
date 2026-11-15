import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import '../../game/ludo.dart';
import '../menu/menu_models.dart';
import 'ludo_controller.dart';
import 'ludo_layout.dart';
import '../../core/i18n/app_language.dart';
import '../../core/services/ad_free_service.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/game_scaffold.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/resume_game.dart';
import '../../widgets/difficulty_chip.dart';
import '../../widgets/game_header.dart';

part 'ludo_parts/ludo_header_players.dart';
part 'ludo_parts/ludo_die.dart';
part 'ludo_parts/ludo_board.dart';
part 'ludo_parts/ludo_footer_end.dart';

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
      LudoColor.red => const _Tone(
          Color(0xFFE43F5F),
          Color(0xFF8F203D),
          Color(0xFFFFD3DC),
          'Rouge',
        ),
      LudoColor.green => const _Tone(
          Color(0xFF49C9A7),
          Color(0xFF14705B),
          Color(0xFFC9F5E8),
          'Vert',
        ),
      LudoColor.yellow => const _Tone(
          Color(0xFFFFD653),
          Color(0xFF9A6B00),
          Color(0xFFFFF1BF),
          'Jaune',
        ),
      LudoColor.blue => const _Tone(
          Color(0xFF1676D2),
          Color(0xFF0B3F7A),
          Color(0xFFCFE5FB),
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
  late final LudoController _controller = LudoController(
    store: const SharedPreferencesSavedGameStore(),
    playerCount: widget.players,
    difficulty: _aiLevel(widget.difficulty),
  );
  final ValueListenable<bool> _adFree = AdFreeService.instance.active;

  static LudoAiLevel _aiLevel(Difficulty d) =>
      aiLevelFor(LudoAiLevel.values, d);

  @override
  void initState() {
    super.initState();
    _controller.restore().then((_) {
      if (mounted) offerResume(context, _controller);
    });
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

    return ExitGuard(
      active: !_controller.roundOver,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          return GameScaffold(
            showAd: !_adFree.value,
            background: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0B4F9C),
                    Color(0xFF1676D2),
                    Color(0xFF2A8CE6),
                  ],
                ),
              ),
            ),
            overlays: [
              if (c.roundOver)
                Positioned.fill(
                  child: _EndDialog(
                    controller: c,
                    onMenu: () => Navigator.of(context).maybePop(),
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: [
                  _Header(controller: c, difficulty: widget.difficulty),
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
                                      ),
                                      const SizedBox(height: 8),
                                      _PlayerRow(
                                        controller: c,
                                        top: false,
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
                              _PlayerRow(controller: c, top: true),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Center(
                                  child: _Board(controller: c),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PlayerRow(controller: c, top: false),
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
