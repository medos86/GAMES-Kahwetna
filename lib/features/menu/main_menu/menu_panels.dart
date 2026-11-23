part of '../main_menu_screen.dart';

class _AdFreeButton extends StatelessWidget {
  const _AdFreeButton({
    required this.sm,
    required this.secondsLeft,
    required this.onTap,
  });

  final bool sm;
  final int secondsLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = secondsLeft > 0;
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final clock =
        active ? '$minutes:${seconds.toString().padLeft(2, '0')}' : '30:00';

    return Pressable(
      sound: Sfx.uiClick,
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
            BoxShadow(
              color: Color(0x66040B1F),
              offset: Offset(0, 14),
              blurRadius: 28,
            ),
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
                      border: Border.all(
                        color: const Color(0x3315264D),
                        width: 2,
                      ),
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
                            active
                                ? Strings.menuAdFreeActive
                                : Strings.menuAdFreeOffer,
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
                            active
                                ? Strings.menuAdFreeActiveNote
                                : Strings.menuAdFreeOfferNote,
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
              padding: EdgeInsets.symmetric(
                horizontal: sm ? 16 : 8,
                vertical: sm ? 10 : 6,
              ),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
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
              const Text(
                '01',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gameName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2.2,
                  color: Colors.white,
                ),
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
              Shadow(
                offset: Offset(0, 9),
                blurRadius: 18,
                color: Color(0x610B1C44),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Strings.menuChooseLevelNote,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xCCFFFFFF),
          ),
        ),
      ],
    );
  }
}

class _LaunchButton extends StatelessWidget {
  const _LaunchButton({
    required this.label,
    required this.sm,
    required this.onTap,
  });

  final String label;
  final bool sm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      sound: Sfx.uiClick,
      semanticLabel: Strings.menuLaunch,
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: sm ? 64 : 56),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE16B), Color(0xFFFFB43C)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xFFA64A1D), offset: Offset(0, 6)),
            BoxShadow(
              color: _shadowSoft,
              offset: Offset(0, 11),
              blurRadius: 22,
            ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x6B071030),
            offset: Offset(0, 18),
            blurRadius: 55,
          ),
        ],
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
