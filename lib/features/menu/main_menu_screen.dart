import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/comic_palette.dart';
import '../../core/theme/game_style.dart';
import '../../widgets/comic/comic_panel.dart';
import '../../widgets/exit_guard.dart';
import '../../widgets/comic/halftone_overlay.dart';
import '../../widgets/fade_slide_in.dart';
import '../settings/settings_screen.dart';
import '../../widgets/pressable.dart';
import '../../widgets/texture_patterns.dart';
import 'game_icons.dart';
import 'menu_models.dart';
import '../../core/strings.dart';
import '../../core/services/ad_free_service.dart';
import '../../core/services/saved_game_store.dart';
import '../../widgets/comic_button.dart';
import '../../widgets/resume_game.dart';
import '../../core/services/toast.dart';

part 'main_menu/menu_background.dart';
part 'main_menu/menu_header.dart';
part 'main_menu/games_panel.dart';
part 'main_menu/menu_panels.dart';

// Couleurs fixes reprises du source (Tailwind -> hex).
const _ink = Color(0xFF15264D);
const _ceramic = Color(0xFFFFF8E7);
const _gold = Color(0xFFFFE16B);
const _shadowSoft = Color(0x47141630); // rgba(20,22,48,0.28)

/// Menu principal : liste des jeux, choix du niveau et du score, mode sans pub.
/// Porte MainMenu.tsx. `onPlay` reçoit la partie choisie (la navigation passe par lib/app/game_routes.dart).
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key, this.onPlay});

  final void Function(LaunchRequest request)? onPlay;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

enum _MenuScreen { menu, difficulty }

