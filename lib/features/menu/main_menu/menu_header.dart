part of '../main_menu_screen.dart';

class _Header extends StatelessWidget {
  const _Header({
    required this.difficulty,
    required this.screen,
    required this.onBack,
    this.profile,
    this.onProfileTap,
  });

  final Difficulty difficulty;
  final _MenuScreen screen;
  final VoidCallback onBack;
  final PlayerProfile? profile;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pastille profil (#546) : avatar + pseudo, sur l'écran principal seulement.
        if (screen == _MenuScreen.menu && profile != null)
          ProfileChip(
            name: profile!.name,
            avatarId: profile!.avatarId,
            onTap: onProfileTap ?? () {},
          ),
        // Pas de solde affiché : aucune économie n'est définie (#118).
        if (screen != _MenuScreen.menu)
          _GlassButton(
            onTap: onBack,
            semanticLabel: Strings.menuBackToGames,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 20),
                SizedBox(width: 8),
                Text(
                  Strings.menuBack,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
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
              onTap: () => _showPrivacyDialog(context),
              semanticLabel: Strings.menuPrivacy,
              child: const Icon(Icons.privacy_tip_outlined, size: 20),
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

/// Dialogue « Confidentialité » : accorder, refuser ou retirer le consentement
/// (#466), revoir les choix UMP et réinitialiser la réponse d'âge (#570).
Future<void> _showPrivacyDialog(BuildContext context) {
  final consent = ConsentService.instance;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(Strings.privacyTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(Strings.privacyBody),
          TextButton(
            onPressed: () => showUmpPrivacyOptions(),
            child: Text(Strings.privacyReviewChoices),
          ),
          TextButton(
            onPressed: () async {
              await AgeGateService.instance.reset();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(Strings.privacyResetAge),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await consent.withdraw();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(Strings.privacyWithdraw),
        ),
        TextButton(
          onPressed: () async {
            await consent.deny();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(Strings.privacyRefuse),
        ),
        FilledButton(
          onPressed: () async {
            await consent.grant();
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(Strings.privacyAccept),
        ),
      ],
    ),
  );
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
            padding: square
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            padding: square
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xA610254C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x59FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
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
    final base = TextStyle(
      fontFamily: 'Bangers',
      fontSize: size,
      height: 1,
      letterSpacing: 1,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          kAppName,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.12
              ..strokeJoin = StrokeJoin.round
              ..color = ComicPalette.ink,
          ),
        ),
        Text(kAppName, style: base.copyWith(color: ComicPalette.yellow)),
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
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFFFFE76A),
              ),
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
                kAppName,
                style: TextStyle(
                  fontFamily: 'BowlbyOneSC',
                  fontSize: titleSize,
                  height: 1,
                  letterSpacing: -0.05 * titleSize,
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
        const SizedBox(height: 4),
        Text(
          'لمّـة، ضحكة ولعبة تونسية',
          style: TextStyle(
            fontSize: sm ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xF2FFFFFF),
            shadows: const [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 7,
                color: Color(0xBF07193C),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
