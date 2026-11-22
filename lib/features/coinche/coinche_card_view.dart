import 'package:material_ui/material_ui.dart';

import '../../game/coinche.dart';
import '../../core/strings.dart';
import '../rami/rami_card_view.dart' show ramiCardBackAsset, ramiCardsFolder;

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

/// Image Rami (CC0) d'une carte Coinche : valeurs 7 à 10 en chiffres, V = valet, D = dame, R = roi, A = as.
String coincheCardAsset(CoincheCard card) {
  final rank = switch (card.rank) {
    CoincheRank.seven => '7',
    CoincheRank.eight => '8',
    CoincheRank.nine => '9',
    CoincheRank.ten => '10',
    CoincheRank.valet => 'jack',
    CoincheRank.dame => 'queen',
    CoincheRank.roi => 'king',
    CoincheRank.ace => 'ace',
  };
  final suit = switch (card.suit) {
    CoincheSuit.deniers => 'diamonds',
    CoincheSuit.coupes => 'hearts',
    CoincheSuit.epees => 'spades',
    CoincheSuit.batons => 'clubs',
  };
  return '$ramiCardsFolder/${rank}_of_$suit.webp';
}

/// Fond teinté derrière les cartes d'atout (#786, remplace la dorure #734).
const Color coincheTrumpTint = Color(0x553FA7D6);

/// Vrai si la carte est de la couleur d'atout du contrat en cours (#734).
bool coincheIsTrump(CoincheCard card, Contract? contract) =>
    contract != null && card.suit == contract.mode;

/// Carte Coinche : face (rang + couleur) ou dos. Hauteur = 1,4 × largeur, comme le source.
class CoincheCardView extends StatelessWidget {
  const CoincheCardView({
    super.key,
    required this.width,
    this.card,
    this.onTap,
    this.dimmed = false,
    this.trump = false,
  });

  final double width;

  /// null = dos de carte.
  final CoincheCard? card;
  final VoidCallback? onTap;

  /// Carte non jouable pendant le tour du joueur.
  final bool dimmed;

  /// Carte d'atout : bordure et reflet dorés (#734).
  final bool trump;

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
    final radius = BorderRadius.circular(width * 0.12);
    final image = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        coincheCardAsset(c),
        fit: BoxFit.fill,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
    if (!trump) return image;
    return DecoratedBox(
      key: const ValueKey('trump-tint'),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: coincheTrumpTint,
      ),
      child: image,
    );
  }

  Widget _back(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(width * 0.12),
      child: Image.asset(
        ramiCardBackAsset,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}