class _MainMenuScreenState extends State<MainMenuScreen> {
  Difficulty _difficulty = Difficulty.facile;
  GameEntry _selected = gameEntries.first;
  int _target = gameEntries.first.defaultTarget;
  int _playerCount = 1;
  _MenuScreen _screen = _MenuScreen.menu;
  final AdFreeService _adFree = AdFreeService.instance;
  int _adFreeLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // L'échéance conservée est relue au démarrage (main) ; ici on suit seulement le service.
    _adFreeLeft = _secondsLeft();
    _adFree.active.addListener(_syncAdFree);
    _startCountdown();
  }

  @override
  void dispose() {
    _adFree.active.removeListener(_syncAdFree);
    _timer?.cancel();
    super.dispose();
  }

  int _secondsLeft() => (_adFree.remaining.inMilliseconds / 1000).ceil();

  /// Le service a changé d'état (activation ou expiration).
  void _syncAdFree() {
    if (!mounted) return;
    setState(() => _adFreeLeft = _secondsLeft());
    _startCountdown();
  }

  /// Décompte d'une seconde, actif seulement tant qu'il reste du temps (comme le useEffect source).
  void _startCountdown() {
    _timer?.cancel();
    if (!_adFree.active.value) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _adFreeLeft = _secondsLeft());
      if (!_adFree.active.value) _timer?.cancel();
    });
  }

  Future<void> _selectGame(GameEntry game) async {
    if (!game.available) {
      showToast(
        context,
        '${game.name} arrive bientôt !',
        description: Strings.menuComingSoonBody,
      );
      return;
    }
    final key = savedGameKeys[game.route];
    if (key != null) {
      const store = SharedPreferencesSavedGameStore();
      final saved = await store.load(key);
      if (!mounted) return;
      if (saved != null) {
        final resume = await showConfirmDialog(
          context,
          title: Strings.resumeTitle,
          body: Strings.resumeBody,
          cancelLabel: Strings.resumeNew,
          confirmLabel: Strings.resumeContinue,
          confirmVariant: ComicButtonVariant.primary,
        );
        if (!mounted) return;
        if (resume == null) return;
        if (resume == true) {
          markResumeConfirmed(key);
          final prefs = await SharedPreferences.getInstance();
          final name = prefs.getString(_difficultyPrefKey(key));
          setState(() {
            _selected = game;
            _difficulty = Difficulty.values.firstWhere(
              (d) => d.name == name,
              orElse: () => Difficulty.facile,
            );
            _target = game.defaultTarget;
          });
          _launch();
          return;
        }
        final sure = await showConfirmDialog(
          context,
          title: Strings.resumeNewTitle,
          body: Strings.resumeNewBody,
          cancelLabel: Strings.exitStay,
          confirmLabel: Strings.resumeNew,
          dismissible: false,
        );
        if (!mounted) return;
        if (sure != true) return;
        await store.clear(key);
      }
    }
    setState(() {
      _selected = game;
      _target = game.defaultTarget;
      _screen = _MenuScreen.difficulty;
    });
  }

  static String _difficultyPrefKey(String key) => 'kahwetne-difficulty-$key';

  void _launch() {
    final key = savedGameKeys[_selected.route];
    final chosen = _difficulty;
    if (key != null) {
      unawaited(
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(_difficultyPrefKey(key), chosen.name),
        ),
      );
    }
    widget.onPlay?.call(
      LaunchRequest(
        game: _selected,
        difficulty: _difficulty,
        target: _target,
        players: _playerCount,
      ),
    );
    // Au retour du jeu (bouton Menu), on revient à la liste des jeux (#365).
    setState(() {
      _screen = _MenuScreen.menu;
      _difficulty = Difficulty.facile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final vw = screenSize.width;
    final sm = vw >= 640; // breakpoint sm de Tailwind
    final md = vw >= 768;

    return PopScope(
      // Retour système : d'abord revenir de l'écran de difficulté, puis demander confirmation avant de fermer l'app (#117).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_screen == _MenuScreen.difficulty) {
          setState(() {
            _difficulty = Difficulty.facile;
            _screen = _MenuScreen.menu;
          });
          return;
        }
        final leave = await showLeaveDialog(
          context,
          title: Strings.exitAppTitle,
          body: Strings.exitAppBody,
        );
        if (leave == true) await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2BB8EA),
        body: Stack(
          children: [
            _Background(
              difficulty: _difficulty,
              imageAsset: _screen == _MenuScreen.difficulty
                  ? _selected.backgroundAsset
                  : kMenuBackgroundAsset,
            ),
            // Trame de points du menu : radial-gradient(#17203f 1.2px) 7px, opacité 0.07.
            const Positioned.fill(
              child: IgnorePointer(
                child: DotPattern(
                  spacing: 7,
                  radius: 1.2,
                  color: Color(0x1217203F),
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(0, 16, 0, 16),
              child: LayoutBuilder(
                builder: (context, c) {
                  final contentWidth = math.min(640.0, c.maxWidth);
                  final padding = sm ? 28.0 : 16.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      height: c.maxHeight,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Column(
                          children: [
                            _Header(
                              difficulty: _difficulty,
                              screen: _screen,
                              onBack: () => setState(() {
                                _difficulty = Difficulty.facile;
                                _screen = _MenuScreen.menu;
                              }),
                            ),
                            Expanded(
                              child: _screen == _MenuScreen.menu
                                  ? _buildMenu(vw: vw, sm: sm, md: md)
                                  : _buildDifficulty(vw: vw, sm: sm),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Écran 1 : liste des jeux ----------

  Widget _buildMenu({required double vw, required bool sm, required bool md}) {
    return Column(
      children: [
        SizedBox(height: sm ? 16 : 12),
        FadeSlideIn(
          offset: const Offset(0, -0.1),
          child: Transform.rotate(
            angle: -2 * math.pi / 180,
            child: _TitleBlock(vw: vw, sm: sm),
          ),
        ),
        SizedBox(height: sm ? 16 : 12),
        Expanded(
          child: _GamesPanel(
            difficulty: _difficulty,
            sm: sm,
            md: md,
            onSelect: _selectGame,
          ),
        ),
        const SizedBox(height: 12),
        _AdFreeButton(
          sm: sm,
          secondsLeft: _adFreeLeft,
          onTap: () {
            _adFree.activate();
            showToast(
              context,
              Strings.menuAdFreeToastTitle,
              description: Strings.menuAdFreeToastBody,
            );
          },
        ),
      ],
    );
  }

  // ---------- Écran 2 : niveau et score ----------

  Widget _buildDifficulty({required double vw, required bool sm}) {
    final wide = vw >= 540;
    final scoreOptions = _selected.targets;
    final label =
        difficultyOptions.firstWhere((o) => o.difficulty == _difficulty).label;

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: sm ? 28 : 20),
                _DifficultyTitle(vw: vw, gameName: _selected.name),
                SizedBox(height: sm ? 28 : 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: _GlassPanel(
                    difficulty: _difficulty,
                    radius: 28,
                    padding: EdgeInsets.all(sm ? 20 : 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _sectionLabel(Strings.menuDifficultyTitle),
                        const SizedBox(height: 8),
                        _difficultyRow(wide: wide),
                        if (!_selected.isLudo && scoreOptions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _sectionLabel(Strings.menuScoreSection),
                          const SizedBox(height: 8),
                          _scoreRow(scoreOptions),
                        ],
                        if (_selected.isLudo) ...[
                          const SizedBox(height: 16),
                          _sectionLabel(Strings.menuHumanPlayersCount),
                          const SizedBox(height: 8),
                          _playerRow(),
                          const SizedBox(height: 8),
                          Text(
                            Strings.menuAiSeatsNote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _LaunchButton(label: label, sm: sm, onTap: _launch),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: sm ? 28 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _difficultyRow({required bool wide}) {
    final buttons = [
      for (final o in difficultyOptions) _difficultyButton(o, wide),
    ];
    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }
    return Semantics(
      inMutuallyExclusiveGroup: true,
      child: Column(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            buttons[i],
          ],
        ],
      ),
    );
  }

  Widget _difficultyButton(DifficultyOption o, bool wide) {
    final active = _difficulty == o.difficulty;
    final fg =
        active ? o.activeForeground : const Color(0xA6FFFFFF); // blanc 65 %
    final bg =
        active ? o.activeBackground : const Color(0x8C081735); // #081735 à 55 %
    final border = active ? const Color(0xB3FFFFFF) : const Color(0x26FFFFFF);

    final iconBoxSize = wide ? 48.0 : 40.0;
    final icon = Container(
      width: iconBoxSize,
      height: iconBoxSize,
      decoration: BoxDecoration(
        color: active ? const Color(0x40FFFFFF) : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(o.icon, size: 20, color: fg),
    );
    final texts = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          o.label,
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            fontSize: wide ? 20 : 18,
            fontWeight: FontWeight.w900,
            height: 1,
            color: fg,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          o.detail.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: fg.withValues(alpha: active ? 0.65 : 0.45),
          ),
        ),
      ],
    );

    return Pressable(
      semanticLabel: active ? '${o.label}, sélectionné' : o.label,
      onTap: () => setState(() => _difficulty = o.difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(minHeight: wide ? 150 : 76),
        padding: EdgeInsets.symmetric(horizontal: wide ? 12 : 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
          boxShadow: active
              ? [BoxShadow(color: o.activeShadow, offset: const Offset(0, 3))]
              : null,
        ),
        child: Stack(
          children: [
            if (active)
              const Positioned(right: 8, top: 8, child: _Dot(size: 10)),
            wide
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [icon, const SizedBox(height: 8), texts],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: texts),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          color: Color(0xBFFFFFFF),
        ),
      );

  Widget _scoreRow(List<int> scores) {
    return Row(
      children: [
        for (var i = 0; i < scores.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _choiceButton(
              label: '${scores[i]} points',
              active: _target == scores[i],
              onTap: () => setState(() => _target = scores[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _playerRow() {
    return Row(
      children: [
        for (var count = 1; count <= 4; count++) ...[
          if (count > 1) const SizedBox(width: 12),
          Expanded(
            child: _choiceButton(
              label: '$count',
              active: _playerCount == count,
              onTap: () => setState(() => _playerCount = count),
            ),
          ),
        ],
      ],
    );
  }

  Widget _choiceButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? _gold : const Color(0x8C081735),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xB3FFFFFF) : const Color(0x26FFFFFF),
            width: 2,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(color: Color(0xFFD99921), offset: Offset(0, 3)),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: active ? const Color(0xFF513B00) : const Color(0xA6FFFFFF),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Composants visuels
// =====================================================================

/// Fond sombre des cases BD du menu (encre semi-transparente).
Color get _comicInk => ComicPalette.ink.withAlpha(0xE6);
