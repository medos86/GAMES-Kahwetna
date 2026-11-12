import 'package:material_ui/material_ui.dart';

import 'ad_banner.dart';

/// Structure commune des écrans de jeu (guide §8 : GameScaffold).
/// Fond → contenu dans SafeArea (largeur max 1100) → bannière pub (si affichée) → overlays.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.child,
    this.background,
    this.showAd = true,
    this.overlays = const [],
  });

  final Widget child;

  /// Fond de l'écran ; par défaut un aplat de la couleur de fond de l'app.
  final Widget? background;

  /// Faux pendant le mode sans pub : la bannière disparaît et le contenu remonte.
  final bool showAd;

  /// Dialogues et calques posés au-dessus du contenu.
  final List<Widget> overlays;

  static const double maxContentWidth = 1100;
  static const double _adReservedHeight = 88;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final width = media.size.width;
    final bottomPadding = showAd ? _adReservedHeight + bottomInset : 12.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          background ?? const ColoredBox(color: Color(0xFF10234B)),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: child,
                ),
              ),
            ),
          ),
          if (showAd)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (width - 16).clamp(0, 624).toDouble(),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: AdBanner(),
                  ),
                ),
              ),
            ),
          ...overlays,
        ],
      ),
    );
  }
}
