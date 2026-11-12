import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
import '../../core/services/toast.dart';


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

  void _selectGame(GameEntry game) {
    if (!game.available) {
      showToast(
        context,
        '${game.name} arrive bientôt !',
        description: Strings.menuComingSoonBody,
      );
      return;
    }
    setState(() {
      _selected = game;
      _target = game.defaultTarget;
      _screen = _MenuScreen.difficulty;
    });
  }

  void _launch() {
    widget.onPlay?.call(
      LaunchRequest(
        game: _selected,
        difficulty: _difficulty,
        target: _target,
        players: _playerCount,
      ),
    );
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
        if (leave == true) SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF2BB8EA),
      body: Stack(
        children: [
          _Background(difficulty: _difficulty),
          // Trame de points du menu : radial-gradient(#17203f 1.2px) 7px, opacité 0.07.
          const Positioned.fill(
            child: IgnorePointer(
              child: DotPattern(spacing: 7, radius: 1.2, color: Color(0x1217203F)),
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
        Expanded(child: _GamesPanel(difficulty: _difficulty, sm: sm, md: md, onSelect: _selectGame)),
        const SizedBox(height: 12),
        _AdFreeButton(
          sm: sm,
          secondsLeft: _adFreeLeft,
          onTap: () {
            _adFree.activate();
            showToast(context, Strings.menuAdFreeToastTitle, description: Strings.menuAdFreeToastBody);
          },
        ),
      ],
    );
  }

  // ---------- Écran 2 : niveau et score ----------

  Widget _buildDifficulty({required double vw, required bool sm}) {
    final wide = vw >= 540;
    final scoreOptions = _selected.targets;
    final label = difficultyOptions.firstWhere((o) => o.difficulty == _difficulty).label;

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
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0x99FFFFFF)),
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
    final buttons = [for (final o in difficultyOptions) _difficultyButton(o, wide)];
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
    final fg = active ? o.activeForeground : const Color(0xA6FFFFFF); // blanc 65 %
    final bg = active ? o.activeBackground : const Color(0x8C081735); // #081735 à 55 %
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
      crossAxisAlignment: wide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
          boxShadow: active ? [BoxShadow(color: o.activeShadow, offset: const Offset(0, 3))] : null,
        ),
        child: Stack(
          children: [
            if (active)
              const Positioned(
                right: 8,
                top: 8,
                child: _Dot(size: 10),
              ),
            wide
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [icon, const SizedBox(height: 8), texts],
                  )
                : Row(
                    children: [icon, const SizedBox(width: 12), Expanded(child: texts)],
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
          Expanded(child: _choiceButton(
            label: '${scores[i]} points',
            active: _target == scores[i],
            onTap: () => setState(() => _target = scores[i]),
          )),
        ],
      ],
    );
  }

  Widget _playerRow() {
    return Row(
      children: [
        for (var count = 1; count <= 4; count++) ...[
          if (count > 1) const SizedBox(width: 12),
          Expanded(child: _choiceButton(
            label: '$count',
            active: _playerCount == count,
            onTap: () => setState(() => _playerCount = count),
          )),
        ],
      ],
    );
  }

  Widget _choiceButton({required String label, required bool active, required VoidCallback onTap}) {
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
          boxShadow: active ? const [BoxShadow(color: Color(0xFFD99921), offset: Offset(0, 3))] : null,
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

class _Background extends StatelessWidget {
  const _Background({required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final filter = switch (difficulty) {
      Difficulty.facile => _colorAdjust(brightness: 1.05, saturation: 1.10),
      Difficulty.moyen => _colorAdjust(brightness: 0.90, saturation: 1.25),
      Difficulty.difficile => _colorAdjust(brightness: 0.58, saturation: 0.80),
    };
    final scale = switch (difficulty) {
      Difficulty.facile => 1.0,
      Difficulty.moyen => 1.02,
      Difficulty.difficile => 1.04,
    };
    final glowOpacity = switch (difficulty) {
      Difficulty.facile => 0.0,
      Difficulty.moyen => 0.22,
      Difficulty.difficile => 0.36,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond commun au menu et au choix du niveau : assets/images/background.webp
        Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: filter,
            child: Image.asset(
              'assets/images/background.webp',
              semanticLabel: Strings.menuBackgroundAlt,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, error, __) => ColoredBox(
                color: const Color(0xFF2BB8EA),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    // Diagnostic temporaire : affiche la raison exacte si l'image ne se charge pas.
                    child: Text(
                      'Fond introuvable : $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (kComicMenu)
          const IgnorePointer(child: HalftoneOverlay(child: SizedBox.expand())),
        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: _tint(difficulty)))),
        IgnorePointer(
          child: Opacity(
            opacity: glowOpacity,
            child: DecoratedBox(decoration: BoxDecoration(gradient: _glow(difficulty))),
          ),
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.64),
                radius: 0.9,
                colors: [Colors.transparent, Color(0x33051836)],
                stops: [0.28, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static LinearGradient _tint(Difficulty d) {
    const top = [Color(0x40063A6B), Color(0x00000000), Color(0xBF101638)];
    const moyen = [Color(0x40A52D1D), Color(0x1AFF8A3D), Color(0xCC311631)];
    const difficile = [Color(0xA6080D37), Color(0x40351455), Color(0xF2080B24)];
    final colors = switch (d) {
      Difficulty.facile => top,
      Difficulty.moyen => moyen,
      Difficulty.difficile => difficile,
    };
    return LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors);
  }

  static Gradient _glow(Difficulty d) {
    if (d == Difficulty.difficile) {
      return const RadialGradient(
        center: Alignment(0.56, -0.76),
        radius: 0.45,
        colors: [Color(0xFFAE9CFF), Colors.transparent],
      );
    }
    return const RadialGradient(
      center: Alignment(0.44, -0.6),
      radius: 0.5,
      colors: [Color(0xFFFFDF67), Colors.transparent],
    );
  }

  /// Luminosité et saturation approximées par une matrice de couleur (les sépia et rotation de teinte sont omis).
  static ColorFilter _colorAdjust({required double brightness, required double saturation}) {
    final s = saturation;
    final b = brightness;
    return ColorFilter.matrix([
      (0.213 + 0.787 * s) * b, (0.715 - 0.715 * s) * b, (0.072 - 0.072 * s) * b, 0, 0,
      (0.213 - 0.213 * s) * b, (0.715 + 0.285 * s) * b, (0.072 - 0.072 * s) * b, 0, 0,
      (0.213 - 0.213 * s) * b, (0.715 - 0.715 * s) * b, (0.072 + 0.928 * s) * b, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.difficulty, required this.screen, required this.onBack});

  final Difficulty difficulty;
  final _MenuScreen screen;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (screen == _MenuScreen.menu)
          const _CoinsPill()
        else
          _GlassButton(
            onTap: onBack,
            semanticLabel: Strings.menuBackToGames,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 8),
                Text(Strings.menuBack, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        const Spacer(),
        Row(
          children: [
            _GlassButton(
              square: true,
              onTap: () {},
              semanticLabel: Strings.menuToggleSound,
              child: const Icon(Icons.volume_up, size: 20),
            ),
            const SizedBox(width: 8),
            _GlassButton(
              square: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
              semanticLabel: Strings.menuOpenSettings,
              child: const Icon(Icons.settings, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoinsPill extends StatelessWidget {
  const _CoinsPill();

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      semanticLabel: Strings.menuCoinBalance,
      onTap: () {},
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFD74A),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.monetization_on, size: 16, color: Color(0xFF7C4A00)),
            ),
          ),
          SizedBox(width: 8),
          Text('1 250', style: TextStyle(fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// Bouton « verre dépoli » (fond sombre translucide, bordure blanche).
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.square = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool square;

  @override
  Widget build(BuildContext context) {
    if (kComicMenu) {
      return Pressable(
        semanticLabel: semanticLabel,
        onTap: onTap,
        pressedScale: 0.92,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: ComicPanel(
            color: _comicInk,
            outlineColor: ComicPalette.tunisBlue,
            radius: 14,
            shadowOffset: const Offset(3, 3),
            padding: square ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            // Icônes en papier sur la case sombre (#152) et centrées dans la case.
            child: IconTheme.merge(
              data: const IconThemeData(color: _ceramic, size: 20),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: _ceramic),
                child: square ? Center(child: child) : child,
              ),
            ),
          ),
        ),
      );
    }
    return Pressable(
      semanticLabel: semanticLabel,
      onTap: onTap,
      pressedScale: 0.92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: square ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xA610254C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x59FFFFFF)),
              boxShadow: const [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 4), blurRadius: 12)],
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: _ceramic),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.vw, required this.sm});

  final double vw;
  final bool sm;

  /// Titre BD : Bangers jaune avec contour d'encre (issue #96).
  Widget _comicTitle(double size) {
    final base = TextStyle(fontFamily: 'Bangers', fontSize: size, height: 1, letterSpacing: 1);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'Kahwetne',
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.12
              ..strokeJoin = StrokeJoin.round
              ..color = ComicPalette.ink,
          ),
        ),
        Text('Kahwetne', style: base.copyWith(color: ComicPalette.yellow)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // font-size: clamp(2.6rem, 11vw, 5.5rem)
    final titleSize = math.min(math.max(41.6, 0.11 * vw), 88.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x73FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFFFE76A)),
              const SizedBox(width: 6),
              Text(
                Strings.menuTagline,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 12 * 0.18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        kComicMenu
            ? _comicTitle(titleSize)
            : Text(
          'Kahwetne',
          style: TextStyle(
            fontFamily: 'BowlbyOneSC',
            fontSize: titleSize,
            height: 1,
            letterSpacing: -0.05 * titleSize,
            color: _ceramic,
            shadows: const [
              Shadow(offset: Offset(0, 5), color: Color(0xFF173A79)),
              Shadow(offset: Offset(0, 9), blurRadius: 18, color: Color(0x610B1C44)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'لمّـة، ضحكة ولعبة تونسية',
          style: TextStyle(
            fontSize: sm ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xF2FFFFFF),
            shadows: const [Shadow(offset: Offset(0, 2), blurRadius: 7, color: Color(0xBF07193C))],
          ),
        ),
      ],
    );
  }
}

