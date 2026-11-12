import 'package:material_ui/material_ui.dart';

import '../../game/coinche.dart';
import '../../core/strings.dart';

/// Symbole de chaque couleur (suitSymbols du source).
String coincheSuitSymbol(CoincheSuit suit) => switch (suit) {
      CoincheSuit.deniers => '♦',
      CoincheSuit.coupes => '♥',
      CoincheSuit.epees => '♠',
      CoincheSuit.batons => '♣',
    };

/// Couleur de chaque couleur (suitColors du source : yellow-600, red-600, gray-800, amber-800).
Color coincheSuitColor(CoincheSuit suit) => switch (suit) {
      CoincheSuit.deniers => const Color(0xFFCA8A04),
      CoincheSuit.coupes => const Color(0xFFDC2626),
      CoincheSuit.epees => const Color(0xFF1F2937),
      CoincheSuit.batons => const Color(0xFF92400E),
    };

/// Nom de couleur en français (suitNames du source, utilisé pour les accessibilités).
String coincheSuitName(CoincheSuit suit) => switch (suit) {
      CoincheSuit.deniers => Strings.suitCarreau,
      CoincheSuit.coupes => Strings.suitCoeur,
      CoincheSuit.epees => Strings.suitPique,
      CoincheSuit.batons => Strings.suitTrefle,
    };

/// Matrice couleur : luminosité 0.75 et saturation 0.5 (style « jouée / illégale » du source).
const List<double> _dimMatrix = [
  0.75 * (0.2126 * 0.5 + 0.5),
  0.75 * (0.7152 * 0.5),
  0.75 * (0.0722 * 0.5),
  0,
  0,
  0.75 * (0.2126 * 0.5),
  0.75 * (0.7152 * 0.5 + 0.5),
  0.75 * (0.0722 * 0.5),
  0,
  0,
  0.75 * (0.2126 * 0.5),
  0.75 * (0.7152 * 0.5),
  0.75 * (0.0722 * 0.5 + 0.5),
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Carte Coinche : face (rang + couleur) ou dos. Hauteur = 1,4 × largeur, comme le source.
class CoincheCardView extends StatelessWidget {
  const CoincheCardView({
    super.key,
    required this.width,
    this.card,
    this.onTap,
    this.dimmed = false,
  });

  final double width;

  /// null = dos de carte.
  final CoincheCard? card;
  final VoidCallback? onTap;

  /// Carte non jouable pendant le tour du joueur.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final shown = card;
    Widget face = SizedBox(
      width: width,
      height: height,
      child: shown == null ? _back(width) : _front(shown, width, height),
    );
    if (dimmed) {
      face = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_dimMatrix),
        child: face,
      );
    }
    if (onTap == null) return face;
    return GestureDetector(onTap: onTap, child: face);
  }

  Widget _front(CoincheCard c, double width, double height) {
    final color = coincheSuitColor(c.suit);
    final symbol = coincheSuitSymbol(c.suit);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: const Color(0xFF15264D), width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.08,
            top: height * 0.04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.rank.label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: height * 0.2,
                    height: 1,
                  ),
                ),
                Text(
                  symbol,
                  style: TextStyle(
                    color: color,
                    fontSize: height * 0.16,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              symbol,
              style: TextStyle(color: color, fontSize: height * 0.4, height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _back(double width) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: const Color(0xFF15264D), width: 1.5),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.68,
          heightFactor: 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xCCCA8A04), width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
