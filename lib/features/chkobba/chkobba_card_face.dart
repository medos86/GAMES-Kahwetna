import 'package:flutter/material.dart';

import '../../game/chkobba.dart';

/// Symbole de chaque couleur (même correspondance que suitSymbols du source).
String chkobbaSuitSymbol(ChkobbaSuit suit) => switch (suit) {
  ChkobbaSuit.deniers => '♦',
  ChkobbaSuit.coupes => '♥',
  ChkobbaSuit.epees => '♠',
  ChkobbaSuit.batons => '♣',
};

/// Couleur de chaque couleur (suitColors du source : yellow-600, red-600, gray-800, amber-800).
Color chkobbaSuitColor(ChkobbaSuit suit) => switch (suit) {
  ChkobbaSuit.deniers => const Color(0xFFCA8A04),
  ChkobbaSuit.coupes => const Color(0xFFDC2626),
  ChkobbaSuit.epees => const Color(0xFF1F2937),
  ChkobbaSuit.batons => const Color(0xFF92400E),
};

/// Libellé de valeur : 1 = A, 8 = D (dame), 9 = V (valet), 10 = R (roi).
String chkobbaRankLabel(int rank) => switch (rank) {
  1 => 'A',
  8 => 'D',
  9 => 'V',
  10 => 'R',
  _ => '$rank',
};

/// Nom de fichier de l'enseigne dans assets/images/cards_cartoon/.
String _assetSuitName(ChkobbaSuit suit) => switch (suit) {
  ChkobbaSuit.deniers => 'carreau',
  ChkobbaSuit.coupes => 'coeur',
  ChkobbaSuit.epees => 'pique',
  ChkobbaSuit.batons => 'trèfle',
};

const String _cardsFolder = 'assets/images/cards_cartoon';
const String cardBackAsset = '$_cardsFolder/Chkobba_back.png';

/// Chemin de l'image cartoon d'une carte, par ex. assets/images/cards_cartoon/Chkobba_pique_08.png.
String chkobbaCardAsset(ChkobbaCard card) {
  final num = card.rank.toString().padLeft(2, '0');
  return '$_cardsFolder/Chkobba_${_assetSuitName(card.suit)}_$num.png';
}

/// Face d'une carte : image cartoon de la carte.
class ChkobbaCardFace extends StatelessWidget {
  const ChkobbaCardFace({
    super.key,
    required this.card,
    this.onTap,
    this.highlight = false,
  });

  final ChkobbaCard card;
  final VoidCallback? onTap;

  /// Anneau jaune (carte choisie).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final face = AspectRatio(
      aspectRatio: 480 / 707,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: highlight
              ? Border.all(color: const Color(0xFFFACC15), width: 3)
              : null,
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            chkobbaCardAsset(card),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            semanticLabel:
                '${chkobbaRankLabel(card.rank)} ${chkobbaSuitSymbol(card.suit)}',
          ),
        ),
      ),
    );

    if (onTap == null) return face;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: face,
    );
  }
}

/// Dos d'une carte (main de l'adversaire).
class ChkobbaCardBack extends StatelessWidget {
  const ChkobbaCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 480 / 707,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            cardBackAsset,
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