class _GamesPanel extends StatelessWidget {
  const _GamesPanel({required this.difficulty, required this.sm, required this.md, required this.onSelect});

  final Difficulty difficulty;
  final bool sm;
  final bool md;
  final void Function(GameEntry) onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      difficulty: difficulty,
      radius: 28,
      padding: EdgeInsets.all(md ? 20 : (sm ? 16 : 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.menuChooseTable,
                        style: TextStyle(
                          fontSize: sm ? 12 : 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: (sm ? 12 : 10) * 0.22,
                          color: const Color(0xFFFFE277),
                        ),
                      ),
                      Text(
                        Strings.menuStart,
                        style: TextStyle(
                          fontFamily: 'RobotoSlab',
                          fontSize: sm ? 24 : 20,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6EE7B7),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFF6EE7B7), blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gameEntries.length} tables',
                      style: TextStyle(
                        fontSize: sm ? 12 : 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xBFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sm ? 16 : 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 4),
              itemCount: gameEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final game = gameEntries[i];
                return FadeSlideIn(
                  delay: Duration(milliseconds: 220 + i * 70),
                  offset: const Offset(0, 0.1),
                  child: _GameTile(game: game, sm: sm, onTap: () => onSelect(game)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.sm, required this.onTap});

  final GameEntry game;
  final bool sm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(21.6);
    return Pressable(
      semanticLabel: game.name,
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        constraints: BoxConstraints(minHeight: sm ? 94 : 82),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [game.gradientFrom, game.gradientTo]),
          borderRadius: radius,
          border: Border.all(color: _ink, width: 3),
          boxShadow: [
            BoxShadow(color: game.edgeColor, offset: const Offset(0, 6)),
            const BoxShadow(color: _shadowSoft, offset: Offset(0, 11), blurRadius: 22),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Trame de points propre au bouton : radial-gradient(#17203f 1.1px) 6px, opacité 0.09.
              const Positioned.fill(
                child: DotPattern(spacing: 6, radius: 1.1, color: Color(0x1717203F)),
              ),
              Positioned(
                right: -20,
                top: -32,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sm ? 20 : 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: sm ? 64 : 56,
                      height: sm ? 64 : 56,
                      decoration: BoxDecoration(
                        color: const Color(0x29FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x4DFFFFFF)),
                      ),
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: sm ? 1 : 0.88,
                        child: SvgPicture.string(gameIconSvg[game.name]!, width: 56, height: 56),
                      ),
                    ),
                    SizedBox(width: sm ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            game.name,
                            style: TextStyle(
                              fontFamily: 'RobotoSlab',
                              fontSize: sm ? 24 : 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -0.025 * (sm ? 24 : 20),
                              color: Colors.white,
                              shadows: const [Shadow(offset: Offset(0, 2), color: Color(0x73132249))],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.tunisian,
                            style: TextStyle(
                              fontSize: sm ? 14 : 12,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xB3FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Color(0x4015264D), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdFreeButton extends StatelessWidget {
  const _AdFreeButton({required this.sm, required this.secondsLeft, required this.onTap});

  final bool sm;
  final int secondsLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = secondsLeft > 0;
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final clock = active
        ? '$minutes:${seconds.toString().padLeft(2, '0')}'
        : '30:00';

    return Pressable(
      semanticLabel: active
          ? 'Mode sans publicité actif, $minutes minutes et $seconds secondes restantes'
          : Strings.menuAdFreeEnable,
      onTap: onTap,
      child: Container(
        // Hauteur fixe : le bandeau ne doit pas changer de taille quand le texte se met à jour.
        height: sm ? 112 : 96,
        padding: EdgeInsets.symmetric(horizontal: sm ? 24 : 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF07A), Color(0xFFFFD04F), Color(0xFFFF9D45)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _ink, width: 3),
          boxShadow: const [
            BoxShadow(color: _ink, offset: Offset(0, 7)),
            BoxShadow(color: Color(0x66040B1F), offset: Offset(0, 14), blurRadius: 28),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: sm ? 64 : 44,
                    height: sm ? 64 : 44,
                    decoration: BoxDecoration(
                      color: const Color(0x8CFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x3315264D), width: 2),
                    ),
                    child: Icon(
                      active ? Icons.verified_user : Icons.workspace_premium,
                      size: sm ? 32 : 22,
                      color: const Color(0xFF563900),
                    ),
                  ),
                  SizedBox(width: sm ? 16 : 10),
                  // FittedBox : le texte se réduit pour tenir dans la place, au lieu d'être coupé par « … ».
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            active ? Strings.menuAdFreeActive : Strings.menuAdFreeOffer,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'RobotoSlab',
                              fontSize: sm ? 24 : 18,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                              color: const Color(0xFF20284B),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            active ? Strings.menuAdFreeActiveNote : Strings.menuAdFreeOfferNote,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: sm ? 14 : 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xBF20284B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sm ? 16 : 8, vertical: sm ? 10 : 6),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FFFFFF)),
                boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 4), blurRadius: 8)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: sm ? 20 : 16, color: _gold),
                  const SizedBox(height: 2),
                  Text(
                    clock,
                    style: TextStyle(
                      fontSize: sm ? 18 : 14,
                      fontWeight: FontWeight.w900,
                      color: _gold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyTitle extends StatelessWidget {
  const _DifficultyTitle({required this.vw, required this.gameName});

  final double vw;
  final String gameName;

  @override
  Widget build(BuildContext context) {
    // font-size: clamp(2.1rem, 9vw, 4.5rem)
    final size = math.min(math.max(33.6, 0.09 * vw), 72.0);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x59FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('01', style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 12)),
              const SizedBox(width: 8),
              Text(
                gameName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2.2, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Strings.menuChooseLevel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BowlbyOneSC',
            fontSize: size,
            height: 1,
            color: _ceramic,
            shadows: const [
              Shadow(offset: Offset(0, 5), color: Color(0xFF173A79)),
              Shadow(offset: Offset(0, 9), blurRadius: 18, color: Color(0x610B1C44)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Strings.menuChooseLevelNote,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xCCFFFFFF)),
        ),
      ],
    );
  }
}

