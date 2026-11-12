import 'package:material_ui/material_ui.dart';

/// Carte à jouer générique (guide §8) : gère le dos, la sélection et le tap.
/// Le contenu de la face est fourni par l'appelant (ex. ChkobbaCardFace).
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.face,
    this.back,
    this.faceDown = false,
    this.selected = false,
    this.onTap,
    this.width,
    this.semanticLabel,
  });

  /// Contenu de la face visible.
  final Widget face;

  /// Dos personnalisé ; sinon [PlayingCard.defaultBack].
  final Widget? back;
  final bool faceDown;

  /// Carte choisie : translation vers le haut et anneau jaune.
  final bool selected;
  final VoidCallback? onTap;
  final double? width;
  final String? semanticLabel;

  /// Rapport largeur / hauteur (480 × 707, comme les images de cartes).
  static const double aspectRatio = 480 / 707;
  static const double _radius = 8;

  /// Dos rouge du source : dégradé #b91c1c → #7f1d1d, cadre intérieur #ca8a04.
  static Widget defaultBack() => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
          ),
        ),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.68,
            heightFactor: 0.72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xCCCA8A04), width: 3),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: selected
            ? Border.all(color: const Color(0xFFFACC15), width: 3)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black, offset: Offset(0, selected ? 5 : 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: faceDown ? (back ?? defaultBack()) : face,
      ),
    );

    final sized = SizedBox(
      width: width,
      child: AspectRatio(aspectRatio: aspectRatio, child: card),
    );

    if (onTap == null) return sized;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: sized,
      ),
    );
  }
}
