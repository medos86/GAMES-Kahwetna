import 'package:material_ui/material_ui.dart';

import '../../game/rami.dart' as rules;
import '../../core/strings.dart';

/// Dossier des images du jeu Rami (CC0, voir ATTRIBUTIONS.md). Distinct de cards_cartoon (Chkobba).
const String ramiCardsFolder = 'assets/images/cards_rami';

/// Dos de carte utilisé pour la pioche et la main adverse.
const String ramiCardBackAsset = '$ramiCardsFolder/card_back_red.png';

/// Largeur de décodage des PNG (1500 px d'origine) : suffisant pour l'affichage, sans gonfler la mémoire.
const int _ramiCacheWidth = 600;

/// Libellé d'une valeur : As, Valet, Dame, Roi, ou le chiffre.
String ramiRankLabel(int rank) => switch (rank) {
      1 => 'A',
      11 => 'V',
      12 => 'D',
      13 => 'R',
      _ => '$rank',
    };

/// Symbole de chaque couleur (valeurs de Card.tsx).
String ramiSuitSymbol(rules.RamiSuit suit) => switch (suit) {
      rules.RamiSuit.deniers => '♦',
      rules.RamiSuit.coupes => '♥',
      rules.RamiSuit.epees => '♠',
      rules.RamiSuit.batons => '♣',
    };

/// Nom anglais de la couleur, tel qu'il figure dans les fichiers CC0.
String _ramiSuitFileName(rules.RamiSuit suit) => switch (suit) {
      rules.RamiSuit.deniers => 'diamonds',
      rules.RamiSuit.coupes => 'hearts',
      rules.RamiSuit.epees => 'spades',
      rules.RamiSuit.batons => 'clubs',
    };

/// Nom anglais de la valeur : ace, jack, queen, king, ou le chiffre.
String _ramiRankFileName(int rank) => switch (rank) {
      1 => 'ace',
      11 => 'jack',
      12 => 'queen',
      13 => 'king',
      _ => '$rank',
    };

/// Image d'une carte, par ex. assets/images/cards_rami/ace_of_spades.png.
/// Les deux jokers ont chacun leur couleur : joker-0 noir, joker-1 rouge.
String ramiCardAsset(rules.RamiCard card) {
  if (card.isJoker) {
    final colour = card.id == 'joker-1' ? 'red' : 'black';
    return '$ramiCardsFolder/${colour}_joker.png';
  }
  final suit = _ramiSuitFileName(card.suit!);
  return '$ramiCardsFolder/${_ramiRankFileName(card.rank)}_of_$suit.png';
}

/// Carte Rami : image du jeu CC0. Seul le coin haut-gauche est visible dans la main,
/// les cartes qui se chevauchent restent donc lisibles.
class RamiCardView extends StatelessWidget {
  const RamiCardView({
    super.key,
    required this.card,
    required this.width,
    this.selected = false,
  });

  final rules.RamiCard card;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.4;
    final radius = BorderRadius.circular(width * 0.14);
    final semanticsLabel = card.isJoker
        ? Strings.jokerLabel
        : '${ramiRankLabel(card.rank)} ${ramiSuitSymbol(card.suit!)}';

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Transform.translate(
        offset: Offset(0, selected ? -width * 0.25 : 0),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected
                ? Border.all(color: const Color(0xFFFFE16B), width: 3)
                : null,
            boxShadow: const [
              BoxShadow(color: Colors.black, offset: Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Image.asset(
              ramiCardAsset(card),
              fit: BoxFit.fill,
              gaplessPlayback: true,
              cacheWidth: _ramiCacheWidth,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dos d'une carte, pour la pioche.
class RamiBackView extends StatelessWidget {
  const RamiBackView({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width * 0.14);
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          ramiCardBackAsset,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          cacheWidth: _ramiCacheWidth,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