class _LaunchButton extends StatelessWidget {
  const _LaunchButton({required this.label, required this.sm, required this.onTap});

  final String label;
  final bool sm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: Strings.menuLaunch,
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: sm ? 64 : 56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE16B), Color(0xFFFFB43C)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFFA64A1D), offset: Offset(0, 6)),
            BoxShadow(color: _shadowSoft, offset: Offset(0, 11), blurRadius: 22),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, size: 20, color: Color(0xFF30264F)),
            const SizedBox(width: 12),
            Text(
              'Lancer la partie · $label',
              style: TextStyle(
                fontFamily: 'RobotoSlab',
                fontSize: sm ? 20 : 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF30264F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panneau translucide (fond selon le niveau, flou d'arrière-plan).
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.difficulty,
    required this.radius,
    required this.padding,
    required this.child,
  });

  final Difficulty difficulty;
  final double radius;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kComicMenu) {
      return ComicPanel(
        color: _comicInk,
        outlineColor: ComicPalette.tunisBlue,
        radius: radius,
        padding: padding,
        child: child,
      );
    }
    final color = switch (difficulty) {
      Difficulty.facile => const Color(0x7A0A2349),
      Difficulty.moyen => const Color(0x993F1D32),
      Difficulty.difficile => const Color(0xBF090D2F),
    };
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [BoxShadow(color: Color(0x6B071030), offset: Offset(0, 18), blurRadius: 55)],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              border: Border.all(color: const Color(0x59FFFFFF)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10)],
      ),
    );
  }
}
